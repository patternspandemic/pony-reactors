use "collections"

interface val EventHint
interface val EventError
  fun apply(): String val

type OptionalEventHint is (EventHint | None)


trait Events[T: Any #send]
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
    react_handler: {(T, OptionalEventHint)},
    unreact_handler: {()})
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

  fun ref on_event(react_handler: {(T, OptionalEventHint)}): Subscription =>
    """
    Register a callback for `react`. Shorthand for `on_reaction` where `except`
    and `unreact` events are ignored.
    """
    let o: Observer[T] = BuildObserver[T].of_react(react_handler)
    on_reaction(o)

  // TODO: Events on_match - Not sure this is really needed. What's the difference between implementing something like Scala PartialFunction and simply using nested Pony match statements in a handler given to on_event? Maybe some higher level composition of match handlers arrived from disparate sources.
  // fun ref on_match

  fun ref on(react_handler: {()}): Subscription =>
    """
    Register a callback for `react` events without regards to event values.
    Shorthand for `on_reaction`. This method is useful when the event value is
    not important, or when the type of the event is `None`.
    """
    let o: Observer[T] =
      BuildObserver[T].of_react_without_regards(react_handler)
    on_reaction(o)

  fun ref on_done(unreact_handler: {()}): Subscription =>
    """
    Register a callback for `unreact`. Shorthand for `on_reaction` where
    `react` and `except` events are ignored.
    """
    let o: Observer[T] = BuildObserver[T].of_unreact(unreact_handler)
    on_reaction(o)

  fun ref on_except(except_handler: {(EventError)}): Subscription =>
    """
    Register a callback for `except`. Shorthand for `on_reaction` where
    `react` and `unreact` events are ignored.
    """
    let o: Observer[T] = BuildObserver[T].of_except(except_handler)
    on_reaction(o)


// TODO: Push
// - Possibility of having references to observers that are no longer reachable?
trait Push[T: Any #send] is Events[T]
  """ Default Implementation of an event stream. """
  // Push state accessors ...
  fun ref get_observers(): (SetIs[Observer[T]] | None)
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
      | None =>
        let observers = SetIs[Observer[T]]
        observers.set(observer)
        set_observers(observers)
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

  fun ref react_all(value: T, hint: EventHint) =>
    """ Send a `react` event to all observers """

    // FIXME: How to deal with value that needs to be consumed to all observers. Clone? / Enforce a single observer? / Enforce #share instead of send?

    // Consume value directly when there's a single observer, otherwise clone?

    // Or consume to first observer, send tag to others when T is iso?

    match get_observers()
    | let observers: SetIs[Observer[T]] =>
      if observers.size() == 1 then
        try observers.index(0)?.react(consume value, hint) end
      else
        // SetIs not ordered though, must keep sep
        for observer in observers.values() do
          None
          // observer.react(consume value, hint)
        end
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



// type Emitter[T: Any #send] is (Push[T] & Events[T] & Observer[T])
class Emitter[T: Any #send] is (Push[T] & Events[T] & Observer[T])
  """
  An event source that emits events when `react`, `except`, or `unreact` is called. Emitters are simultaneously an event stream and observer.
  """
  // Push state
  var _observers: (SetIs[Observer[T]] | None) = None
  var _events_unreacted: Bool = false

  // Implemented state accessors
  fun ref get_observers(): (SetIs[Observer[T]] | None) => _observers
  fun ref set_observers(observers: (SetIs[Observer[T]] | None)) =>
    _observers = observers
  fun _get_events_unreacted(): Bool => _events_unreacted
  fun ref _set_events_unreacted(value: Bool) => _events_unreacted = value

  // Observer ...
  fun ref react(value: T, hint: (EventHint | None) = None) =>
    if not _get_events_unreacted() then
      react_all(consume value, hint)
    end

  fun ref except(x: EventError) =>
    if not _get_events_unreacted() then
      except_all(x)
    end

  fun ref unreact() =>
    if not _get_events_unreacted() then
      unreact_all()
    end


// TODO: BuildEvents docstring
primitive BuildEvents
  """"""

  fun emitter[T: Any #send](): Emitter[T] =>
    """
    An event source that emits events when `react`, `except`, or `unreact` is called. Emitters are simultaneously an event stream and observer.
    """
    Emitter[T]
