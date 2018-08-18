
primitive ReactorSystemTag


/*
  - Track 'non-daemon' connectors, as to be able to 'terminate' the reactor when all such connectors are sealed. Basically make it so no other actors
  can send messages to the reactor. Channels may be spread far, so it may require some kind of system event telling reactors that a channel is sealed, and therefor to drop val refs to them? (Part of the default ReactorState). But how does a reactor even access/drop channel references captured in event callbacks for instance? This may be a problem.
*/
/* Could also be made generic with ReactorSystemProxy type, for example to deal with custom services? */
class ReactorState[T: Any #send]
  """ An object which manages internal state of a reactor. """
  // Should also be able to supply the real system, to allow for creating reactors within actors.
  let system: ReactorSystem tag
//  let system_proxy: ReactorSystemProxy
  let reactor: Reactor[T]
  let main_connector: Connector[T]
  let system_events: Events[SysEvent]
  // let connectors: MapIs[ChannelTag tag, Connector[Any]]
  let connectors: MapIs[Any tag, Connector[Any]]
  var channels_service: Channel[ChannelsEvent] val

  new create(
    reactor': Reactor[T],
    system': ReactorSystem tag,
    reservation': (ChannelReservation | None) = None)
  =>
    reactor = reactor'
    system = system'

    // TODO: ReactorState.create (order is important)

    //- Setup the system proxy (required for channels interaction)
//    system_proxy = ReactorSystemProxy(reactor, system)

    // Assign a no-op dummy channel as the channels_service...
    channels_service = BuildChannel.dummy[ChannelsEvent]()
    // ...and promise to supplant it with the real thing:
    let promise: Promise[Channel[ChannelsEvent]] = system.channels()
    promise.next[None]({
      (channels_channel: Channel[ChannelsEvent]) =>
        reactor._supplant_channels_service(channels_channel)
    })

    //- Setup system events connector
    //- Setup main connector, optionally registering it with a reserved name
    //- Setup any default event handling
    //- Ensure the reactor's _init get called
    //- Pass system channel/reactor to the ReactorSystem (will send start event)


/* Reactors will need functionality to open channels themselves. They'll then have to push any such channels they want public to the channels service. */

/* Provide a ReactorState helper object to automate creation of needed  */

trait Reactor[E: Any #send]
  """"""
    fun ref reactor_state(): ReactorState

    fun ref main(): Connector[E] =>
      /*
      let main_channel_tag = reactor_state().main_channel_tag
      reactor_state().connectors(main_channel_tag)
      */
      reactor_state().main_connector

    fun ref sys_events(): Events[SysEvent] =>
      reactor_state().system_events

    // TODO: Reactor.system - Use of the system must be partially applied with this reactor. The value of this reactor should then be propogated to each service, for instance to create the proper channels for service values to make their way back to the reactor. Or maybe this value is a wrapper around a ReactorSystem val, a ReactorSystemProxy?
    /*
    fun ref system(): ReactorSystemProxy =>
      reactor_state().system_proxy
    */
    fun ref channels(): Channel[ChannelsEvent] val =>
      reactor_state().channels_service

    fun tag shl(event: E) =>
      """ Shortcut to use a reactor reference itself as its default channel. """
      default_sink(event)

    fun tag default_sink(event: E) =>
      """ The reactor's default channel sink. """
      /*
      _muxed_sink[E](
        reactor_state().main_connector.channel.channel_tag(),
        consume event)
      */
      _muxed_sink[E](this, consume event)
    
    // TODO: Reactor._system_event_sink - Replace ReactorSystemTag with actual system via the proxy
    fun tag _system_event_sink(event: SysEvent) =>
      """ The reactor's system events channel sink. """
      _muxed_sink[SysEvent](ReactorSystemTag, consume event)

    // Extra channels, one time channels, in addition to above..
    // be _muxed_sink[T: (Any #send | E)](channel_tag: ChannelTag tag, event: T) =>
    be _muxed_sink[T: (Any #send | E)](channel_tag: Any tag, event: T) =>
      """
      The reactor's multiplexed sink for events sent to any of its channels.
      This behavior acts as a router for all events sent to the reactor,
      ensuring they make their way to the channel's corresponding emitter.
      """
      iftype T <: Any iso then
        None // channel_tag lookup in reactor_state().connectors, push event to its stream..
      elseif T <: Any val then
        None
      elseif T <: Any tag then
        None
      end
    
    be _supplant_channels_service(
      channels_channel: Channel[ChannelsEvent] val)
    =>
      _reactor_state.channels_service = channels_channel

    // TODO: Reactor.init - Ensure init'd only once
    be _init()
      """"""

/* OLD
// How to add state though?
actor ProtoReactor[T: Any #send] is Reactor[T]
  let name: String
  let channel_name: String = "main"
  let _default_connector: Connector
  let _reactor_system: ReactorSystemProxy
  let _connector_map: MapIs[Channel tag, Events[?]] // ?

  fun open_connector or fun open_channel
*/

actor MyStringReactor is Reactor[String]
  let _reactor_state: ReactorState
  // Other custom reactor state ...

  new create(
    system: ReactorSystem,
    name: String,
    channel_name: String = "main")
  =>
    _reactor_state = ReactorState(system, this, name, channel_name)

  fun ref reactor_state(): ReactorState => _reactor_state

  // Called by default after reactor is registered with the system?
  be _init() =>
    main().events().on( ... /* Mod custom state */ ... )
    let another = open("another_channel")
    system().channels.register(another) // Or add as part of opening channels?
    system().channels.unregister(another) // etc

let hello_reactor = HelloReactor
hello_reactor << "Hello"


// ...
let my_literal_string_reactor =
  object is Reactor[String]
    // let other = CustomState
    let _reactor_state: ReactorState =
      ReactorState(system, "my-literal-reactor")
    fun ref reactor_state(): ReactorState = _reactor_state
    be _init() =>
      main().events.on(...)
  end

// Because can't yet refer to literals in construction, could let system setup the reactor state and callback to init?
reactor_sys.spawn(my_literal_string_reactor) // Calls back to _init() ?
reactor_sys.spawn(MyStringReactor, "name", "default-channel-name") // Could also be required with named reactors
// spawn could maybe somehow inject the required ReactorState w/destructive read, then call _init, would require get/set_reactor_state, along with _reactor_state: (ReactorState | None) = None, matched in getters/setters.. 
// spawn would also be useful to receive back a channel to the reactor.
// ...


// primitive BuildReactor[T: Any #send]
//   """"""
//   fun apply(body: {(Reactor[T])}) =>
//     // ...
//     None

///////////////////////////////////////

/*
BuildReactor[String](
  object
    fun apply(self: Reactor[String]) =>
      self.main.events.on_event({(ev: String) => ... }
  end
)

BuildReactor[String]({
  (self: Reactor[String]) =>
    self.main.events.on_event({(ev: String) => ... })}
)
*/

// Reference Code
/*


trait Thing[E: Stringable #read]
  fun ref main(): Array[E] ref
  fun ref _env(): Env
  be bar(body: {(Thing[E] ref)} val) =>
    body(this)

actor AnonThing[T: Stringable #read] is Thing[T]
  let a: Array[T] ref = Array[T]
  let env: Env
  
  new create(e: Env) =>
    env = e
  
  fun ref main(): Array[T] ref => a
  fun ref _env(): Env => env
  

actor Main
  new create(env: Env) =>
  
    //let a': Array[String] iso = recover iso Array[String] end
    
    let o = object is Thing[String]
      //let _a: Array[String] ref = consume a'
      let a: Array[String] iso = recover Array[String] end
      fun ref main(): Array[String] iso => a
      fun ref _env(): Env => env
      be other() => None // Appease
    end
    
    o.bar({
      (thing: Thing[String] ref) =>
        thing.main().push("Pony")
        thing._env().out.print(
          try
            thing.main().apply(0)?
          else
            "Bummer"
          end)
    })
    
    let anon = AnonThing[String](env)
    anon.bar({
      (thing: Thing[String] ref) =>
        thing.main().push("Lang")
        thing._env().out.print(
          try
            thing.main().apply(0)?
          else
            "Other Bummer"
          end)
    })
*/

///////////

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