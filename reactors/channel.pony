
trait val Channel[E: Any #send]
  """
  Channels are the conduit of inter-reactor event propogation, and introduce
  communication paths into a reactor.

  An event may be propogated through a channel by calling the `<<` infix
  operator between the channel and event. The event is eventually emitted on
  the channel's corresponding event stream inside the channel's owning reactor.
  """
    fun shl(event: E)
      """ Send a single event on this channel. """
