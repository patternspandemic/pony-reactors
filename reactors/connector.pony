
interface ConnectorKind

class Connector[T: Any #send] is ConnectorKind
  """"""
  let _reactor_state: ReactorState[(Any iso | Any val | Any tag)]
  var _is_sealed: Bool = false
  let channel: Channel[T] val
  var reservation: (ChannelReservation | None)
  let events: Emitter[T] //Events[T] ref

  // TODO: Connector.create - Provide default events?
  new create(
    channel': Channel[T] val,
    events': Emitter[T], //Events[T]
    reactor_state': ReactorState[(Any iso | Any val | Any tag)],
    reservation': (ChannelReservation | None) = None)
  =>
    channel = channel'
    events = events'
    _reactor_state = reactor_state'
    reservation = reservation'

  fun ref seal() =>
    if not _is_sealed then
      // Mark connector as sealed, and unreact its event stream.
      _is_sealed = true
      events.unreact()

      // Remove the connector from the owning reactor's collection.
      try _reactor_state.connectors.remove(channel.channel_tag())? end

      // If channel was registerd ask channels service to forget it.
      match reservation
      | let cr: ChannelReservation =>
        _reactor_state.channels_service << ChannelRegister(cr, None)
      end
    end
