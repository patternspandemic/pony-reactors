use "ponytest"

// primitive _TestHint is EventHint
// primitive _TestEventError is EventError
//   fun apply(): String => "except"

class iso _TestEventsEmitterImmediatelyUnreactToClosed is UnitTest
  var unreacted: Bool = false

  fun name():String => "events/emitter/immediately unreact to closed"

  fun ref apply(h: TestHelper) =>
    let emitter = BuildEvents.emitter[USize]()
    emitter.unreact()

    let me = this
    emitter.on_done({ref () => me.unreacted = true})

    h.assert_true(unreacted)
