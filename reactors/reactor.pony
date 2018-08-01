
/*
A reactor may also have to have a collection of match tests for C?
Looking more like will need separate be's for each send cap, _in_val, _in_iso, _in_tag...
*/

trait Reactor[E: Any #send]
  """"""
    fun ref main(): Connector[E]

    fun ref sys_events(): Events[SysEvent]

    fun system(): ReactorSystem

    // Needed channel receives:
    //  - default
    //  - system events
    //  - opened/additional reactor channels
    //  - one off reply channels

    fun tag default(event: E) =>
      _in[E](this, consume event)

    be _in[T: (Any #send | E)](channel_label: Any tag, event: T) =>
      """ The reactor's router for events sent to any of its channels. """
      iftype T <: Any iso then
        None
      elseif T <: Any val then
        None
      elseif T <: Any tag then
        None
      end

///////////////////////////////////////
// Reference Code
/*

actor Doubler
  //be default(x: I32, c: {(I32)} val) =>
  be default(e: (I32, {(I32)} val)) =>
    (let x, let c) = e
    c(x + x)

actor Capitalizer
  //be default(s: String iso, c: {(String iso)} val) =>
  be default(e: (String iso, {(String iso)} val)) =>
    (let s, let c) = consume e
    let r: String iso = recover iso
      let x = consume s
      x.upper()
    end
    c(consume r)

actor Foo[T: Any #send]
  let _env: Env
  
  new create(env: Env) =>
    _env = env

  be test_val() =>
    let dblr_chnl = object
      let _foo: Foo[T] = this
      fun shl(ev: I32) =>
        let dblr = Doubler
        // Event sent is tuple of value & reply channel
        dblr.default(
          //(ev, _foo~reply_channel[Doubler, I32](dblr))
          (ev, _foo~reply_channel[I32](dblr))
        )
    end
    
    dblr_chnl << 1
  
  be test_iso() =>
    let cap_chnl = object
      let _foo: Foo[T] = this
      fun shl(ev: String iso) =>
        let cap = Capitalizer
        cap.default(
          //(consume ev, _foo~reply_channel[Capitalizer, String iso](cap))
          (consume ev, _foo~reply_channel[String iso](cap))
        )
    end
    
    let strings: Array[String val] = [
      "hello"
    ]
    
    for word in strings.values() do
      let s = recover iso
        let m = String
        m.append(word)
        m
      end
      cap_chnl << consume s
    end
    
  fun tag default(e: T) =>
    reply_channel[T](this, consume e)
  
  be reply_channel[U: (Any #send | T)](c: Any tag, x: U) =>
    iftype U <: Any iso then
      //let ei: Any iso = consume x
      _env.out.print("Event was iso")
      match c
      | let _: Capitalizer =>
        let s = try (x as String iso) else "Capitalizer Wups" end
        _env.out.print(consume s)
      end
    elseif U <: Any val then
      //let ev: Any val = x
      _env.out.print("Event was val")
      match c
      | let _: Doubler =>
        let s = try (x as I32).string() else "Doubler Wups" end
        _env.out.print(s)
      | let _: Foo[U] =>
        let s = try (x as I32).string() else "Foo Wups" end
        _env.out.print(s + " from default!!!")
      end
    elseif U <: Any tag then
      //let et: Any tag = x
      _env.out.print("Event was tag")
    end


actor Main
  new create(env: Env val) =>
    let foo = Foo[I32](env)
    foo.test_val()
    foo.test_iso()
    foo.default(I32(777))

*/