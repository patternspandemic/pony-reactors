
interface val EventHint
interface val EventError
  fun apply(): String val

trait Observer[T: Any #send]
  """
  An observer of values of type T produced by an event stream Events[T], or a
  signal indicating there will be no more events.
  """

  fun react(value: T, hint: (EventHint | None) = None)
    """
    Called by an event stream when an event 'value' is produced. `hint` may be
    provided as an extra value produced at the descretion of the event source.
    """

  fun except(x: EventError)
    """
    Called by the event stream when there wasAny an error producing an event value.
    """
  
  fun unreact()
    """
    Called by an event stream when there will be no more events produced.
    """


primitive BuildObserver[T: Any #send]
  """ Observer Builder  """
  
  fun apply(
    react': {(T, (EventHint | None))},
    except': {(EventError)},
    unreact': {()})
    : Observer[T]
  =>
    """
    Create and return an observer using the specified handlers.
    """
    object is Observer[T]
      fun react(value: T, hint: (EventHint | None) = None) =>
        react'( consume value, hint)
      fun except(x: EventError) => except'(x)
      fun unreact() => unreact'()
    end
