use "collections"

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


trait SubscriptionProxy is Subscription
  """ Forwards `unsubscribe` to another subscription. """
  fun ref proxy_subscription(): Subscription
    """ The subscription this is proxy to. """

  fun ref unsubscribe() =>
    """ Unsubscribing this proxy unsubscribes the proxied. """
    proxy_subscription().unsubscribe()


class SubscriptionComposite is Subscription
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
    if not _unsubscribed then
      _unsubscribed = true
      for s in _subscriptions.values() do
        s.unsubscribe()
      end
    end


class tag SubscriptionTag

class SubscriptionCollection is Subscription
  """
  A mutable collection of subscriptions, itself a subscription. When
  unsubscribed, all containing subscriptions are also unsubscribed.
  Subsequently added subscriptions are automatically unsubscribed.
  """
  // TODO: SubscriptionCollection - Remove _tag_map if Pony ever lets you ref a thing while being built. See below.
  // A separate tag mapping to subscriptions was required because needed a way
  // to reference the subscription from inside when being built.
  let _tag_map: MapIs[SubscriptionTag, Subscription] =
    MapIs[SubscriptionTag, Subscription]
  let _subscriptions: SetIs[Subscription] = SetIs[Subscription]
  var _unsubscribed: Bool = false

  fun _is_unsubscribed(): Bool =>
    _unsubscribed

  fun ref unsubscribe() =>
    """ Unsubscribe this and all subscriptions in the collection. """
    if not _unsubscribed then
      _unsubscribed = true
      for s in _subscriptions.values() do
        s.unsubscribe()
      end
      _subscriptions.clear()
      _tag_map.clear()
    end

  fun ref add_and_get(subscription: Subscription): Subscription =>
    """ Add a subscription to the collection and get it returned. """
    if _unsubscribed then
      subscription.unsubscribe()
      BuildSubscription.empty()
    else
      let sub_key = SubscriptionTag
      let new_subscription = BuildSubscription(
        where
          unsubscribe_action = {ref
            ()(collection = this, sub = subscription) =>
              sub.unsubscribe()
              collection._remove(sub_key)
          }
      )
      _tag_map(sub_key) = new_subscription
      _subscriptions.set(new_subscription)
      new_subscription
    end

  fun ref _remove(subscription_key: SubscriptionTag) =>
    """ Remove a subscription from the collection by key. """
    try
      let sub = _tag_map.remove(subscription_key)?._2
      remove(sub)
      true
    else
      false
    end

  fun ref remove(subscription: Subscription): Bool =>
    """ Given a subscription, remove it from the collection. """
    try
      // Only extract when the collection is not unsubscribed, otherwise errors
      // occur in the unsubscribe loop.
      if not _unsubscribed then
        _subscriptions.extract(subscription)?
      end
      true
    else
      false
    end

  fun is_empty(): Bool => _subscriptions.size() == 0


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
    object ref is Subscription
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
    SubscriptionComposite(subscriptions)

  fun collection(): SubscriptionCollection =>
    """ A subscription composed of many subscriptions. """
    SubscriptionCollection

// TODO: Subscription Implementations
//  - Cell (mutable cell of at most one subscription)
