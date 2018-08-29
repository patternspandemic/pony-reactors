use "../../reactors"


actor Welcomer is Reactor[String]
  let _reactor_state: ReactorState[String]
  let _out: OutStream

  new create(
    system: ReactorSystem,
    out: OutStream,
    reservation: (ChannelReservation | None) = None)
  =>
    _reactor_state = ReactorState[String](this, system, reservation)
    _out = out

  fun ref reactor_state(): ReactorState[String] => _reactor_state

  fun ref init() =>
    main().events.on_event({
      (name: String, hint: OptionalEventHint)(self = this) =>
        _out.print("Welcome " + name + "!")
        self.main().seal()
    })


actor Main is Reactor[None]
  let _env: Env
  let _system: ReactorSystem
  let _reactor_state: ReactorState[None]

  new create(env: Env) =>
    _env = env
    _system = ReactorSystem
    _reactor_state = ReactorState[None](this, _system)

  fun ref reactor_state(): ReactorState[None] => _reactor_state

  fun ref init() =>
    let connector = open[(ChannelReservation | None)]()
    channels() << ChannelReserve(connector.channel, "welcomer")
    connector.events.on_event({
      (event: (ChannelReservation | None), hint: OptionalEventHint) =>
        match event
        | let reservation: ChannelReservation =>
          let welcomer = Welcomer(_system, _env.out, reservation)
          welcomer << "Ponylang"
        | None => _env.out.print("Denied reservation.")
        end
        connector.seal()
    })
