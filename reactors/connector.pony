
class Connector[T]
  """"""
  let _is_sealed: Bool = false
  let channel: Channel[T] val
  var reservation: (ChannelReservation val | None)
  let events: Events[T] ref

  // TODO: Connector.create - Provide default events?
  new create(
    channel': Channel[T] val,
    events': Events[T],
    reservation': (ChannelReservation val | None) = None)
  =>
    channel = channel'
    events = events'
    reservation = reservation'

  fun ref seal() =>
    if not _is_sealed then
      events.unreact()
      _is_sealed = true
    end
