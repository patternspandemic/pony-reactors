use "ponytest"

// primitive _TestHint is EventHint
primitive _SomeTestEventError is EventError
  fun apply(): String => "except"
primitive _OtherTestEventError is EventError
  fun apply(): String => "except"

// TODO: _TestEventsPush? Its functionality tested through other event tests.
// TODO: _TestEventsEmitter? Its functionality tested through other event tests.
// TODO: _TestEventsMutable? Its functionality tested through mutate eventtests.

class iso _TestEventsNever is UnitTest
  var unreacted: Bool = false

  fun name():String => "events/never"

  fun ref apply(h: TestHelper) =>
    let self = this
    let emitter = BuildEvents.never[None]()
    emitter.on_done({ref () => self.unreacted = true})
    h.assert_true(unreacted)


class iso _TestEventsImmediatelyUnreactToClosed is UnitTest
  var unreacted: Bool = false

  fun name():String => "events/immediately unreact to closed"

  fun ref apply(h: TestHelper) =>
    let self = this
    let emitter = BuildEvents.emitter[USize]()
    emitter.unreact()
    emitter.on_done({ref () => self.unreacted = true})
    h.assert_true(unreacted)


class iso _TestEventsOnReaction is UnitTest
  var event: (String | None) = None
  var event_error: (EventError | None) = None
  var unreacted: Bool = false

  fun name():String => "events/sinks/on_reaction"

  fun ref apply(h: TestHelper) =>
    let self = this
    let emitter = BuildEvents.emitter[String]()
    emitter.on_reaction(BuildObserver[String](
      where
        react' = {
          (s: String, hint: (EventHint | None) = None) => self.event = s
        },
        except' = {
          (x: EventError) => self.event_error = x
        },
        unreact' = {
          () => self.unreacted = true
        }
    ))

    emitter.react("ok")
    try h.assert_eq[String]("ok", event as String)
    else h.fail("react event not propogated") end
    try h.assert_is[None](None, event_error as None)
    else h.fail("except event without except") end
    h.assert_false(unreacted, "unreact event without unreact")

    emitter.except(_SomeTestEventError)
    try h.assert_eq[String]("ok", event as String)
    else h.fail("`event` should still be String") end
    try h.assert_is[_SomeTestEventError](
      _SomeTestEventError,
      event_error as _SomeTestEventError)
    else h.fail("except event not propogated") end
    h.assert_false(unreacted, "unreact event without unreact")

    emitter.unreact()
    try h.assert_eq[String]("ok", event as String)
    else h.fail("`event` should still be a String") end
    try h.assert_is[_SomeTestEventError](
      _SomeTestEventError,
      event_error as _SomeTestEventError)
    else h.fail("`event_error` should still be `_SomeTestEventError`") end
    h.assert_true(unreacted, "unreact event not propogated")

    emitter.react("nope")
    emitter.except(_OtherTestEventError)
    unreacted = false
    emitter.unreact()
    try h.assert_eq[String]("ok", event as String)
    else h.fail("`event` should still be a String") end
    try h.assert_is[_SomeTestEventError](
      _SomeTestEventError,
      event_error as _SomeTestEventError)
    else h.fail("`event_error` should still be `_SomeTestEventError`") end
    h.assert_false(unreacted, "unreact event propogated more than once")


class iso _TestEventsOnReactionUnsubscribe is UnitTest
  var event: (String | None) = None
  var event_error: (EventError | None) = None
  var unreacted: Bool = false

  fun name():String => "events/sinks/on_reaction/unsubscribe"

  fun ref apply(h: TestHelper) =>
    let self = this
    let emitter = BuildEvents.emitter[String]()
    let sub = emitter.on_reaction(BuildObserver[String](
      where
        react' = {
          (s: String, hint: (EventHint | None) = None) => self.event = s
        },
        except' = {
          (x: EventError) => self.event_error = x
        },
        unreact' = {
          () => self.unreacted = true
        }
    ))

    emitter.react("ok")
    try h.assert_eq[String]("ok", event as String)
    else h.fail("react event not propogated") end
    try h.assert_is[None](None, event_error as None)
    else h.fail("except event without except") end
    h.assert_false(unreacted, "unreact event without unreact")

    sub.unsubscribe()

    emitter.react("nope")
    try h.assert_eq[String]("ok", event as String)
    else h.fail("`event` should still be String") end
    try h.assert_is[None](None, event_error as None)
    else h.fail("except event without except") end
    h.assert_false(unreacted, "unreact event without unreact")


