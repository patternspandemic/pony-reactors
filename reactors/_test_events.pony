use "ponytest"

// primitive _TestHint is EventHint
// primitive _TestEventError is EventError
//   fun apply(): String => "except"

class iso _TestEvents is UnitTest
  fun name():String => "events"

  fun apply(h: TestHelper) =>
    None
