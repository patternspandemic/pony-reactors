use "../../reactors"


actor Welcomer is Reactor[String]
  let _reactor_state: ReactorState[String]
  let _out: OutStream

  new create(
    system: ReactorSystem,
    out: OutStream)
  =>
    _reactor_state = ReactorState[String](this, system)
    _out = out

  fun ref reactor_state(): ReactorState[String] => _reactor_state

  fun ref init() =>
    main().events.on_event({
      (name: String, hint: OptionalEventHint)(self = this) =>
        _out.print("Welcome " + name + "!")
        self.main().seal()
    })


actor Main
  new create(env: Env) =>
    let system = ReactorSystem
    let welcomer = Welcomer(system, env.out)
    welcomer << "Ponylang"
