# Globals & the registry

If you'll recall from chapter 2.1, each request and event is associated with an
object ID, but thus far we haven't discussed how objects are created. When we
receive a Wayland message, we must know what interface the object ID represents
to decode it. We must also somehow negotiate available objects, the creation of
new ones, and the assigning of IDs to them, in some manner. On Wayland we solve
both of these problems at once - when we *bind* an object ID, we agree on the
interface used for it in all future messages, and stash a mapping of object IDs
to interfaces in our local state.

In order to bootstrap these, the server offers a list of *global* objects. These
globals often provide information and functionality on their own merits, but
most often they're used to broker additional objects to fulfill various
purposes - such as the creation of application windows. These globals themselves
also have their own object IDs and interfaces, which we have to assign and agree
upon somehow.

With questions of hens and eggs no doubt coming to mind by now, I'll reveal the
secret trick: object ID 1 is already implicitly assigned to the `wl_display`
interface when you make the connection. As you'll recall the interface, take
note of the `wl_display::get_registry` request:

```xml
<interface name="wl_display" version="1">
  <request name="sync">
    <arg name="callback" type="new_id" interface="wl_callback" />
  </request>

  <request name="get_registry">
    <arg name="registry" type="new_id" interface="wl_registry" />
  </request>

  <!-- cotd -->
</interface>
```

The `wl_display::get_registry` request can be used to bind an object ID to the
`wl_registry` interface, which is the next one found in `wayland.xml`. Given
that the `wl_display` always has object ID 1, the following wire message ought
to make sense (in big-endian):

```
C->S    00000001 000C0001 00000002            .... .... ....
```

When we break this down, the first number is the object ID. The most significant
16 bits of the second number are the total length of the message in bytes, and
the least significant bits are the request opcode. The remaining words (just
one) are the arguments. In short, this calls request 1 (0-indexed) on object ID
1 (the `wl_display`), which accepts one argument: a generated ID for a new
object. Note in the XML documentation that this new ID is defined ahead of time
to be governed by the `wl_registry` interface:

```xml
<interface name="wl_registry" version="1">
  <request name="bind">
    <arg name="name" type="uint" />
    <arg name="id" type="new_id" />
  </request>

  <event name="global">
    <arg name="name" type="uint" />
    <arg name="interface" type="string" />
    <arg name="version" type="uint" />
  </event>

  <event name="global_remove">
    <arg name="name" type="uint" />
  </event>
</interface>
```

It is this interface which we'll discuss in the following chapters.
