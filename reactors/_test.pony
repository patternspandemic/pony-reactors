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
    test(_TestSubscriptionEmpty)
    test(_TestSubscriptionComposite)
    test(_TestSubscriptionProxy)
    test(_TestSubscriptionCollection)
    test(_TestSubscriptionCell)

    /* Events Tests */
    /* - sinks */
    test(_TestEventsImmediatelyUnreactToClosed)
    test(_TestEventsNever)
    test(_TestEventsOnReaction)
    test(_TestEventsOnReactionUnsubscribe)
    test(_TestEventsOnEventOrDone)
    test(_TestEventsOnEvent)
    test(_TestEventsOnMatch)
    test(_TestEventsOn)
    test(_TestEventsOnDone)
    test(_TestEventsOnDoneUnsubscribe)
    test(_TestEventsOnExcept)
    /* - combinators */
    test(_TestEventsAfter)
    test(_TestEventsBatch)
    test(_TestEventsCollect)
    test(_TestEventsCollectHint)
    test(_TestEventsConcatStreams)
    test(_TestEventsConcat)
    test(_TestEventsCount)
    test(_TestEventsDrop)
    test(_TestEventsDropAfter)
    test(_TestEventsDropWhile)
    test(_TestEventsFilter)
    test(_TestEventsFirst)
    test(_TestEventsGet)
    test(_TestEventsGroupBy)
    test(_TestEventsIgnoreExceptions) // Needed?
    test(_TestEventsIncremental)
    test(_TestEventsLiftTry)
    test(_TestEventsMap)
    test(_TestEventsMutate1)
    test(_TestEventsMutate2)
    test(_TestEventsMutate3)
    test(_TestEventsMux)
    test(_TestEventsOnce)
    test(_TestEventsPipe)
    test(_TestEventsPossibly)
    test(_TestEventsRecover)
    test(_TestEventsReducePast)
    test(_TestEventsSample)
    test(_TestEventsScanPast)
    test(_TestEventsSliding)
    test(_TestEventsSync)
    test(_TestEventsTail)
    test(_TestEventsTake)
    test(_TestEventsTakeWhile)
    test(_TestEventsToCold)
    test(_TestEventsToEager)
    test(_TestEventsToEmpty)
    test(_TestEventsToIVar)
    test(_TestEventsToRCell)
    test(_TestEventsToSignal)
    test(_TestEventsUnionStreams)
    test(_TestEventsUnion)
    test(_TestEventsUnliftTry)
    test(_TestEventsUnreacted)
    test(_TestEventsUntil)
    test(_TestEventsZipHint)
