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


// TODO: Push docstring
trait Push[T: Any #send]
  """"""
  // Push state accessors
  fun _get_propogation_depth(): Bool
    """ Getter for `_propogation_depth` """
  fun ref _set_propogation_depth(value: Bool)
    """ Setter for `_propogation_depth` """
  fun ref get_observers(): (SetIs[Observer[T]] | None)
    """ Getter for `_observers` """
  fun ref set_observers(observers: (SetIs[Observer[T]] | None))
    """ Setter for `_observers` """
  fun _get_events_unreacted(): Bool
    """ Getter for `_events_unreacted` """
  fun ref _set_events_unreacted(value: Bool)
    """ Getter for `_events_unreacted` """

  // Implementation
  fun react_all(value: T, hint: EventHint) => None


  fun except_all(x: EventError) => None


  fun unreact_all() => None



type Emitter[T: Any #send] is (Push[T] & Events[T] & Observer[T])



// TODO: BuildEvents docstring
primitive BuildEvents
  """"""

  // TODO: BuildEvents.emitter docstring
  fun emitter[T: Any #send](): Emitter[T] =>
    """"""
    object is Emitter[T]
      // Push state
      var _propogation_depth: U32 = 0
      var _observers: (SetIs[Observer[T]] | None) = _observers.create()
      var _events_unreacted: Bool = false
      // Emitter state
      var _closed: Bool = false

      // State Accessors
      fun _get_propogation_depth(): Bool => _propogation_depth
      fun ref _set_propogation_depth(value: Bool) => _propogation_depth = value
      fun ref get_observers(): (SetIs[Observer[T]] | None) => _observers
      fun ref set_observers(observers: (SetIs[Observer[T]] | None)) =>
        _observers = observers
      fun _get_events_unreacted(): Bool => _events_unreacted
      fun ref _set_events_unreacted(value: Bool) => _events_unreacted = value

      fun react(value: T, hint: (EventHint | None) = None) =>
        if not _closed then
          react_all(consume value, hint)
        end

      fun except(x: EventError) =>
        if not _closed then
          except_all(x)
        end

      fun unreact() =>
        if not _closed then
          _closed = true
          unreact_all()
          // demux = None // TODO: Deal
        end
    end
