
// TODO: Protocol trait not needed?
trait Protocol
  """ Encapsulation of a set of event streams and channels. """
  fun system(): ReactorSystem tag

trait tag Service
  """ A Protocol that can be shut down. """
  be shutdown()

trait val ServiceBuilder
  fun apply(system: ReactorSystem tag): Service



// Channels Service Types /////////////////////////////////////////////////////
primitive ChannelsService is ServiceBuilder
  fun apply(system: ReactorSystem tag): Channels =>
    Channels(system)

class ChannelReserve
  """"""
  let reactor_name: String
  let channel_name: String
  let reply_channel: Channel[(ChannelReservation | None)] val
  new val create(
    reply_channel': Channel[(ChannelReservation | None)] val,
    reactor_name': String,
    channel_name': String = "main")
  =>
    reply_channel = reply_channel'
    reactor_name = reactor_name'
    channel_name = channel_name'

class ChannelRegister
  """ Register, replace, or forget a channel with a ChannelReservation. """
  let reservation: ChannelReservation val
  let channel: (Channel[(Any iso | Any val | Any tag)] val | None)
  new val create(
    reservation': ChannelReservation val,
    channel: (Channel[(Any iso | Any val | Any tag)] val) | None)
  =>
    reservation = reservation'
    channel = channel'

class ChannelGet[E: Any #send]
  """"""
  let reactor_name: String
  let channel_name: String
  let reply_channel: Channel[(Channel[E] | None)] val
  new val create(
    reply_channel': Channel[(Channel[E] | None)] val,
    reactor_name': String,
    channel_name': String = "main")
  =>
    reply_channel = reply_channel'
    reactor_name = reactor_name'
    channel_name = channel_name'

class ChannelAwait[E: Any #send]
  """"""
  let reactor_name: String
  let channel_name: String
  let reply_channel: Channel[Channel[E]] val
  new val create(
    reply_channel': Channel[Channel[E]] val,
    reactor_name': String,
    channel_name': String = "main")
  =>
    reply_channel = reply_channel'
    reactor_name = reactor_name'
    channel_name = channel_name'

type ChannelsEvent is
  ( ChannelReserve
  | ChannelRegister
  | ChannelGet
  | ChannelAwait
  )

class ChannelReservation
  """"""
  let reserved_key: (String, String)
  new val create(
    reactor_name': String,
    channel_name': String = "main")
  =>
    reserved_key = (reactor_name', channel_name')

// TODO: Channels service
//- Give it the responsibility to lazily create services on demand. If any reactor awaits a channel that describes a reserved standard or custom? service, instantiate that reactor service and provide it. (Replaces ReactorSystemProxy, system() call with regular channel requests.) The Channels channel should be preemptively provided to all ReactorState, given its importance, perhaps via Promise from the ReactorSystem.
actor Channels is (Service & Reactor[ChannelsEvent])
  """"""
  let _reactor_state: ReactorState[ChannelsEvent]
  let _system: (ReactorSystem tag | None)

  // A map of (reactor-name, channel-name) pairs to the registered channel or
  // reservation used to guarrentee the registered name pair.
  let _channel_map: MapIs[
    (String, String),
    (Channel[(Any iso | Any val | Any tag)] val | ChannelReservation val)
  ]

  // A map of (reactor-name, channel-name) pairs to the set of reply channels
  // of reactors awaiting the named channel to be registered.
  let _await_map: MapIs[
    (String, String),
    SetIs[Channel[(Any iso | Any val | Any tag)] val]
  ]

  new create(system': ReactorSystem tag) =>
    _reactor_state = ReactorState[ChannelsEvent](this, system)
    _system = system'
    _channel_map = _channel_map.create()
    _await_map = _await_map.create()
  
  fun ref reactor_state(): ReactorState[ChannelsEvent] => _reactor_state

  be _init() =>
    // Register the default channel of this reactor, the channels service.
    _channel_map(("channels", "main")) =
      object val is Channel[ChannelsEvent]
        let _channel_tag: ChannelTag = ChannelTag
        fun channel_tag(): ChannelTag => _channel_tag
        fun shl(ev: ChannelsEvent) =>
          default_sink(ev)
      end
    
    // TODO: Add reservations for lazily init'd core services.
    
    // TODO: Channels event handling - delegate to funs
    main().events.on_event({
      (event: ChannelsEvent) =>
        match event
        | let reserve: ChannelReserve => None //reserve_channel(reserve)
        | let register: ChannelRegister => None //register_channel(register)
        | let get: ChannelGet => None //get_channel(get)
        | let await: ChannelAwait => None //await_channel(await)
        end
    })

  be shutdown() =>
    _system = None
    _channel_map.clear()
    _await_map.clear()



/*
// Services:
// Clock Service Types ////////////////////////////////////////////////////////
// Debugger Service Types /////////////////////////////////////////////////////
// Io Service Types ///////////////////////////////////////////////////////////
// Log Service Types //////////////////////////////////////////////////////////
// Names Service Types ////////////////////////////////////////////////////////
// Net Service Types //////////////////////////////////////////////////////////
// Remote Service Types ///////////////////////////////////////////////////////
*/
