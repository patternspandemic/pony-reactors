
trait Observer[T: Any #read]
  """
  An observer of values of type T produced by an event stream Events[T], or a
  signal indicating there will be no more events.
  """

  fun ref react(value: T, hint: (EventHint | None) = None) =>
    """
    Called by an event stream when an event 'value' is produced. `hint` may be
    provided as an extra value produced at the descretion of the event source.
    """
    None

  fun ref except(x: EventError) =>
    """
    Called by the event stream when there wasAny an error producing an event value.
    """
    None
  
  fun ref unreact() =>
    """
    Called by an event stream when there will be no more events produced.
    """
    None


primitive BuildObserver[T: Any #read]
  """ Observer Builder  """
  
  fun apply(
    react': {ref (T, (EventHint | None))},
    except': {ref (EventError)},
    unreact': {ref ()})
    : Observer[T]
  =>
    """
    Create and return an observer using the specified handlers.
    """
    object is Observer[T]
      fun ref react(value: T, hint: (EventHint | None) = None) =>
        react'(value, hint)
      fun ref except(x: EventError) => except'(x)
      fun ref unreact() => unreact'()
    end

  fun of_react_and_unreact(
    react': {ref (T, (EventHint | None))},
    unreact': {ref ()})
    : Observer[T]
  =>
    """
    Create and return an observer using the specified `react` and `unreact`
    handlers. `except` events are ignored.
    """
    object is Observer[T]
      fun ref react(value: T, hint: (EventHint | None) = None) =>
        react'(value, hint)
      fun ref unreact() => unreact'()
    end

  fun of_react(react': {ref (T, (EventHint | None))}): Observer[T] =>
    """
    Create and return an observer using the specified `react` handler.
    `except` and `unreact` events are ignored.
    """
    object is Observer[T]
      fun ref react(value: T, hint: (EventHint | None) = None) =>
        react'(value, hint)
    end

  fun of_react_without_regards(react': {ref ()}): Observer[T] =>
    """
    Create and return an observer using the specified `react` handler, which
    disregards the value of the event. `except` and `unreact` events are
    ignored.
    """
    object is Observer[T]
      fun ref react(value: T, hint: (EventHint | None) = None) => react'()
    end

  fun of_unreact(unreact': {ref ()}): Observer[T] =>
    """
    Create and return an observer using the specified `unreact` handler.
    `react` and `except` events are ignored.
    """
    object is Observer[T]
      fun ref unreact() => unreact'()
    end

  fun of_except(except': {ref (EventError)}): Observer[T] =>
    """
    Create and return an observer using the specified `except` handler.
    `react` and `unreact` events are ignored.
    """
    object is Observer[T]
      fun ref except(x: EventError) => except'(x)
    end

  fun that_mutates[C: Any ref](
    mutable': Mutable[C],
    mutator': {ref (C, T)}) // TODO: mutator need not be ref?
    : Observer[T]
  =>
    """
    Create and return an observer that on reaction, firsts mutates the
    `Mutable` event stream `mutable'` and then tells that event stream to
    react to all its observers.
    """
    object is Observer[T]
      let mutate_with: {ref (T)} = mutator'~apply(mutable'.content)
      fun ref react(value: T, hint: (EventHint | None) = None) =>
        // Mutates the underlying content of the Mutable
        mutate_with(value)
        // React all observers of the mutable event stream
        mutable'.react_all(mutable'.content, None)
      fun ref except(x: EventError) => mutable'.except_all(x)
    end
