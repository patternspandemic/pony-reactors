
trait Subscription
  """
  A subscription to some kind of event, processing or computation.
  """
  fun _is_unsubscribed(): Bool
    """ Whether this subscription has unsubscribed.  """

  fun ref unsubscribe()
  """ Stop event propogation on the corresponding event stream. """

  fun ref and_then(action: {ref ()}): Subscription =>
    """
    Returns a new subscription that unsubscribes this, then runs an action.
    """
    BuildSubscription({ref ()(self = this) =>
      self.unsubscribe()
      action()
    })

  fun ref chain(other: Subscription): Subscription =>
    """
    Returns a new subscription that unsubscribes this, and then another.
    """
    BuildSubscription({ref ()(self = this) =>
      self.unsubscribe()
      other.unsubscribe()
    })


class Composite is Subscription
  """
  A subscription composed of several subscriptions. When unsubscribed, all
  component subscriptions get unsubscribed.
  """
  let _subscriptions: Array[Subscription]
  var _unsubscribed: Bool = false

  new create(subscriptions: Array[Subscription]) =>
    _subscriptions = subscriptions

  fun _is_unsubscribed(): Bool =>
    _unsubscribed

  fun ref unsubscribe() =>
    for s in _subscriptions.values() do
      s.unsubscribe()
      _unsubscribed = true
    end


primitive BuildSubscription
  """ Subscription Builder """

  fun apply(
    unsubscribe_action: {ref ()})
    : Subscription
  =>
    """
    Create and return a subscription that runs the specified action when
    unsubscribed. The action will not be run more than once.
    """
    object is Subscription
      var _unsubscribed: Bool = false

      fun _is_unsubscribed(): Bool =>
        _unsubscribed

      fun ref unsubscribe() =>
        if not _unsubscribed then
          _unsubscribed = true
          unsubscribe_action()
        end
    end

  fun empty(): Subscription =>
    """ A subscription that does not unsubscribe from anything. """
    object ref is Subscription
      fun ref unsubscribe() => None
      fun _is_unsubscribed(): Bool => true
    end

  fun composite(subscriptions: Array[Subscription]): Subscription =>
    """ A subscription composed of many subscriptions. """
    Composite(subscriptions)

// TODO: Subscription Implementations
//  Proxy (trait for a thing that defers to a subscription it has)
//  Collection (mutable version of Composite?)
//  Cell (mutable cell of at most one subscription)
