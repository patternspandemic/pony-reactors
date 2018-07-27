use "ponytest"

class iso _TestSubscription is UnitTest
  var unsubscribe_cnt: U8 = U8(0)

  fun name():String => "subscription/base"

  fun ref apply(h: TestHelper) =>

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
    h.expect_action("unsubscribe")
    h.expect_action("then act")

    s = BuildSubscription(
      where
        unsubscribe_action = {ref
          () => h.complete_action("unsubscribe")
        }
    ).and_then({ref
      () => h.complete_action("then act")
    })

    s.unsubscribe()

    // Chained unsubscribe asserts
    h.expect_action("this unsubscribed")
    h.expect_action("other unsubscribed")

    s = BuildSubscription(
      where
        unsubscribe_action = {ref
          () => h.complete_action("this unsubscribed")
        }
    ).chain(BuildSubscription(
      where
        unsubscribe_action = {ref
          () => h.complete_action("other unsubscribed")
        }
    ))

    s.unsubscribe()

  fun ref inc_unsubscribe_cnt() =>
    unsubscribe_cnt = unsubscribe_cnt + 1


class iso _TestSubscriptionEmpty is UnitTest
  fun name():String => "NI/subscription/empty"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestSubscriptionComposite is UnitTest
  fun name():String => "NI/subscription/composite"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestSubscriptionProxy is UnitTest
  fun name():String => "NI/subscription/proxy"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestSubscriptionCollection is UnitTest
  fun name():String => "NI/subscription/collection"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestSubscriptionCell is UnitTest
  fun name():String => "NI/subscription/cell"
  fun ref apply(h: TestHelper) => h.fail("not implemented")
