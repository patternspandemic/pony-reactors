use "ponytest"

// primitive _TestHint is EventHint
primitive _SomeTestEventError is EventError
  fun apply(): String => "except"
primitive _OtherTestEventError is EventError
  fun apply(): String => "except"

class iso _TestEventsEmitterImmediatelyUnreactToClosed is UnitTest
  var unreacted: Bool = false

  fun name():String => "events/emitter/immediately unreact to closed"

  fun ref apply(h: TestHelper) =>
    let me = this
    let emitter = BuildEvents.emitter[USize]()
    emitter.unreact()
    emitter.on_done({ref () => me.unreacted = true})
    h.assert_true(unreacted)


class iso _TestEventsOnReaction is UnitTest
  var event: (String | None) = None
  var event_error: (EventError | None) = None
  var unreacted: Bool = false

  fun name():String => "events/sinks/on_reaction"

  fun ref apply(h: TestHelper) =>
    let me = this
    let emitter = BuildEvents.emitter[String]()
    emitter.on_reaction(BuildObserver[String](
      where
        react' = {
          (s: String, hint: (EventHint | None) = None) => me.event = s
        },
        except' = {
          (x: EventError) => me.event_error = x
        },
        unreact' = {
          () => me.unreacted = true
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
