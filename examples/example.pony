use "../reactors"


actor Welcomer is Reactor[String]
  let _reactor_state: ReactorState[String]
  let _out: OutStream

  new create(
    system: ReactorSystem,
    reservation: (ChannelReservation | None) = None)
    out: Env)
  =>
    _reactor_state = ReactorState(this, system, reservation)
    _out = out

  fun ref reactor_state(): ReactorState => _reactor_state

  be _init() =>
    main().events.on_event({
      (name: String, hint: OptionalEventHint) =>
        _out.print("Welcome " + name + "!")
        main().seal()
    })


/* Obtain reserved name prior reactor creation via making Main a reactor. */
actor Main is Reactor[None]
  let env: Env
  let system: ReactorSystem
  let _reactor_state: ReactorState

  new create(env': Env) =>
    env = env'
    system = ReactorSystem
    _reactor_state = ReactorState(this, system)

  be _init() =>
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


// Other OLD ideas

/* Obtain reserved name prior reactor creation via promise.
actor Main
  new create(env: Env) =>
    let system ReactorSystem
    let res: Promise[ReservedChannel] = system.channels.reserve("welcomer")
    res.next[None](
      where
        fulfill = {
          (rc: ReservedChannel) =>
            let welcomer = Welcomer(system, rc, env.out)?
            welcomer << "Ponylang"
        },
        rejected = {() => env.out.print("Failed to reserve channel name.")}
    )
*/

/* Force reactor creation to be partial
actor Main
  new create(env: Env) =>
    let system ReactorSystem
    try
      let welcomer = Welcomer(system, "welcomer", env.out)?
      welcomer << "Ponylang"

      let literal_welcomer =
        object is Reactor[String]
          let _reactor_state: ReactorState =
            ReactorState(this, system, "my-literal-reactor")?
          fun ref reactor_state(): ReactorState = _reactor_state
          be _init() =>
            main().events.on_event({
              (name: String, hint: OptionalEventHint) =>
                _out.print("Welcome " + name + "!")
            })
        end
    end
*/
