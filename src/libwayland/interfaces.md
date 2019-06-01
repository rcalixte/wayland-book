# Interfaces & listeners

Finally, we reach the summit of libwayland's abstractions: interfaces and
listeners. The ideas discussed in previous chapters - `wl_proxy` and
`wl_resource`, and the primitives - are singular implementations which live in
libwayland, and they exist to provide support to this layer. When you run an XML
file through wayland-scanner, it generates *interfaces* and *listeners*, as well
as glue code between them and the low-level wire protocol interfaces, all
specific to each interface in the high-level protocols.

Recall that each actor on a Wayland connection can both receive and send
messages. A client is listening for events and sending requests, and a server
listens for requests and sends events. Each side listens for the messages of the
other using an aptly-named `wl_listener`. Here's an example of this interface:

```c
struct wl_surface_listener {
	/** surface enters an output */
	void (*enter)(void *data,
		      struct wl_surface *wl_surface,
		      struct wl_output *output);

	/** surface leaves an output */
	void (*leave)(void *data,
		      struct wl_surface *wl_surface,
		      struct wl_output *output);
};
```

This is a client-side listener for a `wl_surface`. The XML that wayland-scanner
uses to generate this is:

```xml
<interface name="wl_surface" version="4">
  <event name="enter">
    <arg name="output"
      type="object"
      interface="wl_output"/>
  </event>

  <event name="leave">
    <arg name="output"
      type="object"
      interface="wl_output"/>
  </event>
  <!-- additional details omitted for brevity -->
</interface>
```

It should be fairly clear how these events become a listener interface. Each
function pointer takes some arbitrary user data, a reference to the resource
which the event pertains to, and the arguments to that event. We can bind a
listener to a `wl_surface` like so:

```c
static void wl_surface_enter(void *data,
        struct wl_surface *wl_surface, struct wl_output *output) {
    // ...
}

static void wl_surface_leave(void *data,
        struct wl_surface *wl_surface, struct wl_output *output) {
    // ...
}

static const struct wl_surface_listener surface_listener = {
    .enter = wl_surface_enter,
    .leave = wl_surface_leave,
};

// ...cotd...

struct wl_surface *surf;
wl_surface_add_listener(surf, &surface_listener, NULL);
```

The `wl_surface` interface also defines some requests that the client can make
for that surface:

```xml
<interface name="wl_surface" version="4">
  <request name="attach">
    <arg name="buffer"
      type="object"
      interface="wl_buffer"
      allow-null="true"/>
    <arg name="x" type="int"/>
    <arg name="y" type="int"/>
  </request>
  <!-- additional details omitted for brevity -->
</interface>
```

wayland-scanner generates the following prototype, as well as glue code which
marshalls this message.

```c
void wl_surface_attach(struct wl_surface *wl_surface,
    struct wl_buffer *buffer, int32_t x, int32_t y);
```

The server-side code for interfaces and listeners is identical, but reversed -
it generates listeners for requests and glue code for events. When libwayland
receives a message, it looks up the object ID, and its interface, then uses that
to decode the rest of the message. Then it looks for listeners on this object
and invokes your functions with the arguments to the message.

That's all there is to it! It took us a couple of layers of abstraction to get
here, but you should now understand how an event starts in your server code,
becomes a message on the wire, is understood by the client, and dispatched to
your client code. There remains one unanswered question, however. All of this
presupposes that you already have references to Wayland objects. How do you get
those?
