# Interfaces, requests, and events

The Wayland protocol works by issuing *requests* and *events* that act on
*objects*. Each object has an *interface* which defines what requests and events
are possible, and the *signature* of each. Let's consider an example interface:
`wl_surface`.

## Requests

A surface is a box of pixels that can be displayed on-screen. It's one of the
primitives we build things like application windows out of. One of its
*requests* is "damage", which the client uses to indicate that some part of the
surface has changed and needs to be redrawn. Here's an annotated example of a
"damage" message on the wire (in hexadecimal):

    0000000A    Object ID (10)
    00180002    Message length (24) and request opcode (2)
    00000000    X coordinate (int): 0
    00000000    Y coordinate (int): 0
    00000100    Width        (int): 256
    00000100    Height       (int): 256

This is a snippet of a session - the surface was allocated earlier and assigned
an ID of 10. When the server receives this message, it looks up the object with
ID 10 and knows it's a `wl_surface` instance (and where to find its own state
for that object). Knowing it's a `wl_surface`, it looks up the request with
opcode 2: damage. Based on this it knows to expect four integers as the
arguments, and it can decode the message and dispatch it for processing
internally.

## Events

This kind of message is sent from the client to the server. The server can also
send messages back - events. One event that the server can send regarding a
`wl_surface` is "enter", which it sends when that surface is being displayed on
a specific output (the client might respond to this, for example, by adjusting
its scale factor for a HiDPI display). Here's an example of such a request:

    0000000A    Object ID (10)
    000B0000    Message length (12) and request opcode (0)
    00000005    Output (object ID): 5

This message references another object, by its ID: the `wl_output` object which
the surface is being shown on. The client receives this and dances to a similar
tune as the server did. It looks up object 10, associates it with the
`wl_surface` interface, and looks up the signature of opcode 0. It decodes the
rest of the message accordingly (looking up the `wl_output` with ID 5 as well),
then dispatches it for processing internally.

## Interfaces

The interfaces which define the list of requests and events, the opcodes
associated with each, and the signatures with which you can decode the messages
is agreed upon in advance. I'm sure you're dying to know how - simply turn the
page to end the suspense.
