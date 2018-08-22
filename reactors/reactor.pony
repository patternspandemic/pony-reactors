use "debug"
use "collections"

// primitive ReactorSystemTag

/*
  - Track 'non-daemon' connectors, as to be able to 'terminate' the reactor when all such connectors are sealed. Basically make it so no other actors
  can send messages to the reactor. Channels may be spread far, so it may require some kind of system event telling reactors that a channel is sealed, and therefor to drop val refs to them? (Part of the default ReactorState). But how does a reactor even access/drop channel references captured in event callbacks for instance? This may be a problem.
*/
class ReactorState[T: Any #share]
// class ReactorState[T: Any val]
  """ An object which manages internal state of a reactor. """
  let reactor: Reactor[T]
  let system: ReactorSystem tag
  var channels_service: Channel[ChannelsEvent] val
  let main_connector: Connector[T, T]
  let register_main_channel: Bool
  let reservation: (ChannelReservation | None)
//  let system_events: Events[SysEvent]
  let connectors: MapIs[Any tag, ConnectorKind]
  var received_channels_channel: Bool = false
  var is_initialized: Bool = false

  new create(
    reactor': Reactor[T],
    system': ReactorSystem tag,
    reservation'': (ChannelReservation | None) = None)
  =>
    reactor = reactor'
    system = system'
    reservation = reservation''
    connectors = connectors.create()
    
//?    //- Setup system events connector

    // Configure the main connector..
    main_connector = Connector[T, T](
      where
        channel' = object val is Channel[T]
          let _channel_tag: ChannelTag = ChannelTag
          fun channel_tag(): ChannelTag => _channel_tag
          fun shl(ev: T) =>
            reactor.default_sink(consume ev)
        end,
        events' = BuildEvents.emitter[T](),
        reservation' = reservation''
        // reactor_state' needs to be set after constructing this, so the
        // reference to `this` ReactorState is `ref` rather than `tag`
    )
    // ..and add it to the reactor's collection, main connectors are indexed by
    // their reactor, rather than the channel's own channel_tag.
    connectors(reactor) = main_connector
    reactor._set_reactor_state_on_main_connector()

    // If a ChannelReservation was provided, note to register
    // the main channel when the channels service is fulfilled.
    register_main_channel = not (reservation is None)

    // Assign a no-op dummy channel as the channels_service..
    channels_service = BuildChannel.dummy[ChannelsEvent]()
    // ..and request the channels channel be sent to this reactor. It will be
    // received by the `_supplant_channels_service` behavior.
    system._request_channels_channel(reactor)
    // Note: Tried to use chained promises for the above combined with the init
    // process, but couldn't get it to fulfill. May be worth trying again in
    // future to attempt to avoid extra message sends retrying initialization.

    //- TODO: ReactorState - Setup any default event handling?

    // Ensure the reactor's init gets called
    reactor._wrapped_init()

    // Add the reactor to the system's reactor set
    system._receive_reactor(reactor)



interface tag ReactorKind
  fun tag name(): String
  be _supplant_channels_service(channels_channel: Channel[ChannelsEvent] val)


trait tag Reactor[E: Any #share] is ReactorKind
// trait tag Reactor[E: Any val] is ReactorKind
  """"""
    fun ref reactor_state(): ReactorState[E]

    fun ref main(): Connector[E, E] =>
      reactor_state().main_connector

//    fun ref sys_events(): Events[SysEvent] =>
//      reactor_state().system_events

    fun ref channels(): Channel[ChannelsEvent] val =>
      reactor_state().channels_service

    // TODO: Reactor.open - Support opening new connectors.
    fun ref open() => None

    fun tag shl(event: E) =>
      """ Shortcut to use a reactor reference itself as its default channel. """
      default_sink(consume event)

    fun tag default_sink(event: E) =>
      """ The reactor's default channel sink. """
      _muxed_sink[E](this, consume event)

    // TODO: Reactor._system_event_sink - Replace ReactorSystemTag with actual system via the proxy
//    fun tag _system_event_sink(event: SysEvent) =>
//      """ The reactor's system events channel sink. """
//      _muxed_sink[SysEvent](ReactorSystemTag, consume event)

    // Extra channels, one time channels, in addition to above..
    // be _muxed_sink[T: (Any #share | E)](channel_tag: ChannelTag tag, event: T) =>
    // be _muxed_sink[T: (Any #share | E)](channel_tag: Any tag, event: T) =>
    be _muxed_sink[T: Any #share](channel_tag: Any tag, event: T) =>
      """
      The reactor's multiplexed sink for events sent to any of its channels.
      This behavior acts as a router for all events sent to the reactor,
      ensuring they make their way to the channel's corresponding emitter.
      """
      if reactor_state().is_initialized then
        try
          let conn = reactor_state().connectors(channel_tag)? as Connector[T, E]
          conn.events.react(event)
        else
          // TODO: Reactor._muxed_sink - log no connector match
          None
        end
      else
        // Received an event before the actor received it's _init message.
        // Resend the event to this behavior, allowing the actor to process the
        // _init message which is still in the queue.
        _muxed_sink[T](channel_tag, event)
      end
/*
      iftype T <: Any iso then
        None // channel_tag lookup in reactor_state().connectors, push event to its stream..
      elseif T <: Any val then
        None
      elseif T <: Any tag then
        None
      end
*/

    fun tag _is_channels_service(): Bool =>
      """ Only to be overridden by the channels service reactor. """
      false

    be _supplant_channels_service(
      channels_channel: Channel[ChannelsEvent] val)
    =>
      """ Supplant the dummy channels channel with the real thing. """
      let rs = reactor_state()
      rs.channels_service = channels_channel
      rs.received_channels_channel = true
      if rs.register_main_channel then
        match main().reservation
        | let cr: ChannelReservation =>
          channels() << ChannelRegister(cr, main().channel)
        end
      end

    be _set_reactor_state_on_main_connector() =>
      """ Complete the reactor state's main_connector configuration. """
      main().set_reactor_state(reactor_state())

    be _wrapped_init() =>
      """ Initialize the reactor after receiving the channels channel. """
      let rs = reactor_state()
      // The Channels reactor need not wait for its own channel. Commence when
      // the channels channel is received.
      if (_is_channels_service() or rs.received_channels_channel) then
        init()
        reactor_state().is_initialized = true
      else
        // Try again after other messages in the queue are processed.
        _wrapped_init()
      end
      

    // TODO: Reactor.init - Provide better docstring.
    fun ref init()
      """ The reactor's custom initialization code. """



///////////////////////////////////////

/*
BuildReactor[String](
  object
    fun apply(self: Reactor[String]) =>
      self.main.events.on_event({(ev: String, hint: OptionalEventHint) => ... }
  end
)

BuildReactor[String]({
  (self: Reactor[String]) =>
    self.main.events.on_event({(ev: String, hint: OptionalEventHint) => ... })}
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