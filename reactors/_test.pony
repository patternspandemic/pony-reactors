use "ponytest"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    /* Observer Tests */
    test(_TestObserver)

    /* Subscription Tests */
    test(_TestSubscription)

    /* Events Tests */
    test(_TestEventsImmediatelyUnreactToClosed)
    test(_TestEventsOnReaction)
    test(_TestEventsOnReactionUnsubscribe)
    test(_TestEventsOnEventOrDone)
    test(_TestEventsOnEvent)
    test(_TestEventsOnMatch)
    test(_TestEventsOn)
    test(_TestEventsOnDone)
    test(_TestEventsOnDoneUnsubscribe)
    test(_TestEventsOnExcept)
    // ...
    test(_TestEventsMutate1)
    test(_TestEventsMutate2)
    test(_TestEventsMutate3)
