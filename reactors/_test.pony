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
    test(_TestEventsAfterUnreactsWithThis)
    test(_TestEventsAfterUnreactsWithThat)
    test(_TestEventsAfterUnsubscribesThat)
    test(_TestEventsBatch)
    test(_TestEventsChanged)
    test(_TestEventsCollect)
    test(_TestEventsCollectHint)
    test(_TestEventsConcatStreams)
    test(_TestEventsConcat)
    test(_TestEventsCount)
    test(_TestEventsDefer)
    test(_TestEventsDone)
    test(_TestEventsDrop)
    test(_TestEventsDropAfter)
    test(_TestEventsDropWhile)
    test(_TestEventsEach)
    test(_TestEventsFilter)
    test(_TestEventsFirst)
    test(_TestEventsGet)
    test(_TestEventsGroupBy)
    test(_TestEventsIgnoreExceptions) // Rename IgnoreExcept
    test(_TestEventsIncremental)
    test(_TestEventsLast)
    // test(_TestEventsLiftTry) // Scala specific
    test(_TestEventsMap)
    test(_TestEventsMaterialize)
    test(_TestEventsMutate1)
    test(_TestEventsMutate2)
    test(_TestEventsMutate3)
    test(_TestEventsMux)
    test(_TestEventsOnce)
    test(_TestEventsPartition)
    test(_TestEventsPipe)
    test(_TestEventsPossibly)
    test(_TestEventsRecover) // May need to rename, RecoverExcept
    test(_TestEventsReducePast)
    test(_TestEventsRepeat)
    test(_TestEventsReverse)
    test(_TestEventsSample)
    test(_TestEventsScanPast)
    test(_TestEventsSliding)
    test(_TestEventsSync)
    test(_TestEventsTail)
    test(_TestEventsTake)
    test(_TestEventsTakeWhile)
    test(_TestEventsToColdSignal)
    test(_TestEventsToColdSignalUnsubscribesWithNoObservers)
    test(_TestEventsToColdSignalUnreactsWhenDone)
    test(_TestEventsToColdSignalUsedWithZipRemovesSubscriptions)
    test(_TestEventsToDoneSignal)
    test(_TestEventsToEagerSignal)
    test(_TestEventsToEmptySignal)
    test(_TestEventsToEventBuffer)
    test(_TestEventsToIVar)
    test(_TestEventsToRCell)
    test(_TestEventsToSignal)
    test(_TestEventsToSignalUnreactsWhenDone)
    test(_TestEventsUnionStreams)
    test(_TestEventsUnion)
    // test(_TestEventsUnliftTry) // Scala specific
    test(_TestEventsUnreacted)
    test(_TestEventsUntil)
    test(_TestEventsZipHint)

    /* Signal Tests */
    test(_TestSignalConst)
    test(_TestSignalMutate1)
    test(_TestSignalAggregate)
    test(_TestSignalChanges)
    test(_TestSignalIs)
    test(_TestSignalBecomes)
    test(_TestSignalDiffPast)
    test(_TestSignalZip)
    test(_TestSignalSyncWith)
    test(_TestSignalPast2)
    test(_TestSignalWithSubscription)
