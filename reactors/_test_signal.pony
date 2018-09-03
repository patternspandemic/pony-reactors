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


class iso _TestSignalChangesFromEmpty is UnitTest
  let buffer: Array[USize] = Array[USize]

  fun name():String => "signal/changes/from empty"

  fun ref apply(h: TestHelper) =>
    let self = this
    let emitter = BuildEvents.emitter[USize]()
    emitter.to_empty_signal().changes().on_event(
      where
        react_handler = {
          (event: USize, hint: (EventHint | None) = None) =>
            self.buffer.push(event)
        }
    )

    emitter.react(3)
    emitter.react(3)
    emitter.react(5)
    emitter.react(7)
    emitter.react(7)
    emitter.react(11)
    h.assert_array_eq[USize]([3; 5; 7; 11], buffer)


class iso _TestSignalChangesFromInitial is UnitTest
  let buffer: Array[USize] = Array[USize]

  fun name():String => "signal/changes/from initial"

  fun ref apply(h: TestHelper) =>
    let self = this
    let emitter = BuildEvents.emitter[USize]()
    emitter.to_signal(0).changes().on_event(
      where
        react_handler = {
          (event: USize, hint: (EventHint | None) = None) =>
            self.buffer.push(event)
        }
    )

    emitter.react(3)
    emitter.react(3)
    emitter.react(5)
    emitter.react(7)
    emitter.react(7)
    emitter.react(11)
    h.assert_array_eq[USize]([3; 5; 7; 11], buffer)


class iso _TestSignalChangesBasedOnEq is UnitTest
  let buffer: Array[USize] = Array[USize]

  fun name():String => "signal/changes/based on eq"

  fun ref apply(h: TestHelper) =>
    let self = this
    let emitter = BuildEvents.emitter[USize]()
    emitter.to_signal(0).changes({
      (old: USize, new': USize): Bool => not old.eq(new')
      }).on_event(
        where
          react_handler = {
            (event: USize, hint: (EventHint | None) = None) =>
              self.buffer.push(event)
          }
      )

    emitter.react(3)
    emitter.react(3)
    emitter.react(5)
    emitter.react(7)
    emitter.react(7)
    emitter.react(11)
    h.assert_array_eq[USize]([3; 5; 7; 11], buffer)


class tag _ChangesObjectTester
class iso _TestSignalChangesBasedOnIs is UnitTest
  let buffer: Array[_ChangesObjectTester tag] = Array[_ChangesObjectTester tag]

  fun name():String => "signal/changes/based on is"

  fun ref apply(h: TestHelper) =>
    let self = this
    let a: _ChangesObjectTester tag = _ChangesObjectTester
    let b: _ChangesObjectTester tag = _ChangesObjectTester
    let c: _ChangesObjectTester tag = _ChangesObjectTester
    let d: _ChangesObjectTester tag = _ChangesObjectTester

    let emitter = BuildEvents.emitter[_ChangesObjectTester tag]()
    emitter.to_signal(a).changes().on_event(
      where
        react_handler = {(
          event: _ChangesObjectTester tag, hint: (EventHint | None) = None)
        =>
          self.buffer.push(event)
        }
    )

    emitter.react(a)
    emitter.react(b)
    emitter.react(b)
    emitter.react(c)
    emitter.react(d)
    emitter.react(d)
    emitter.react(a)
    // Assert each buffered change is that of the expected.
    for (i, tester) in [b; c; d; a].pairs() do
      try
        h.assert_is[_ChangesObjectTester tag](tester, buffer(i)?)
      else
        h.fail("changed based on identity failed")
      end
    end


class iso _TestSignalIs is UnitTest
  var reacted: Bool = false

  fun name():String => "signal/is_value"

  fun ref apply(h: TestHelper) =>
    let self = this
    let emitter = BuildEvents.emitter[String]()
    emitter.to_signal("").is_value("Pony").on(
      where
        react_handler = {
          () => self.reacted = true
        }
    )

    emitter.react("Horse")
    h.assert_false(reacted)
    emitter.react("Pony")
    h.assert_true(reacted)


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
