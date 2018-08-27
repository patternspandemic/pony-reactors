use "debug"
use "collections"

interface val EventHint
interface val EventError
  fun apply(): String val

// TODO: Remove OptionalEventHint - Probably unneeded.
type OptionalEventHint is (EventHint | None)

// TODO: Events - Fill out docstring
trait Events[T: Any #alias]
  """
  A basic event stream.
  """

  fun ref on_reaction(observer: Observer[T]): Subscription
    """
    Register a new observer to this event stream. The observer is invoked
    whenever an event is produced, an error occurs while producing an event,
    and at most once when this event stream no longer produces events. After
    this stream terminates its production of events, no more events or errors
    will propogate to observers.
    """

  fun ref on_event_or_done(
    react_handler: {ref (T, OptionalEventHint)},
    unreact_handler: {ref ()})
    : Subscription
  =>
    """
    Register callbacks for `react` and `unreact` events. Shorthand for
    `on_reaction` where `except` events are ignored.
    """
    let o: Observer[T] = BuildObserver[T].of_react_and_unreact(
      where
        react' = react_handler,
        unreact' = unreact_handler
    )
    on_reaction(o)

  fun ref on_event(react_handler: {ref (T, OptionalEventHint)}): Subscription =>
    """
    Register a callback for `react`. Shorthand for `on_reaction` where `except`
    and `unreact` events are ignored.
    """
    let o: Observer[T] = BuildObserver[T].of_react(react_handler)
    on_reaction(o)

  // TODO: Events on_match - Not sure this is really needed. What's the difference between implementing something like Scala PartialFunction and simply using nested Pony match statements in a handler given to on_event? Maybe some higher level composition of match handlers arrived from disparate sources.
  // fun ref on_match

  fun ref on(react_handler: {ref ()}): Subscription =>
    """
    Register a callback for `react` events without regards to event values.
    Shorthand for `on_reaction`. This method is useful when the event value is
    not important, or when the type of the event is `None`.
    """
    let o: Observer[T] =
      BuildObserver[T].of_react_without_regards(react_handler)
    on_reaction(o)

  fun ref on_done(unreact_handler: {ref ()}): Subscription =>
    """
    Register a callback for `unreact`. Shorthand for `on_reaction` where
    `react` and `except` events are ignored.
    """
    let o: Observer[T] = BuildObserver[T].of_unreact(unreact_handler)
    on_reaction(o)

  fun ref on_except(except_handler: {ref (EventError)}): Subscription =>
    """
    Register a callback for `except`. Shorthand for `on_reaction` where
    `react` and `unreact` events are ignored.
    """
    let o: Observer[T] = BuildObserver[T].of_except(except_handler)
    on_reaction(o)

  fun ref after[S: Any #alias](that: Events[S]): Events[T] =>
    """
    Creates a new event stream that produces events from this event stream only
    after the event stream `that` produces an event. If `that` unreacts before
    it produces an event, the resulting event stream unreacts. If this event
    stream unreacts, the resulting event stream unreacts.
    """
    _After[T, S](this, that)

  fun ref mutate[C: Any ref](
    mutable: Mutable[C],
    mutator: {ref (C, T)})
    : Subscription
  =>
    """
    Mutate the target `Mutable` event stream called `mutable` with `mutator`
    each time this event stream produces an event.
    """
    let o: Observer[T] = BuildObserver[T].that_mutates[C](mutable, mutator)
    on_reaction(o)


// TODO: Push
// - Possibility of having references to observers that are no longer reachable?
trait Push[T: Any #alias] is Events[T]
  """ Default Implementation of an event stream. """
  // Push state accessors ...
//  fun ref get_observers(): (SetIs[Observer[T]] | None)
  fun ref get_observers(): SetIs[Observer[T]]
    """ Getter for `_observers` """
  fun ref set_observers(observers: (SetIs[Observer[T]] | None))
    """ Setter for `_observers` """
  fun _get_events_unreacted(): Bool
    """ Getter for `_events_unreacted` """
  fun ref _set_events_unreacted(value: Bool)
    """ Getter for `_events_unreacted` """

  // Implementation ...

  fun ref on_reaction(observer: Observer[T]): Subscription =>
    """ Add `observer` to the set of observers, subscribing it. """
    if _get_events_unreacted() then
      // This event stream is no longer propogating events. Immediately unreact
      // the observer, and return an empty subscription.
      observer.unreact()
      BuildSubscription.empty()
    else
      // Add the observer to the set of observers, create the set when needed.
      match get_observers()
//      | None =>
//        let observers = SetIs[Observer[T]]
//        observers.set(observer)
//        set_observers(observers)
      | let observers: SetIs[Observer[T]] =>
        observers.set(observer)
      end
      // Return a subscription of the observer, allowing it to be unsubscribe.
      _new_subscription(observer)
    end

  fun ref _new_subscription(observer: Observer[T]): Subscription =>
    """ Build a subscription for `observer` """
    BuildSubscription(this~_remove_reaction(observer))

  fun ref _remove_reaction(observer: Observer[T]) =>
    """ Remove `observer` from the set of observers, unsubscribing it. """
    match get_observers()
    | let observers: SetIs[Observer[T]] =>
      observers.unset(observer)
      // Assign set of observers to None if empty.
      if observers.size() == 0 then set_observers(None) end
    end

  fun ref react_all(value: T, hint: (EventHint | None) = None) =>
    """ Send a `react` event to all observers """
    match get_observers()
    | let observers: SetIs[Observer[T]] =>
      for observer in observers.values() do
        observer.react(value, hint)
      end
    end

  fun ref except_all(x: EventError) =>
    """ Send an `except` event to all observers """
    match get_observers()
    | let observers: SetIs[Observer[T]] =>
      for observer in observers.values() do
        observer.except(x)
      end
    end

  fun ref unreact_all() =>
    """ Send an `unreact` event to all observers """
    _set_events_unreacted(true)
    match get_observers()
    | let observers: SetIs[Observer[T]] =>
      for observer in observers.values() do
        observer.unreact()
      end
    end
    // Assign set of observers to None, as no more events will be propogated.
    set_observers(None)

  fun ref has_subscriptions(): Bool =>
//    match get_observers()
//    | None => false
//    | let _: SetIs[Observer[T]] => true
//    end
    if get_observers().size() > 0 then true else false end


class _After[T: Any #alias, S: Any #alias] is Events[T]
  """
  An event stream that produces events from `self` only after a react event is
  produced from `that`. Unreacts when `self` unreacts, or when `that` unreacts
  before producing a react event.
  """
  let self: Events[T]
  let that: Events[S]

  new create(self': Events[T], that': Events[S]) =>
    self = self'
    that = that'

  fun ref on_reaction(observer: Observer[T]): Subscription =>
    let after_observer: _AfterObserver[T] =
      BuildObserver[T]._after(observer)
    let after_that_observer: _AfterThatObserver[S, T] =
      BuildObserver[S]._after_that[T](after_observer)
    let sub: Subscription = self.on_reaction(after_observer)
    let sub_that: Subscription = that.on_reaction(after_that_observer)
    after_that_observer.subscription = sub_that
    BuildSubscription.composite([sub; sub_that])


class Emitter[T: Any #alias] is (Push[T] & Events[T] & Observer[T])
  """
  An event source that emits events when `react`, `except`, or `unreact` is called. Emitters are simultaneously an event stream and observer.
  """
  // Push state
//  var _observers: (SetIs[Observer[T]] | None) = None
  var _observers: SetIs[Observer[T]] = SetIs[Observer[T]]
  var _events_unreacted: Bool = false

  // Implemented state accessors
//  fun ref get_observers(): (SetIs[Observer[T]] | None) => _observers
  fun ref get_observers(): SetIs[Observer[T]] => _observers
  fun ref set_observers(observers: (SetIs[Observer[T]] | None)) =>
//    _observers = observers
    None
  fun _get_events_unreacted(): Bool => _events_unreacted
  fun ref _set_events_unreacted(value: Bool) => _events_unreacted = value

  // Observer ...
  fun ref react(value: T, hint: (EventHint | None) = None) =>
    if not _get_events_unreacted() then
      react_all(value, hint)
    end

  fun ref except(x: EventError) =>
    if not _get_events_unreacted() then
      except_all(x)
    end

  fun ref unreact() =>
    if not _get_events_unreacted() then
      unreact_all()
    end

// TODO: Mutable - Try to make this safer by requiring the mutator replace content with val versions, makeing the only way to easily update the signal to go through the mutate observer protocol. So instead of allowing content to be directly mutable (ref), allow it to be (val) replaced by the mutator.
// TODO: Mutable - Fill out docstring
class Mutable[M: Any ref] is (Push[M] & Events[M])
  """
  An event stream that emits an underlying mutable object as its event values
  when that underlying mutable object is potentially modified. This is a type of
  signal which provides a controlled way of manipulating mutable values.

  Note: It is important the underlying mutable object must only be mutated by
  the `mutate*` operators of `Events`, and never be mutated directly by
  accessing the signal's `content` directly.
  """
  // Push state
//  var _observers: (SetIs[Observer[M]] | None) = None
  var _observers: SetIs[Observer[M]] = SetIs[Observer[M]]
  var _events_unreacted: Bool = false
  // Underlying Mutable state
  var content: M ref

  new create(content': M) =>
    content = content'

  // Implemented state accessors
//  fun ref get_observers(): (SetIs[Observer[M]] | None) => _observers
  fun ref get_observers(): SetIs[Observer[M]] => _observers
  fun ref set_observers(observers: (SetIs[Observer[M]] | None)) =>
//    _observers = observers
    None
  fun _get_events_unreacted(): Bool => _events_unreacted
  fun ref _set_events_unreacted(value: Bool) => _events_unreacted = value


class Never[T: Any #alias] is Events[T]
  """
  An event source that never emits events. Subscribers immediately `unreact`.
  """
  fun ref on_reaction(observer: Observer[T]): Subscription =>
    observer.unreact()
    BuildSubscription.empty()


// TODO: BuildEvents docstring
primitive BuildEvents
  """"""

  fun emitter[T: Any #alias](): Emitter[T] =>
    """
    An event source that emits events when `react`, `except`, or `unreact` is called. Emitters are simultaneously an event stream and observer.
    """
    Emitter[T]

  fun mutable[M: Any ref](content: M): Mutable[M] =>
    Mutable[M](content)

  fun never[T: Any #alias](): Never[T] =>
    """
    An event source that never emits events. Subscribers immediately `unreact`.
    """
    Never[T]

  /*
  apply
  mux
  union
  sync
  single
  */