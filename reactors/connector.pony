
interface ConnectorKind

/*
May need to split this out to
  - IsolateConnector[C: Any iso, E: Any ref]
  - Connector[T: (Any val | Any tag)] // #share

Then have counterpart Reactor types
  - IsolateReactor[C: Any iso, E: Any ref]
  - Reactor[T: (Any val | Any tag)] // #share
  - IsolateReactorState[C: Any iso, E: Any ref]
  - ReactorState[T: (Any val | Any tag)] // #share

Then have counterpart calls to open
  - open_isolate[C: Any iso, E: Any ref]
  - open[T: (Any val | Any tag)] // #share

ETC...

So plan: Move the current generic typing from #send to #share to cover the `val` and `tag` case. Then add Isolate* types to account for reactors, channels, etc operating on events that are `iso` in nature. Additionally, add a `iso` to `ref` translation fun that can be overridden for when Isolated* C and E types are not the same underlying (may not be worth it)?
*/

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
