
class Connector[T]
  """"""
  let channel: Channel[T] val
  let events: Events[T] ref

  new create(
    channel': Channel[T] val,
    events': Events[T]) // TODO: Connector.create - Provide default events?
  =>
    channel = channel'
    events = events'
