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
  let channel: (ChannelKind val | None)
  new val create(
    reservation': ChannelReservation val,
    channel': (ChannelKind val | None))
  =>
    reservation = reservation'
    channel = channel'

// Maybe can use Channel[ChannelKind] in place of Channel[E] to make work with Isolate version?
// class val ChannelGet[E: Any #share]
class val ChannelGet
  """"""
  let reactor_name: String
  let channel_name: String
  // let reply_channel: Channel[(Channel[E] | None)] val
  let reply_channel: Channel[(ChannelKind val | None)] val
  new val create(
    // reply_channel': Channel[(Channel[E] | None)] val,
    reply_channel': Channel[(ChannelKind val | None)] val,
    reactor_name': String,
    channel_name': String = "main")
  =>
    reply_channel = reply_channel'
    reactor_name = reactor_name'
    channel_name = channel_name'

// Maybe can use Channel[ChannelKind] in place of Channel[E] to make work with Isolate version?
// class val ChannelAwait[E: Any #share]
class val ChannelAwait
  """"""
  let reactor_name: String
  let channel_name: String
  // let reply_channel: Channel[Channel[E]] val
  let reply_channel: Channel[ChannelKind val] val
  new val create(
    // reply_channel': Channel[Channel[E]] val,
    reply_channel': Channel[ChannelKind val] val,
    reactor_name': String,
    channel_name': String = "main")
  =>
    reply_channel = reply_channel'
    reactor_name = reactor_name'
    channel_name = channel_name'

type ChannelsEvent is
  ( ChannelReserve
  | ChannelRegister
  | ChannelGet //[(Any val | Any tag)] // FIXME: ? Replace w/subtype
  | ChannelAwait //[(Any val | Any tag)] // FIXME: ? Replace w/subtype
  // | ChannelGet[Any val]
  // | ChannelAwait[Any val]
  )

class val ChannelReservation
  """"""
  let reserved_key: (String, String)
  new val create(key: (String, String)) =>
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
    ((ChannelKind val, ChannelReservation val) | ChannelReservation val)
  ]

  // FIXME: Probs gonna need to replace (Any val | Any tag) with a subtype like you did with the _channel_map. Probs also gonna have to store the await event so the awaited ch can be sent back on the reply ch typed correctly.
  // A map of (reactor-name, channel-name) pairs to the set of reply channels
  // of reactors awaiting the named channel to be registered.
  let _await_map: MapIs[
    (String, String),
    // SetIs[Channel[(Any val | Any tag)] val]
    // SetIs[Channel[Any val] val]
    SetIs[Channel[ChannelKind val] val]
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
    else
      // The mapping is available.
      let reservation = ChannelReservation(key)
      // Map the key to the reservation until a ChannelRegister event attempts
      // to register a channel with the reservation as its authority to do so.
      _channel_map(key) = reservation
      // Reply with the reservation
      ev_reserve.reply_channel << reservation
    end

  fun ref _register_channel(ev_register: ChannelRegister) =>
    let reservation = ev_register.reservation
    let key = reservation.reserved_key
    let channel = ev_register.channel
    // Reservations are only honored when its key been reserved.
    if _channel_map.contains(key) then
      match channel
      | None => // Forget this reservation
        try _channel_map.remove(key)? end
      | let channel': ChannelKind val => // Register or replace.
        try
          let value = _channel_map(key)?
          match value
          | let reservation': ChannelReservation val =>
            // Register if the reservations match.
            if reservation' is reservation then
              _channel_map(key) = (channel, reservation)
              // Send the channel to reactors awaiting the channel.
              _notify_awaiting(key, channel)
            end
          | (let ck: ChannelKind val, let cr: ChannelReservation val) =>
            // TODO: Channels._register_channel - Test channel replacement.
            // Replace existing registration if the reservations match.
            if cr is reservation then
              _channel_map(key) = (channel, reservation)
            end
          end
        end
      end
    end
    // .. otherwise the reservation has expired and is ignored.

  // fun ref _get_channel(ev_get: ChannelGet[(Any val | Any tag)]) =>
  fun ref _get_channel(ev_get: ChannelGet) =>
    let key = (ev_get.reactor_name, ev_get.channel_name)
    if _channel_map.contains(key) then
      // Requested channel is either registered or reserved.
      try
        match _channel_map(key)?
        | (let channel: ChannelKind val, let _: ChannelReservation val) =>
          // Requested channel is registered, send it back on reply_channel.
          ev_get.reply_channel << channel
        else
          // Requested channel not registered. Reply with `None`
          ev_get.reply_channel << None
        end
      end
    else
      // Requested channel not registered. Reply with `None`
      ev_get.reply_channel << None
    end

  // TODO: Channels service - Test _await_channel
  // fun ref _await_channel(ev_await: ChannelAwait[(Any val | Any tag)]) =>
  fun ref _await_channel(ev_await: ChannelAwait) =>
    let key = (ev_await.reactor_name, ev_await.channel_name)
    if _channel_map.contains(key) then
      // Requested channel is either registered or reserved.
      try
        match _channel_map(key)?
        | (let channel: ChannelKind val, let _: ChannelReservation val) =>
          // Requested channel is registered, send it back on reply_channel.
          ev_await.reply_channel << channel
        else
          // Requested channel not registered. Await the channel.
          _add_awaiting(key, ev_await.reply_channel)
        end
      end
    else
      // Requested channel not registered. Await the channel.
      _add_awaiting(key, ev_await.reply_channel)
    end

  fun ref _add_awaiting(
    key: (String, String),
    reply_channel: Channel[ChannelKind val] val)
  =>
    // Initialize a waiting set of channels if needed.
    if not _await_map.contains(key) then
      _await_map(key) = SetIs[Channel[ChannelKind val] val]
    end
    // Add the reply_channel to the waiting set.
    try
      let awaiting_set = _await_map(key)?
      awaiting_set.set(reply_channel)
    end

  fun ref _notify_awaiting(key: (String, String), channel: ChannelKind val) =>
    if _await_map.contains(key) then
      try
        // Notify each awaiting channel of the requested channel.
        let awaiting_set = _await_map(key)?
        for awaiter in awaiting_set.values() do
          awaiter << channel
        end
        // Remove the waiting set of channels after notifying.
        _await_map.remove(key)?
      end
    end

  fun ref init() =>
    // FIXME: ? Replace (Any val | Any tag) w/subtype
    //  - Then will likely need to reply through the event itself, only it knows chan type?
    // i.e. get.reply(_channel_map((get.reactor_name,get.channel_name))?) which will cast subtype to `E`
    main().events.on_event({ref
      (event: ChannelsEvent, hint: OptionalEventHint)(self = this) =>
        match event
        | let ev_reserve: ChannelReserve =>
          self._reserve_channel(ev_reserve)
        | let ev_register: ChannelRegister =>
          self._register_channel(ev_register)
        // | let ev_get: ChannelGet[(Any val | Any tag)] =>
        | let ev_get: ChannelGet =>
          self._get_channel(ev_get)
        // | let ev_await: ChannelAwait[(Any val | Any tag)] =>
        | let ev_await: ChannelAwait =>
          self._await_channel(ev_await)
        // | let get: ChannelGet[Any val] => None //get_channel(get)
        // | let await: ChannelAwait[Any val] => None //await_channel
        end
    })

    // TODO: Add reservations for lazily init'd core services.

    match _system
    | let system: ReactorSystem tag =>
      // Propogate the main channel to the system for spread to all reactors.
      system._receive_channels_service(main().channel)
      // Add this to the system's services
      system._receive_service(this)
    end

    // Register the main channel in the named channel map as well.
    let key = ("channels", "main")
    _channel_map(key) = (main().channel, ChannelReservation(key))

    // Channels service reactor is initialized
    reactor_state().is_initialized = true

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