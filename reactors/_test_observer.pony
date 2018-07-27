use "ponytest"

primitive _ObserverTestHint is EventHint
primitive _ObserverTestEventError is EventError
  fun apply(): String => "except"

class iso _TestObserver is UnitTest
  fun name():String => "observer"

  fun apply(h: TestHelper) =>
    h.expect_action("react true")
    h.expect_action("react false")
    h.expect_action("react hinted")
    h.expect_action("unreact")
    h.expect_action("except")

    let o: Observer[Bool] = BuildObserver[Bool](
      where
        react' = {
          (b: Bool, hint: (EventHint | None) = None) =>
            match b
            | true => h.complete_action("react true")
            | false => h.complete_action("react false")
            end
            if hint isnt None then
              h.complete_action("react hinted")
            end
        },
        except' = {
          (x: EventError) => h.complete_action(x())
        },
        unreact' = {
          () => h.complete_action("unreact")
        }
    )

    o.react(false)
    o.react(true)
    o.react(true, _ObserverTestHint)
    o.except(_ObserverTestEventError)
    o.unreact()


// TODO: Test other BuildObserver methods? They should be tested via higher level Events functionality.
