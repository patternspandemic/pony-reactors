
trait Observer[T: Any #alias]
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


class _AfterObserver[T: Any #alias] is Observer[T]
  """ Helper observer for `_After` event streams. """
  let target: Observer[T]
  var started: Bool = false
  var live: Bool = true

  new create(target': Observer[T]) =>
    target = target'

  fun ref react(value: T, hint: (EventHint | None) = None) =>
    if started then target.react(value, hint) end

  fun ref except(x: EventError) => target.except(x)

  fun ref unreact() => try_unreact()

  fun ref try_unreact() =>
    if live then
      live = false
      target.unreact()
    end


class _AfterThatObserver[T: Any #alias, S: Any #alias] is Observer[T]
  """ Helper observer for `_After` event streams. """
  let after_observer: _AfterObserver[S]
  var subscription: Subscription = BuildSubscription.empty()

  new create(after_observer': _AfterObserver[S]) =>
    after_observer = after_observer'

  fun ref react(value: T, hint: (EventHint | None) = None) =>
    if not after_observer.started then
      after_observer.started = true
      subscription.unsubscribe()
    end

  fun ref except(x: EventError) =>
    if not after_observer.started then
      after_observer.target.except(x)
    end

  fun ref unreact() =>
    if not after_observer.started then
      after_observer.try_unreact()
    end


class _SignalChangesObserver[T: Any #alias] is Observer[T]
  let _target: Observer[T]
  var _cached: (T | _EmptySignal)
  let _changed: {(T, T): Bool}

  new create(
    target: Observer[T],
    cached: (T | _EmptySignal),
    changed: {(T, T): Bool})
  =>
    _target = target
    _cached = cached
    _changed = changed

  fun ref react(value: T, hint: (EventHint | None) = None) =>
    match _cached
    | let value': T =>
      if _changed(value', value) then
        _cached = value
        _target.react(value, hint)
      end
    | _EmptySignal =>
      _cached = value
      _target.react(value, hint)
    end

  fun ref except(x: EventError) => _target.except(x)
  fun ref unreact() => _target.unreact()


class _ToColdSelfObserver[T: Any #alias] is Observer[T]
  """ Helper observer for `_ToColdSignal` event streams. """
  let _signal: _ToColdSignal[T]

  new create(signal: _ToColdSignal[T]) =>
    _signal = signal

  fun ref react(value: T, hint: (EventHint | None) = None) =>
    _signal.push_source.react_all(value, hint)
  fun ref except(x: EventError) => _signal.push_source.except_all(x)
  fun ref unreact() => _signal.push_source.unreact_all()


class _ToColdSignalObserver[T: Any #alias] is Observer[T]
  """ Helper observer for `_ToColdSignal` event streams. """
  let _target: Observer[T]
  let _signal: _ToColdSignal[T]
  var done: Bool = false

  new create(target: Observer[T], signal: _ToColdSignal[T]) =>
    _target = target
    _signal = signal

  fun ref react(value: T, hint: (EventHint | None) = None) =>
    _signal.cached = value
    _target.react(value, hint)

  fun ref except(x: EventError) => _target.except(x)

  fun ref unreact() =>
    done = true
    _signal.check_unsubscribe()
    _target.unreact()


primitive BuildObserver[T: Any #alias]
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

  fun _after(
    target': Observer[T])
    : _AfterObserver[T]
  =>
    _AfterObserver[T](target')

  fun _after_that[S: Any #alias](
    after_observer': _AfterObserver[S])
    : _AfterThatObserver[T, S]
  =>
    _AfterThatObserver[T, S](after_observer')

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

  fun _signal_changes(
    target: Observer[T],
    cached: (T | _EmptySignal),
    changed: {(T, T): Bool})
    : Observer[T]
  =>
    _SignalChangesObserver[T](target, cached, changed)

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

  fun _to_cold_self(signal: _ToColdSignal[T]): _ToColdSelfObserver[T] =>
    _ToColdSelfObserver[T](signal)

  fun _to_cold_signal(
    target: Observer[T],
    signal: _ToColdSignal[T])
    : _ToColdSignalObserver[T]
  =>
    _ToColdSignalObserver[T](target, signal)
