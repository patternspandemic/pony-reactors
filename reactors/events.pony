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

  // TODO: Events.to_*signal docstrings
  fun ref to_empty_signal(): Signal[T] =>
    """"""
    _ToSignal[T](this).>_supplant_raw_subscription()

  fun ref to_eager_signal(): Signal[T] =>
    """"""
    _ToSignal[T](this, true).>_supplant_raw_subscription()

  fun ref to_signal(initial: T): Signal[T] =>
    """"""
    _ToSignal[T](this, true, initial).>_supplant_raw_subscription()

  fun ref to_cold_signal(initial: T): Signal[T] =>
    """"""
    _ToColdSignal[T](this, initial)
/*
  fun ref to_done_signal(): Signal[Bool] =>
    """"""
    done().map[Bool]({() => true}).to_signal(false)
*/


// TODO: Push
// - Possibility of having references to observers that are no longer reachable?
trait Push[T: Any #alias] is Events[T]
  """ Default Implementation of an event stream. """
  // Push state accessors ...
  fun ref get_observers(): SetIs[Observer[T]]
    """ Getter for `_observers` """
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
      get_observers().set(observer)
      // Return a subscription of the observer, allowing it to be unsubscribe.
      _new_subscription(observer)
    end

  fun ref _new_subscription(observer: Observer[T]): Subscription =>
    """ Build a subscription for `observer` """
    BuildSubscription(this~_remove_reaction(observer))

  fun ref _remove_reaction(observer: Observer[T]) =>
    """ Remove `observer` from the set of observers, unsubscribing it. """
    get_observers().unset(observer)

  fun ref react_all(value: T, hint: (EventHint | None) = None) =>
    """ Send a `react` event to all observers """
    for observer in get_observers().values() do
      observer.react(value, hint)
    end

  fun ref except_all(x: EventError) =>
    """ Send an `except` event to all observers """
    for observer in get_observers().values() do
      observer.except(x)
    end

  fun ref unreact_all() =>
    """ Send an `unreact` event to all observers """
    _set_events_unreacted(true)
    let observers = get_observers()
    for observer in observers.values() do
      observer.unreact()
    end
    observers.clear()

  fun ref has_subscriptions(): Bool =>
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


class Emitter[T: Any #alias] is (Push[T] & Observer[T])
  """
  An event source that emits events when `react`, `except`, or `unreact` is called. Emitters are simultaneously an event stream and observer.
  """
  // Push state
  var _observers: SetIs[Observer[T]] = SetIs[Observer[T]]
  var _events_unreacted: Bool = false

  // Implemented state accessors
  fun ref get_observers(): SetIs[Observer[T]] => _observers
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
class Mutable[M: Any ref] is (Push[M] & Signal[M])
  """
  An event stream that emits an underlying mutable object as its event values
  when that underlying mutable object is potentially modified. This is a type of
  signal which provides a controlled way of manipulating mutable values.

  Note: It is important the underlying mutable object must only be mutated by
  the `mutate*` operators of `Events`, and never be mutated directly by
  accessing the signal's `content` directly.
  """
  // Push state
  var _observers: SetIs[Observer[M]] = SetIs[Observer[M]]
  var _events_unreacted: Bool = false
  // Underlying Mutable state
  var content: M ref
  // Subscription state
  var _unsubscribed: Bool = false

  new create(content': M) =>
    content = content'

  // Implement Signal
  fun ref apply(): M => content
  fun is_empty(): Bool => false
  fun _is_unsubscribed(): Bool => _unsubscribed
  fun ref unsubscribe() =>
    _unsubscribed = true
    if not _get_events_unreacted() then
      unreact_all()
    end

  // Implement Push
  fun ref get_observers(): SetIs[Observer[M]] => _observers
  fun _get_events_unreacted(): Bool => _events_unreacted
  fun ref _set_events_unreacted(value: Bool) => _events_unreacted = value


class Never[T: Any #alias] is Events[T]
  """
  An event source that never emits events. Subscribers immediately `unreact`.
  """
  fun ref on_reaction(observer: Observer[T]): Subscription =>
    observer.unreact()
    BuildSubscription.empty()


class _PushSource[T: Any #alias] is Push[T]
  """ The Push implemetation actualized. """
  // Push state
  var _observers: SetIs[Observer[T]] = SetIs[Observer[T]]
  var _events_unreacted: Bool = false

  // Implemented state accessors
  fun ref get_observers(): SetIs[Observer[T]] => _observers
  fun _get_events_unreacted(): Bool => _events_unreacted
  fun ref _set_events_unreacted(value: Bool) => _events_unreacted = value


primitive \nosupertype\ _EmptySignal
  """ The non-value of a signal. """

class _ToSignal[T: Any #alias] is (Signal[T] & Observer[T] & SubscriptionProxy)
  """"""
  let _self: Events[T]
  var _eager: Bool
  var _cached: (T | _EmptySignal)
  let _push_source: _PushSource[T] = _PushSource[T]
  var _raw_subscription: Subscription
  var _events_unreacted: Bool = false

  new create(
    self: Events[T],
    eager: Bool = false,
    cached: (T | _EmptySignal) = _EmptySignal)
  =>
    _self = self
    _eager = eager
    _cached = cached
    _raw_subscription = BuildSubscription.empty()

  fun ref _supplant_raw_subscription() =>
    _raw_subscription = _self.on_reaction(this)

  fun ref on_reaction(observer: Observer[T]): Subscription =>
    if _events_unreacted then
      // This signal is no longer propogating events. Immediately unreact
      // the observer, and return an empty subscription.
      observer.unreact()
      BuildSubscription.empty()
    else
      // TODO: _ToSignal - Test eagerness around _EmptySignal
      if _eager then
      // React on subscription, but only when signal is not empty.
        match _cached
        // | _EmptySignal => None
        | let value: T => observer.react(value, None)
        end
      end
      _push_source.on_reaction(observer)
    end

  // Signal ...
  fun ref apply(): T? =>
    match _cached
    | _EmptySignal => error
    | let value: T => value
    end

  fun is_empty(): Bool => _cached is _EmptySignal

  // Observer ...
  fun ref react(value: T, hint: (EventHint | None) = None) =>
    if not _events_unreacted then
      _cached = value
      _push_source.react_all(value, hint)
    end

  fun ref except(x: EventError) =>
    if not _events_unreacted then
      _push_source.except_all(x)
    end

  fun ref unreact() =>
    if not _events_unreacted then
      _events_unreacted = true
      _push_source.unreact_all()
    end

  // SubscriptionProxy ...
  fun _is_unsubscribed(): Bool =>
    _raw_subscription._is_unsubscribed()

  fun ref proxy_subscription(): Subscription =>
    _raw_subscription


// TODO: _ToColdSignal - Make work with empty value?
class _ToColdSignal[T: Any #alias] is Signal[T]
  """"""
  let _self: Events[T]
  var cached: T
  var _self_subscription: (Subscription | None) = None
  let _subscriptions: SubscriptionCollection = SubscriptionCollection
  let push_source: _PushSource[T] = _PushSource[T]

  new create(self: Events[T], cached': T) =>
    _self = self
    cached = cached'

  fun ref on_reaction(target: Observer[T]): Subscription =>
    let obs = BuildObserver[T]._to_cold_signal(target, this)
    let sub = push_source.on_reaction(obs)
    if not obs.done then
      if _subscriptions.is_empty() then
        _self_subscription =
          _self.on_reaction(BuildObserver[T]._to_cold_self(this))
      end
      let saved_sub = _subscriptions.add_and_get(sub)
      saved_sub.and_then(this~check_unsubscribe())
    else
      BuildSubscription.empty()
    end

  fun ref check_unsubscribe() =>
    if _subscriptions.is_empty() then
      match _self_subscription
      | let sub: Subscription =>
        sub.unsubscribe()
        _self_subscription = None
      end
    end

  // Signal ...
  fun ref apply(): T => cached
  fun is_empty(): Bool => false

  // Subscription ...
  fun _is_unsubscribed(): Bool => false
  fun ref unsubscribe() => None


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
  