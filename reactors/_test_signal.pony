use "ponytest"


class iso _TestSignalConst is UnitTest
  fun name():String => "signal/const"

  fun ref apply(h: TestHelper) =>
    let s = BuildSignal.const[USize](1)
    h.assert_eq[USize](1, s())


class iso _TestSignalMutate1 is UnitTest
  var length: USize = 0
  var log: MutableSignal[Array[String]] =
    BuildSignal.mutable[Array[String]](Array[String])

  fun name():String => "signal/mutable/mutate1"

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
    h.assert_array_eq[String]([], log())
    emitter.react("one")
    h.assert_eq[USize](1, length)
    h.assert_array_eq[String](["one"], log())
    emitter.react("two")
    h.assert_eq[USize](2, length)
    h.assert_array_eq[String](["one"; "two"], log())


class iso _TestSignalAggregate is UnitTest
  fun name():String => "NI/signal/Aggregate"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestSignalChanges is UnitTest
  fun name():String => "NI/signal/Changes"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestSignalIs is UnitTest
  fun name():String => "NI/signal/Is"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestSignalBecomes is UnitTest
  fun name():String => "NI/signal/Becomes"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestSignalDiffPast is UnitTest
  fun name():String => "NI/signal/DiffPast"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestSignalZip is UnitTest
  fun name():String => "NI/signal/Zip"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestSignalSyncWith is UnitTest
  fun name():String => "NI/signal/SyncWith"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestSignalPast2 is UnitTest
  fun name():String => "NI/signal/Past2"
  fun ref apply(h: TestHelper) => h.fail("not implemented")


class iso _TestSignalWithSubscription is UnitTest
  fun name():String => "NI/signal/WithSubscription"
  fun ref apply(h: TestHelper) => h.fail("not implemented")