class iso _TestEventsOnEventOrDone is UnitTest
  var event: (String | None) = None
  var unreacted: Bool = false

  fun name():String => "events/sinks/on_event_or_done"

  fun ref apply(h: TestHelper) =>
    let self = this
    let emitter = BuildEvents.emitter[String]()
    emitter.on_event_or_done(
      where
        react_handler = {
          (s: String, hint: (EventHint | None) = None) => self.event = s
        },
        unreact_handler = {
          () => self.unreacted = true
        }
    )

    emitter.react("ok")
    try h.assert_eq[String]("ok", event as String)
    else h.fail("react event not propogated") end
    h.assert_false(unreacted, "unreact event without unreact")

    emitter.unreact()
    try h.assert_eq[String]("ok", event as String)
    else h.fail("`event` should still be a String") end
    h.assert_true(unreacted, "unreact event not propogated")


class iso _TestEventsOnEvent is UnitTest
  var event: (String | None) = None

  fun name():String => "events/sinks/on_event"

  fun ref apply(h: TestHelper) =>
    let self = this
    let emitter = BuildEvents.emitter[String]()
    let sub = emitter.on_event(
      where
        react_handler = {
          (s: String, hint: (EventHint | None) = None) => self.event = s
        }
    )

    emitter.react("ok")
    try h.assert_eq[String]("ok", event as String)
    else h.fail("react event not propogated") end

    sub.unsubscribe()

    emitter.react("other")
    try h.assert_eq[String]("ok", event as String)
    else h.fail("`event` should still be a String") end


class iso _TestEventsOnMatch is UnitTest
  fun name():String => "NI/events/sinks/on_match"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsOn is UnitTest
  var count: U32 = 0

  fun name():String => "events/sinks/on"

  fun ref apply(h: TestHelper) =>
    let self = this
    let emitter = BuildEvents.emitter[String]()
    let sub = emitter.on(
      where
        react_handler = {
          () => self.count = self.count + 1
        }
    )

    h.assert_eq[U32](0, count)
    emitter.react("first")
    h.assert_eq[U32](1, count)
    emitter.react("second")
    h.assert_eq[U32](2, count)
    sub.unsubscribe()
    emitter.react("ignored")
    h.assert_eq[U32](2, count)


class iso _TestEventsOnDone is UnitTest
  var unreacted: Bool = false

  fun name():String => "events/sinks/on_done"

  fun ref apply(h: TestHelper) =>
    let self = this
    let emitter = BuildEvents.emitter[String]()
    emitter.on_done(
      where
        unreact_handler = {
          () => self.unreacted = true
        }
    )

    h.assert_false(unreacted)
    emitter.react("event")
    h.assert_false(unreacted)
    emitter.unreact()
    h.assert_true(unreacted)


class iso _TestEventsOnDoneUnsubscribe is UnitTest
  var unreacted: Bool = false

  fun name():String => "events/sinks/on_done/unsubscribe"

  fun ref apply(h: TestHelper) =>
    let self = this
    let emitter = BuildEvents.emitter[String]()
    let sub = emitter.on_done(
      where
        unreact_handler = {
          () => self.unreacted = true
        }
    )

    h.assert_false(unreacted)
    emitter.react("event")
    h.assert_false(unreacted)
    sub.unsubscribe()
    emitter.unreact()
    h.assert_false(unreacted)


class iso _TestEventsOnExcept is UnitTest
  var error_found: Bool = false

  fun name():String => "events/sinks/on_except"

  fun ref apply(h: TestHelper) =>
    let self = this
    let emitter = BuildEvents.emitter[String]()
    emitter.on_except(
      where
        except_handler = {
          (e: EventError) =>
            match e
            | _SomeTestEventError => self.error_found = true
            end
        }
    )

    h.assert_false(error_found)
    emitter.except(_OtherTestEventError)
    h.assert_false(error_found)
    emitter.except(_SomeTestEventError)
    h.assert_true(error_found)


class iso _TestEventsAfter is UnitTest
  fun name():String => "NI/events/After"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsBatch is UnitTest
  fun name():String => "NI/events/Batch"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsChanged is UnitTest
  fun name():String => "NI/events/Changed"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsCollect is UnitTest
  fun name():String => "NI/events/Collect"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsCollectHint is UnitTest
  fun name():String => "NI/events/CollectHint"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsConcatStreams is UnitTest
  fun name():String => "NI/events/ConcatStreams"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsConcat is UnitTest
  fun name():String => "NI/events/Concat"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsCount is UnitTest
  fun name():String => "NI/events/Count"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsDefer is UnitTest
  fun name():String => "NI/events/Defer"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsDone is UnitTest
  fun name():String => "NI/events/Done"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsDrop is UnitTest
  fun name():String => "NI/events/Drop"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsDropAfter is UnitTest
  fun name():String => "NI/events/DropAfter"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsDropWhile is UnitTest
  fun name():String => "NI/events/DropWhile"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsEach is UnitTest
  fun name():String => "NI/events/Each"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsFilter is UnitTest
  fun name():String => "NI/events/Filter"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsFirst is UnitTest
  fun name():String => "NI/events/First"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsGet is UnitTest
  fun name():String => "NI/events/Get"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsGroupBy is UnitTest
  fun name():String => "NI/events/GroupBy"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsIgnoreExceptions is UnitTest
  fun name():String => "NI/events/IgnoreExceptions"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsIncremental is UnitTest
  fun name():String => "NI/events/Incremental"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsLast is UnitTest
  fun name():String => "NI/events/Last"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


