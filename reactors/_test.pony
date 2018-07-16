use "ponytest"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    test(_TestThing)

class iso _TestThing is UnitTest
  fun name():String => "thing"

  fun apply(h: TestHelper) =>
    h.assert_true(false, "Tests not implemented yet.")
