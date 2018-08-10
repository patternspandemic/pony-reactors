
trait Protocol
  """ Encapsulation of a set of event streams and channels. """
  fun system(): ReactorSystem tag

trait tag Service is Protocol
  """ A Protocol that can be shut down. """
  be shutdown()

trait val ServiceBuilder
  fun apply(system: ReactorSystem tag): Service



primitive ChannelsService is ServiceBuilder
  fun apply(system: ReactorSystem tag): Channels =>
    Channels(system)

actor Channels is Service
  let _system: ReactorSystem tag

  new create(system': ReactorSystem tag) =>
    _system = system'
  
  fun system(): ReactorSystem tag => _system
  be shutdown() => None // TODO: Channels.shutdown()


/*

// Services:
Channels
Clock
Debugger
Io
Log
Names
Net
Remote

*/
