
primitive _DefaultChangesDetector[T: Any #alias]
  """ Detect changes based on difference in identity. """
  fun apply(old: T, new': T): Bool => not (old is new')

trait Signal[T: Any #alias] is (Events[T] & Subscription)
  """
  A special type of event stream that caches the last emitted event.
  """

  // TODO: Signal.apply - Improve safety by returning box? See also Mutable todo
  fun ref apply(): T?
    """ Returns the signal's value, the last event produced by this signal. """

  fun is_empty(): Bool
    """ Returns `true` when the signal does not yet have a value. """

  fun non_empty(): Bool =>
    """ Returns `true` when the signal has a value. """
    not is_empty()

  fun ref changes(
    changed: {(T, T): Bool} val =_DefaultChangesDetector[T])
    : Events[T]
  =>
    """
    An event stream that only emits events when the value of `this` signal
    changes. By default, change is detected by difference in identity.
    """
    _Changes[T](this, changed)

  // fun ref is(value: T): Events[T] =>
  //   """
  //   Emits only when the signal's value is that of the provided value based on
  //   identity.
  //   """

  /* TODO: Signal methods
  is
  becomes (requires changes, Events.filter)
  diff_past
  zip
  sync_with
  past_2 (requires Events.scan_past)
  with_subscription
  */


class ConstSignal[T: Any #alias] is Signal[T]
  """ Signal containing a constant value. """
  let _value: T

  new create(value: T) => _value = value
  fun ref apply(): T => _value
  fun is_empty(): Bool => false
  fun _is_unsubscribed(): Bool => true
  fun ref unsubscribe() => None
  fun ref on_reaction(observer: Observer[T]): Subscription =>
    observer.react(_value, None)
    observer.unreact()
    BuildSubscription.empty()


type MutableSignal[M: Any ref] is Mutable[M]
  """ Signal containing a mutable value. An alias of `Mutable`. """


class _Changes[T: Any #alias] is Events[T]
  """"""
  let _self: Signal[T]
  let _changed: {(T, T): Bool} val

  new create(self: Signal[T], changed: {(T, T): Bool} val) =>
    _self = self
    _changed = changed

  fun ref on_reaction(observer: Observer[T]): Subscription =>
    let cached: (T | _EmptySignal) =
      try _self()? else _EmptySignal end

    _self.on_reaction(
      BuildObserver[T]._signal_changes(observer, cached, _changed))


/* TODO: Classes for Signals
Is
  - IsObserver
DiffPast
  - DiffPastObserver
Zip
  - ZipThisObserver
  - ZipThatObserver
ZipState
ZipMany
  - ZipManyObserver
WithSubscription
*/


primitive BuildSignal
  """"""
  fun const[T: Any #alias](value: T): ConstSignal[T] =>
    ConstSignal[T](value)

  fun mutable[M: Any ref](content: M): MutableSignal[M] =>
    MutableSignal[M](content)

  /* TODO: BuildSignal methods
  zip
  aggregate (requires Signal.zip)
  */
