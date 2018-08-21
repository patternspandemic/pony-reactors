use "debug"
use "../../reactors"


actor Welcomer is Reactor[String]
  let _reactor_state: ReactorState[String]
  let _out: OutStream

  new create(
    system: ReactorSystem,
    reservation: (ChannelReservation | None) = None,
    out: OutStream)
  =>
    _reactor_state = ReactorState[String](this, system, reservation)
    _out = out

  fun tag name(): String => "Welcomer"
  fun ref reactor_state(): ReactorState[String] => _reactor_state

  fun ref init() =>
    main().events.on_event({
      (name: String, hint: OptionalEventHint)(main_con = main()) =>
        _out.print("Welcome " + name + "!")
    })


actor Main is Reactor[None]
  let env: Env
  let system: ReactorSystem
  let _reactor_state: ReactorState[None]

  new create(env': Env) =>
    env = env'
    system = ReactorSystem
    _reactor_state = ReactorState[None](this, system)

  fun tag name(): String => "Main"
  fun ref reactor_state(): ReactorState[None] => _reactor_state

  fun ref init() =>
    let welcomer = Welcomer(system, None, env.out)
    welcomer << "Ponylang"
    welcomer << "Reactors"
    /*
    let conn = open[(ChannelReservation | None)]()
    channels() << ChannelReserve(conn.channel, "welcomer")
    conn.events.on_event({
      (res: (ChannelReservation | None), hint: OptionalEventHint) =>
        match res
        | let cr: ChannelReservation =>
          let welcomer = Welcomer(system, cr, env.out)
          welcomer << "Ponylang"
        | None =>
          env.out.print("Denied 'welcomer' reservation")
        end
        conn.seal()
    })
    */
