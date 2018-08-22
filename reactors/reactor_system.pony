use "debug"
use "collections"
use "promises"

// type SysEvent is ...

// TODO: ReactorSystem - Support custom services.
//    * Custom service builders could be provided at ReactorSystem creation time. Supporting a custom service after this would require an actor behind the scenes and Promises or the like?
actor ReactorSystem
  """
  A system used to create, track, and identify reactors.
  """
  // let _reactors: SetIs[Reactor[(Any iso | Any val | Any tag)]]
  let _reactors: SetIs[ReactorKind tag]
  let _services: SetIs[Service tag]

  // A cache of reactors that have requested the channels channel when not avail
  let _cached_channels_requestors: Array[ReactorKind tag]

  // Standard System Services
  var _channels_service: (Channel[ChannelsEvent] val | None) = None
  // let clock: Clock
  // let debugger: Debugger
  // let io: Io
  // let log: Log
  // let names: Names
  // let net: Net
  // let remote: Remote

  // new val create(name': String) =>
  new create()
    // custom_services: Array[ServiceBuilder] val =
    //   recover val [as ServiceBuilder:] end)
  =>
    _reactors = _reactors.create()
    _services = _services.create()
    _cached_channels_requestors = _cached_channels_requestors.create()
    
    // Create a Channels service, which will register itself as a service in
    // this system, as well as its main channel within itself for use by other
    // reactors.
    // ...
    // TODO: ReactorSystem.create - pass in other services to be init'd by the
    //  channels service.? Or handle directly in Channels?
    ChannelsService(this)
/*
    // A collection of reactor system services
    let services': MapIs[ServiceBuilder, Service] trn =
      recover trn services'.create() end

    // Generate standard reactor system services
    channels = ChannelsService(this); services'(ChannelsService) = channels
    //clock = ClockService(this); services'(ClockService) = clock
    //debugger = DebuggerService(this); services'(DebuggerService) = debugger
    //io = IoService(this); services'(IoService) = io
    //log = LogService(this); services'(LogService) = log
    //names = NamesService(this); services'(NamesService) = names
    //net = NetService(this); services'(NetService) = net
    //remote = RemoteService(this); services'(RemoteService) = remote

    // Process the list of custom ServiceBuilders.
    for service_builder in custom_services.values() do
      let service: Service = service_builder(this)
      services'(service_builder) = service
    end

    services = consume services'
*/

  be _request_channels_channel(reactor: ReactorKind) =>
    """ Used by new reactors to request the channels service channel. """
    _try_send_channels_channel(reactor)
  
  fun ref _try_send_channels_channel(reactor: ReactorKind) =>
    """ Try to supplant the channels channel now or cache for latter. """
    match _channels_service
    | let c: Channel[ChannelsEvent] val => reactor._supplant_channels_service(c)
    | None => _cached_channels_requestors.push(reactor)
    end

  be _receive_channels_service(channels_service': Channel[ChannelsEvent] val) =>
    """ Receive the channels service channel from said service. """
    _channels_service = channels_service'
    // Send the channels channel to all cached reactors awaiting supplantation.
    for r in _cached_channels_requestors.values() do
      r._supplant_channels_service(channels_service')
    end
    _cached_channels_requestors.clear()

/* OLD - will be moved to Channels service. */
  // fun clock(): Clock
  // fun debugger(): Debugger
  // fun io(): Io
  // fun log(): Log
  // fun names(): Names
  // fun net(): Net
  // fun remote(): Remote

  be _receive_service(service: Service tag) =>
    """ Receive a system service. """
    _services.set(service)

  be _receive_reactor(reactor: ReactorKind tag) =>
    """ Receive a system reactor. """
    _reactors.set(reactor)

  fun tag shutdown() =>
    """ Shut down this reactor system and all its services. """
    _shut_down_services()

  be _shut_down_services() => None
    for service in _services.values() do
      service.shutdown()
    end
