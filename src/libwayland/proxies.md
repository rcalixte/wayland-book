# Proxies & resources

An *object* is an entity which known to both the client and server that has some
state, changes to which are negotiated over the wire. On the client side,
libwayland refers to these objects through the `wl_proxy` interface. These are a
concrete C-friendly "proxy" for the abstract object, and provides functions
which are indirectly used by the client to marshall requests into the wire
format. If you review the `wayland-client-core.h` file, you'll find a few
low-level functions for this purpose. Generally, you don't use these directly.

On the server, objects are abstracted through `wl_resource`, which is fairly
similar, but have an extra degree of complexity - the server has to track which
object belongs to which client. Each `wl_resource` is owned by a single client.
Aside from this, the interface is much the same, and provides low-level
abstraction for marshalling events to send to the associated client. You will
use `wl_resource` directly on a server more often than you'll use directly
interface with `wl_proxy` on a client. One example of such a use is to obtain a
reference to the `wl_client` which owns a resource that you're manipulating
out-of-context, or send a protocol error when the client attempts an invalid
operation.

Another level up is another set of higher-level interfaces, which most Wayland
client & server code interacts with to accomplish a majority of their tasks.