/*
// Scala specific
class iso _TestEventsLiftTry is UnitTest
  fun name():String => "NI/events/LiftTry"
  fun ref apply(h: TestHelper) => h.fail("not implemented")
*/


class iso _TestEventsMap is UnitTest
  fun name():String => "NI/events/Map"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsMaterialize is UnitTest
  fun name():String => "NI/events/Materialize"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsMutate1 is UnitTest
  var length: USize = 0
  var log: Mutable[Array[String]] =
    BuildEvents.mutable[Array[String]](Array[String])

  fun name():String => "events/mutable/mutate1"

  fun ref apply(h: TestHelper) =>
    let self = this
    let emitter = BuildEvents.emitter[String]()
    emitter.mutate[Array[String]](
      where
        mutable = log,
        mutator = {ref (a: Array[String], e: String) =>
          a.push(e)
        }
    )
    log.on_event(
      where
        react_handler = {
          (a: Array[String], hint: (EventHint | None) = None) =>
            self.length = a.size()
        }
    )

    h.assert_eq[USize](0, length)
    emitter.react("one")
    h.assert_eq[USize](1, length)
    emitter.react("two")
    h.assert_eq[USize](2, length)
    h.assert_array_eq[String](
      ["one"; "two"],
      log.content
    )


class iso _TestEventsMutate2 is UnitTest
  fun name():String => "NI/events/mutable/mutate2"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsMutate3 is UnitTest
  fun name():String => "NI/events/mutable/mutate3"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsMux is UnitTest
  fun name():String => "NI/events/Mux"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsOnce is UnitTest
  fun name():String => "NI/events/Once"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsPartition is UnitTest
  fun name():String => "NI/events/Partition"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsPipe is UnitTest
  fun name():String => "NI/events/Pipe"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsPossibly is UnitTest
  fun name():String => "NI/events/Possibly"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsRecover is UnitTest
  fun name():String => "NI/events/Recover"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsReducePast is UnitTest
  fun name():String => "NI/events/ReducePast"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsRepeat is UnitTest
  fun name():String => "NI/events/Repeat"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsReverse is UnitTest
  fun name():String => "NI/events/Reverse"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsSample is UnitTest
  fun name():String => "NI/events/Sample"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsScanPast is UnitTest
  fun name():String => "NI/events/ScanPast"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsSliding is UnitTest
  fun name():String => "NI/events/Sliding"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsSync is UnitTest
  fun name():String => "NI/events/Sync"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsTail is UnitTest
  fun name():String => "NI/events/Tail"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsTake is UnitTest
  fun name():String => "NI/events/Take"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsTakeWhile is UnitTest
  fun name():String => "NI/events/TakeWhile"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsToCold is UnitTest
  fun name():String => "NI/events/ToCold"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsToDoneSignal is UnitTest
  fun name():String => "NI/events/ToDoneSignal"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsToEager is UnitTest
  fun name():String => "NI/events/ToEager"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsToEmpty is UnitTest
  fun name():String => "NI/events/ToEmpty"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsToEventBuffer is UnitTest
  fun name():String => "NI/events/ToEventBuffer"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsToIVar is UnitTest
  fun name():String => "NI/events/ToIVar"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsToRCell is UnitTest
  fun name():String => "NI/events/ToRCell"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsToSignal is UnitTest
  fun name():String => "NI/events/ToSignal"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsUnionStreams is UnitTest
  fun name():String => "NI/events/UnionStreams"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsUnion is UnitTest
  fun name():String => "NI/events/Union"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


/*
// Scala specific
class iso _TestEventsUnliftTry is UnitTest
  fun name():String => "NI/events/UnliftTry"
  fun ref apply(h: TestHelper) => h.fail("not implemented")
*/


class iso _TestEventsUnreacted is UnitTest
  fun name():String => "NI/events/Unreacted"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsUntil is UnitTest
  fun name():String => "NI/events/Until"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsZipHint is UnitTest
  fun name():String => "NI/events/ZipHint"
  fun ref apply(h: TestHelper) => h.fail("not implemented")
