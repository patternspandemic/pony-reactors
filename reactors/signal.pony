
trait Signal[T: Any #alias] is (Events[T] & Subscription)
  """
  A special type of event stream that caches the last emitted event.
  """

  fun ref apply(): T
    """ Returns the signal's value, the last event produced by this signal. """

  fun ref is_empty(): Bool
    """ Returns `true` when the signal does not yet have a value. """

  fun ref non_empty(): Bool =>
    """ Returns `true` when the signal has a value. """
    not is_empty()

  /* TODO: Signal methods
  changes
  is
  becomes
  diff_past
  zip
  sync_with
  past_2
  with_subscription
  */


/* TODO: Classes for Signals
Const
Mutable
Changes
  - ChangesObserver
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
  /* TODO: BuildSignal methods
  const
  mutable
  aggregate
  zip
  */
