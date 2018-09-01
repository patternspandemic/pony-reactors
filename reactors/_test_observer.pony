use "ponytest"

primitive _ObserverTestHint is EventHint
primitive _ObserverTestEventError is EventError
  fun apply(): String => "except"

// TODO: _test_observer - Test with all #alias refcap types

class iso _TestObserver is UnitTest
  var reacted_true: Bool = false
  var reacted_false: Bool = false
  var reacted_hinted: Bool = false
  var unreacted: Bool = false
  var excepted: String = ""

  fun name():String => "observer"

  fun ref apply(h: TestHelper) =>
    let self = this

    let o: Observer[Bool] = BuildObserver[Bool](
      where
        react' = {
          (b: Bool, hint: (EventHint | None) = None) =>
            match b
            | true => self.reacted_true = true
            | false => self.reacted_false = true
            end
            if hint isnt None then
              self.reacted_hinted = true
            end
        },
        except' = {
          (x: EventError) => self.excepted = x()
        },
        unreact' = {
          () => self.unreacted = true
        }
    )

    h.assert_false(reacted_true)
    h.assert_false(reacted_false)
    h.assert_false(reacted_hinted)
    h.assert_false(unreacted)
    h.assert_eq[String]("", excepted)
    o.react(false)
    o.react(true)
    o.react(true, _ObserverTestHint)
    o.except(_ObserverTestEventError)
    o.unreact()
    h.assert_true(reacted_true)
    h.assert_true(reacted_false)
    h.assert_true(reacted_hinted)
    h.assert_true(unreacted)
    h.assert_eq[String](_ObserverTestEventError(), excepted)


// TODO: Test other BuildObserver methods? They should be tested via higher level Events functionality.
