use "debug"
use "collections"

// TODO: Protocol trait not needed?
trait Protocol
  """ Encapsulation of a set of event streams and channels. """
  fun system(): ReactorSystem tag

trait tag Service
  """ A Protocol reactor that can be shut down to cleanup its resources. """
  be shutdown()

trait val ServiceBuilder
  fun apply(system: ReactorSystem tag): Service



// Channels Service Types /////////////////////////////////////////////////////
primitive ChannelsService is ServiceBuilder
  fun apply(system: ReactorSystem tag): Channels =>
    Channels(system)

class val ChannelReserve
  """"""
  let reactor_name: String
  let channel_name: String
  let reply_channel: Channel[(ChannelReservation val | None)] val
  new val create(
    reply_channel': Channel[(ChannelReservation val | None)] val,
    reactor_name': String,
    channel_name': String = "main")
  =>
    reply_channel = reply_channel'
    reactor_name = reactor_name'
    channel_name = channel_name'

class val ChannelRegister
  """ Register, replace, or forget a channel with a ChannelReservation. """
  let reservation: ChannelReservation val
  // let channel: (Channel[(Any iso | Any val | Any tag)] val | None)
  let channel: (ChannelKind val | None)
  new val create(
    reservation': ChannelReservation val,
    // channel': (Channel[(Any iso | Any val | Any tag)] val | None))
    channel': (ChannelKind val | None))
  =>
    reservation = reservation'
    channel = channel'

// Maybe can use Channel[ChannelKind] in place of Channel[E] to make work with Isolate version?
class val ChannelGet[E: Any #share]
// class val ChannelGet[E: Any val]
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

// Maybe can use Channel[ChannelKind] in place of Channel[E] to make work with Isolate version?
class val ChannelAwait[E: Any #share]
// class val ChannelAwait[E: Any val]
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
  | ChannelGet[(Any val | Any tag)] // FIXME: ? Replace w/subtype
  | ChannelAwait[(Any val | Any tag)] // FIXME: ? Replace w/subtype
  // | ChannelGet[Any val]
  // | ChannelAwait[Any val]
  )

class val ChannelReservation
  """"""
  let reserved_key: (String, String)
  new val create(key: (String, String))
    // reactor_name': String,
    // channel_name': String = "main")
  =>
    // reserved_key = (reactor_name', channel_name')
    reserved_key = key

// TODO: Channels service
//- Give it the responsibility to lazily create services on demand. If any reactor awaits a channel that describes a reserved standard or custom? service, instantiate that reactor service and provide it. (Replaces ReactorSystemProxy, system() call with regular channel requests.) The Channels channel should be preemptively provided to all ReactorState, given its importance, perhaps via Promise from the ReactorSystem.
actor Channels is (Service & Reactor[ChannelsEvent])
  """"""
  let _reactor_state: ReactorState[ChannelsEvent]
  var _system: (ReactorSystem tag | None)

  // A map of (reactor-name, channel-name) pairs to the registered channel or
  // reservation used to guarrentee the registered name pair.
  let _channel_map: MapIs[
    (String, String),
    // (Channel[(Any iso | Any val | Any tag)] val | ChannelReservation val)
    (ChannelKind val | ChannelReservation val)
  ]

  // FIXME: Probs gonna need to replace (Any val | Any tag) with a subtype like you did with the _channel_map. Probs also gonna have to store the await event so the awaited ch can be sent back on the reply ch typed correctly.
  // A map of (reactor-name, channel-name) pairs to the set of reply channels
  // of reactors awaiting the named channel to be registered.
  let _await_map: MapIs[
    (String, String),
    SetIs[Channel[(Any val | Any tag)] val]
    // SetIs[Channel[Any val] val]
  ]

  new create(system': ReactorSystem tag) =>
    _reactor_state = ReactorState[ChannelsEvent](this, system')
    _system = system'
    _channel_map = _channel_map.create()
    _await_map = _await_map.create()
  
  fun tag name(): String => "Channels"
  fun ref reactor_state(): ReactorState[ChannelsEvent] => _reactor_state
  fun tag _is_channels_service(): Bool => true

  fun ref _reserve_channel(ev_reserve: ChannelReserve) =>
    // Build a tuple key out of the reactor, channel names for which the
    // channel should be mapped to.
    let key = (ev_reserve.reactor_name, ev_reserve.channel_name)
    if _channel_map.contains(key) then
      // A channel or reservation is already mapped. Deny the requested reserve.
      ev_reserve.reply_channel << None
end
/*    else
      // The mapping is available.
      let reservation = ChannelReservation(key)
      // Map the key to the reservation until a ChannelRegister event attempts
      // to register a channel with the reservation as its authority to do so.
      _channel_map(key) = reservation
      // Reply with the reservation
      ev_reserve.reply_channel << reservation
    end
*/
  fun ref init() =>
    match _system
    | let system: ReactorSystem tag =>
      // Propogate the main channel to the system for spread to all reactors.
      system._receive_channels_service(main().channel)
      // Add this to the system's services
      system._receive_service(this)
    end

    // Register the main channel in the named channel map as well.
    _channel_map(("channels", "main")) = main().channel

    // TODO: Add reservations for lazily init'd core services.

    // FIXME: ? Replace (Any val | Any tag) w/subtype
    //  - Then will likely need to reply through the event itself, only it knows chan type?
    // i.e. get.reply(_channel_map((get.reactor_name,get.channel_name))?) which will cast subtype to `E`
    // TODO: Channels event handling - delegate to funs
    let pa_reserve_channel = this~_reserve_channel()
    main().events.on_event({ref
      (event: ChannelsEvent, hint: OptionalEventHint) =>
        match event
        | let ev_reserve: ChannelReserve => pa_reserve_channel(ev_reserve)
        | let ev_register: ChannelRegister => None //register_channel(register)
        | let ev_get: ChannelGet[(Any val | Any tag)] => None //get_channel(get)
        | let ev_await: ChannelAwait[(Any val | Any tag)] => None //await_channel(await)
        // | let get: ChannelGet[Any val] => None //get_channel(get)
        // | let await: ChannelAwait[Any val] => None //await_channel
        end
    })

  be shutdown() =>
    // Send shutdown to core services needed?
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


//////// REFERENCE CODE \\\\\\\\\
/*
// Needed 2 subtypes, one for shareables, one for isolates
trait val Bar
trait iso Sar
  //fun apply(): String => ""

class val Foo[T: Any #share] is Bar
  let t: T
  new val create(t': T) => t = t'
  fun apply(): T => t

interface iso Creatable
  new iso create()

class iso Baz[T: Creatable iso] is Sar
  var t: T
  new iso create(t': T) => t = consume t'
  fun ref apply(): T =>
    let t': T iso = T
    let x = t = consume t'
    consume x

class iso Hat
  let s: String
  new iso create() =>
    s = "Cap"

actor Bag
  fun tag apply(): String => "Bagged"
  
actor Main
  let e: Env
  new create(env: Env) =>
    e = env
    
    let ba: Bag tag = Bag
    
    let fs: Foo[String] = Foo[String]("hello")
    let fi: Foo[U8] = Foo[U8](7)
    let fb: Foo[Bag] = Foo[Bag](ba)
    
    let bh: Baz[Hat] = Baz[Hat](Hat)
    
    // Separate collections were needed for the 2 subtypes
    let a: Array[Bar] = Array[Bar]
    let s: Array[Sar] = Array[Sar]
    
    a.push(fs)
    a.push(fi)
    a.push(fb)
    
    s.push(consume bh)
    
    try
      let bh' = s.pop()?
      as_hat(consume bh')?
      
      let fb' = a.pop()?
      as_bag(fb')?
      let fi' = a.pop()?
      as_u8(fi')?
      let fs' = a.pop()?
      as_string(fs')?
    else
      env.out.print("nopes")
    end
    
  fun as_string(b: Bar val)? =>
    e.out.print((b as Foo[String]).apply().string())
    
  fun as_u8(b: Bar val)? =>
    e.out.print((b as Foo[U8]).apply().string())
  
  fun as_bag(b: Bar val)? =>
    e.out.print((b as Foo[Bag]).apply().apply())
  
  fun as_hat(b: Sar iso)? =>
    let s: String = ((consume b) as Baz[Hat]).apply().s
    e.out.print(s)

*/