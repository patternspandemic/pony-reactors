# pony-reactors

[Draft]

This is an experimental framework implementing _Reactors_ atop the Pony language.

A Reactors framework improves upon the strengths of the actor model. It simplifies message protocol composition and reuse, while preserving important properties for building reliable distributed systems such as serialized message processing and location-transparency. Three abstractions form the basis of a Reactors framework:

* **Reactors** are location-transparent, lightweight entities that execute concurrently with each other, but are internally always single-threaded, and can be ported from a single machine to a distributed setting.
* **Channels** that can be shared between reactors, and are used to asynchronously send events.
* Asynchronous first-class **event streams** that can be reasoned about in a declarative, functional manner, and are the basis for composing components.

With respect to the actor model, a **reactor** is comparable to an _actor_, a **channel** is somewhat comparable to an _actor reference_, and **event-streams** correspond to a composable _observer pattern_.

While these abstractions form an integration of traditional actor model and functional reactive programming concepts, such frameworks have _not_ been built atop existing actor model frameworks or languages. Limitations of basic actor model implementations which prevent this include:

* Lack of multiple message entry points. Separate protocols handled within an actor must be encoded in a single message-handling construct, and thus need to be aware of each other. Multiple message entry points are required for message protocol isolation.
* Inability to await specific combinations of messages. A `receive` block cannot suspend until some multitude of message types arrive. This is often skirted in basic actor implementations by storing and testing for message states, or through the use of futures/promises, but obviously increases complexity. A requirement for the expression of multi-party message protocols.
* An actor's `receive` is a static construct and not first class. It cannot be passed to and returned from function, a requirement for message protocol composition.

It is surmised here, that Pony's specific implementation of the actor model allows for a Reactors framework to be built atop it, thereby providing an approach to overcome the difficulties of reuse and protocol composition, and paving the way to build a protocol stack of reusable distributed computing components in Pony.

Pony absolves itself from the above limitations in the following way:

* Pony includes multiple message entry points in its implementation by way of actor behaviors. Generic behaviors may then form the basis needed for protocol isolation.
* While Pony cannot await specific combinations of messages sent to behaviors, it is further surmised that, just like a Reactor, a Pony actor can use internal event stream composition to essentially await any combination of messages, and avoid the need for a dedicated multi-receive construct.
* Message receives by way of behaviors can be made first class through partial application, fulfilling the requirement for protocol composition.

The _pony-reactors_ framework is inspired and informed by:

* **Reactors, Channels, and Event Streams for Composable Distributed Programming**\
  Aleksandar Prokopec, Martin Odersky\
  October 2015 [PDF](http://aleksandar-prokopec.com/resources/docs/reactors.pdf)
* **Containers and Aggregates, Mutators and Isolates for Reactive Programming**\
  Aleksandar Prokopec, Philipp Haller, Martin Odersky\
  July 2014 [PDF](http://aleksandar-prokopec.com/resources/docs/reactives-and-isolates.pdf)
* **[Reactors.IO](http://reactors.io)**\
  An event-based framework for distributed programming based on event streams, channels and reactors. Provides multiple language frontends.\
  [Source Code](https://github.com/reactors-io/reactors/)

## Status

[![CircleCI](https://circleci.com/gh/patternspandemic/pony-reactors.svg?style=svg)](https://circleci.com/gh/patternspandemic/pony-reactors)

Development of pony-reactors has only just begun.

## Installation

* Install [pony-stable](https://github.com/ponylang/pony-stable)
* Update your `bundle.json`

```json
{ 
  "type": "github",
  "repo": "patternspandemic/pony-reactors"
}
```

* `stable fetch` to fetch your dependencies
* `use "reactors"` to include this package
* `stable env ponyc` to compile your application
