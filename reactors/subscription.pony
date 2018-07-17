
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
      var unsubscribed: Bool = false

      fun _is_unsubscribed(): Bool =>
        unsubscribed

      fun ref unsubscribe() =>
        if not unsubscribed then
          unsubscribed = true
          unsubscribe_action()
        end
    end

// TODO: Subscription Implementations
//  empty (singleton)
//  Composite
//  Proxy (trait for a thing that defers to a subscription it has)
//  Collection (mutable version of Composite?)
//  Cell (mutable cell of at most one subscription)
