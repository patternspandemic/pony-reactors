
class tag ChannelTag
  """ A unique identifier for a channel. """


interface val ChannelKind


trait val Channel[E: Any #share] is ChannelKind
  """
  Channels are the conduit of inter-reactor event propogation, and introduce
  communication paths into a reactor.

  An event may be propogated through a channel by calling the `<<` infix
  operator between the channel and event. The event is eventually emitted on
  the channel's corresponding event stream inside the channel's owning reactor.
  """
    fun channel_tag(): ChannelTag tag
      """ Retrieve the unique identifier for this channel. """

    fun shl(event: E)
      """ Send a single event on this channel. """


primitive BuildChannel
  fun dummy[T: Any #share](): Channel[T] =>
    """ Builds a dummy channel that doesn't forward events. """
    object val is Channel[T]
      let _channel_tag: ChannelTag = ChannelTag
      fun channel_tag(): ChannelTag => _channel_tag
      // TODO: BuildChannel.dummy - Log error/warning when sent event.
      fun shl(event: T) => None
    end

//////// REFERENCE CODE \\\\\\\\\
/*
type Req[T: Any #share, S: Any #share] is (T, Channel[S])
type Server[T: Any #share, S: Any #share] is Channel[Req[T, S]]
*/
