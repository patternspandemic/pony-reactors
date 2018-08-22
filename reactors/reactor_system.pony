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

  // Promises to fulfill of the channels service channel
  // let _channels_service_promises: Array[Promise[Channel[ChannelsEvent] val]]
  let _channels_service_promises: Array[ReactorKind tag]

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
    _channels_service_promises = _channels_service_promises.create()
    
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

  // fun tag channels(): Promise[Channel[ChannelsEvent] val] =>
  //    let promise = Promise[Channel[ChannelsEvent] val]
  //    _try_fulfill_channels(promise)
  //    promise

  be request_channels_channel(reactor: ReactorKind) =>
    _try_send_channels_channel(reactor)
  
  fun ref _try_send_channels_channel(reactor: ReactorKind) =>
    match _channels_service
    | let c: Channel[ChannelsEvent] val =>
      Debug.out("Fulfilled right away")
      reactor._supplant_channels_service(c)
    | None =>
      Debug.out("Cached promise")
      _channels_service_promises.push(reactor)
    end

  // be _try_fulfill_channels(promise: Promise[Channel[ChannelsEvent] val]) =>
  //   match _channels_service
  //   | let c: Channel[ChannelsEvent] val =>
  //     Debug.out("Fulfilled right away")
  //     promise(c)
  //   | None =>
  //     Debug.out("Cached promise")
  //     _channels_service_promises.push(promise)
  //     // promise.reject()
  //   end

  be _receive_channels_service(channels_service': Channel[ChannelsEvent] val) =>
    Debug.out("Received Channels Service!")
    _channels_service = channels_service'
    // Fulfill cached promises
    // for p in _channels_service_promises.values() do
    //   Debug.out("Fulfilled delayed")
    //   p(channels_service')
    // end
    for r in _channels_service_promises.values() do
      Debug.out("Fulfilled delayed")
      r._supplant_channels_service(channels_service')
    end
    _channels_service_promises.clear()

/* OLD - will be moved to Channels service. */
  // fun clock(): Clock
  // fun debugger(): Debugger
  // fun io(): Io
  // fun log(): Log
  // fun names(): Names
  // fun net(): Net
  // fun remote(): Remote

  be _receive_service(service: Service tag) =>
    _services.set(service)

  be _receive_reactor(reactor: ReactorKind tag) =>
    _reactors.set(reactor)

  fun tag shutdown() =>
    """ Shut down this reactor system and all its services. """
    _shut_down_services()

  be _shut_down_services() => None
    for service in _services.values() do
      service.shutdown()
    end
