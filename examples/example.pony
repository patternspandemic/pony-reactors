use "../reactors"


actor Welcomer is Reactor[String]
  let _reactor_state: ReactorState
  let _out: OutStream

  new create(
    system: ReactorSystem,
    name: String,
    channel_name: String = "main",
    out: Env)?
  =>
    _reactor_state = ReactorState(this, system, name, channel_name) //?
    _out = out

  fun ref reactor_state(): ReactorState => _reactor_state

  be _init() =>
    main().events.on_event({
      (name: String) =>
        _out.print("Welcome " + name + "!")
    })

/* Obtain reserved name prior reactor creation via promise. */
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

/* Force reactor creation to be partial */
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
              (name: String) =>
                _out.print("Welcome " + name + "!")
            })
        end
    end


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

    system().channels.reserve("welcomer") // should  use IVar
      .on_event({
        (rc: ReservedChannel) =>
          let welcomer = Welcomer(system, rc, env.out)
          welcomer << "Ponylang"
      })
/*
    let chnls = system().channels.connection()
    chnls.channel << Reserve("welcomer")
    chnls.events.on_event({
      (name_reservation) =>
        let welcomer = Welcomer(system, name_reservation, env.out)
        welcomer << "Ponylang"
    })
*/