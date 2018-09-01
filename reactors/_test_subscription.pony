use "ponytest"

class iso _TestSubscription is UnitTest
  var unsubscribe_cnt: U8 = U8(0)

  var unsubscribed: Bool = false
  var then_acted: Bool = false
  var this_unsubscribed: Bool = false
  var other_unsubscribed: Bool = false

  fun name():String => "subscription/base"

  fun ref apply(h: TestHelper) =>
    let self = this

    // Basic subscription asserts
    var s: Subscription = BuildSubscription(
      where
        unsubscribe_action = {ref
          ()(tester = this) =>
            tester.inc_unsubscribe_cnt()
        }
    )

    h.assert_false(
      s._is_unsubscribed(),
      "Subscription should initially be subscribed.")

    s.unsubscribe() // 1st unsubscribe of subscription

    h.assert_true(
      s._is_unsubscribed(),
      "Subscription should be unsubscribed after call to unsubscribe.")

    s.unsubscribe() // 2nd unsubscribe of subscription

    h.assert_eq[U8](
      1, unsubscribe_cnt,
      "Subscription should only be unsubscribed once.")

    // Action after unsubscribe asserts
    h.assert_false(unsubscribed)
    h.assert_false(then_acted)

    s = BuildSubscription(
      where
        unsubscribe_action = {ref
          () => self.unsubscribed = true
        }
    ).and_then({ref
      () => self.then_acted = true
    })

    s.unsubscribe()
    h.assert_true(unsubscribed)
    h.assert_true(then_acted)

    // Chained unsubscribe asserts
    h.assert_false(this_unsubscribed)
    h.assert_false(other_unsubscribed)

    s = BuildSubscription(
      where
        unsubscribe_action = {ref
          () => self.this_unsubscribed = true
        }
    ).chain(BuildSubscription(
      where
        unsubscribe_action = {ref
          () => self.other_unsubscribed = true
        }
    ))

    s.unsubscribe()
    h.assert_true(this_unsubscribed)
    h.assert_true(other_unsubscribed)

  fun ref inc_unsubscribe_cnt() =>
    unsubscribe_cnt = unsubscribe_cnt + 1


class iso _TestSubscriptionEmpty is UnitTest
  fun name():String => "subscription/empty"

  fun ref apply(h: TestHelper) =>
    let s = BuildSubscription.empty()
    h.assert_true(
      s._is_unsubscribed(),
      "Empty subscription should be unsubscribed by default.")


class iso _TestSubscriptionComposite is UnitTest
  var unsubscribed_a: Bool = false
  var unsubscribed_b: Bool = false

  fun name():String => "subscription/composite"

  fun ref apply(h: TestHelper) =>
    let self = this

    let sub_a: Subscription = BuildSubscription(
      where
        unsubscribe_action = {ref
          () => self.unsubscribed_a = true
        }
    )
    let sub_b: Subscription = BuildSubscription(
      where
        unsubscribe_action = {ref
          () => self.unsubscribed_b = true
        }
    )
    let composite: Subscription =
      BuildSubscription.composite([sub_a; sub_b])

    h.assert_false(unsubscribed_a)
    h.assert_false(unsubscribed_b)
    composite.unsubscribe()
    h.assert_true(unsubscribed_a)
    h.assert_true(unsubscribed_b)


class iso _TestSubscriptionProxy is UnitTest
  var unsubscribed: Bool = false

  fun name():String => "subscription/proxy"

  fun ref apply(h: TestHelper) =>
    let self = this

    let sub: Subscription = BuildSubscription(
      where
        unsubscribe_action = {ref
          () =>
            self.unsubscribed = true
        }
    )
    let proxy: Subscription =
      object is SubscriptionProxy
        let _subscription: Subscription = sub
        fun _is_unsubscribed(): Bool =>
          _subscription._is_unsubscribed()
        fun ref proxy_subscription(): Subscription => _subscription
      end

    h.assert_false(unsubscribed)
    proxy.unsubscribe()
    h.assert_true(unsubscribed)


class iso _TestSubscriptionCollection is UnitTest
  var unsub_cnt: USize = 0
  var unsubscribed_a: Bool = false
  var unsubscribed_b: Bool = false
  var unsubscribed_c: Bool = false
  var unsubscribed_d: Bool = false

  fun name():String => "subscription/collection"

  fun ref apply(h: TestHelper) =>
    let self = this

    let sub_a: Subscription = BuildSubscription(
      where
        unsubscribe_action = {ref
          () =>
            self.unsubscribed_a = true
            self.unsub_cnt = self.unsub_cnt + 1
        }
    )
    let sub_b: Subscription = BuildSubscription(
      where
        unsubscribe_action = {ref
          () =>
            self.unsubscribed_b = true
            self.unsub_cnt = self.unsub_cnt + 1
        }
    )
    let sub_c: Subscription = BuildSubscription(
      where
        unsubscribe_action = {ref
          () =>
            self.unsubscribed_c = true
            self.unsub_cnt = self.unsub_cnt + 1
        }
    )
    let sub_d: Subscription = BuildSubscription(
      where
        unsubscribe_action = {ref
          () =>
            self.unsubscribed_d = true
            self.unsub_cnt = self.unsub_cnt + 1
        }
    )
    let collection: SubscriptionCollection = BuildSubscription.collection()

    h.assert_false(unsubscribed_a)
    h.assert_false(unsubscribed_b)
    h.assert_false(unsubscribed_c)
    h.assert_false(unsubscribed_d)

    h.assert_false(collection._is_unsubscribed())
    h.assert_true(collection.is_empty())
    var sub = collection.add_and_get(sub_a)
    h.assert_false(collection.is_empty())
    sub.unsubscribe()
    // Unsubscribing a subscription that is part of the collection should remove
    // it from the collection
    h.assert_true(unsubscribed_a)
    h.assert_true(
      collection.is_empty(),
      "Unsubscribing an added subscription should remove it")

    sub = collection.add_and_get(sub_b)
    let removed = collection.remove(sub)
    h.assert_false(unsubscribed_b)
    h.assert_true(removed, "sub should have been removed")
    h.assert_true(collection.is_empty())

    collection.add_and_get(sub_b)
    collection.add_and_get(sub_c)
    collection.add_and_get(sub_d)
    collection.unsubscribe()
    h.assert_true(collection._is_unsubscribed())
    h.assert_true(unsubscribed_b)
    h.assert_true(unsubscribed_c)
    h.assert_true(unsubscribed_d)

    h.assert_eq[USize](4, unsub_cnt)


class iso _TestSubscriptionCell is UnitTest
  fun name():String => "NI/subscription/cell"
  fun ref apply(h: TestHelper) => h.fail("not implemented")
