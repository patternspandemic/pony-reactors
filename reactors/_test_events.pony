use "ponytest"

// primitive _TestHint is EventHint
primitive _SomeTestEventError is EventError
  fun apply(): String => "except"
primitive _OtherTestEventError is EventError
  fun apply(): String => "except"

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
  fun name():String => "events/sinks/on_match"
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
  fun name():String => "events/mutable/mutate2"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestEventsMutate3 is UnitTest
  fun name():String => "events/mutable/mutate3"
  fun ref apply(h: TestHelper) => h.fail("not implemented")
