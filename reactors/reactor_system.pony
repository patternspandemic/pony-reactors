use "collections"

trait SysEvent

/*
What if all these service accessors returned channels that took request event types, and returned their results to a one off reply channel of the reactor making the request?!
*/
trait Services
  fun channels(): Channels
  // fun clock(): Clock
  // fun debugger(): Debugger
  // fun io(): Io
  // fun log(): Log
  // fun names(): Names
  // fun net(): Net
  // fun remote(): Remote


// TODO: ReactorSystem - Support custom services.
//    * Custom service builders could be provided at ReactorSystem creation time. Supporting a custom service after this would require an actor behind the scenes and Promises or the like?
actor ReactorSystem //is Services
  """
  A system used to create, track, and identify reactors.
  """
  // var services: MapIs[ServiceBuilder, Service] val =
  //   recover val services.create(0) end
  /*
    bundle // ?
    config // ? bundle.config
  */

  // Standard System Services
  let _channels_service: (Channel[ChannelsEvent] val | None) = None
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
    // _channels = ChannelsService(this)
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

  fun tag channels(): Promise[Channel[ChannelsEvent] val] =>
     let promise = Promise[Channel[ChannelsEvent] val]
     _try_fulfill_channels(promise)
     promise

  be _try_fulfill_channels(promise: Promise[Channel[ChannelsEvent] val]) =>
    match _channels_service
    | let c: Channel[ChannelsEvent] val => promise(c)
    | None => promise.reject()
    end

  be _receive_channels_service(channels_service': Channel[ChannelsEvent] val) =>
    _channels_service = channels_service'

  // fun clock(): Clock
  // fun debugger(): Debugger
  // fun io(): Io
  // fun log(): Log
  // fun names(): Names
  // fun net(): Net
  // fun remote(): Remote

  // fun spawn()

  fun shutdown() =>
    """ Shut down this reactor system and all its services. """
    _shut_down_services()

  fun _shut_down_services() =>
    let services = [
      channels()
    ]
    for service in services.values() do
      service.shutdown()
    end

/*
class ReactorSystemProxy[T: Any #send] //is Services
  let reactor: Reactor[T]
  let system: ReactorSystem tag

  let _channels: Channel[ChannelsEvent]

  new create(reactor': Reactor[T], system': ReactorSystem tag) =>
    reactor = reactor'
    system = system'
*/