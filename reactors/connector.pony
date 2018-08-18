
class Connector[T]
  """"""
  let _reactor_state: ReactorState
  let _is_sealed: Bool = false
  let channel: Channel[T] val
  var reservation: (ChannelReservation val | None)
  let events: Events[T] ref

  // TODO: Connector.create - Provide default events?
  new create(
    channel': Channel[T] val,
    events': Events[T],
    reactor_state': ReactorState,
    reservation': (ChannelReservation val | None) = None)
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

      // If this connector's channel was registerd..
      if not (reservation is None) then
        // ..ask the channels service to forget it.
        _reactor_state.channels_service << ChannelRegister(reservation, None)
      end
    end
