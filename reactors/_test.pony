use "ponytest"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    // Observer Tests
    test(_TestObserver)
    // Subscription Tests
    test(_TestSubscription)
    // Events Tests
    test(_TestEventsEmitterImmediatelyUnreactToClosed)
