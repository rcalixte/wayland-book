# Binding to globals

Upon binding to the registry, server will emit the `global` event for each
global available on the server. You can then bind to the globals you require.

This process of taking a known object and assigning it an ID is called
*binding* the object. Once the client binds to the registry like this, the
server emits the `global` event several times to advertise which interfaces it
supports. Each of these globals is assigned a unique `name`, as an unsigned
integer. The `interface` string maps to the name of the interface found in the
protocol: `wl_display` from the XML above is an example of such a name. The
version number is also defined here - for more information about interface
versioning, see appendix C.

To bind to any of these interfaces, we use the bind request, which works
similarly to the magical process by which we bound to the `wl_registry`. For
example, consider this wire protocol exchange:

```
C->S    00000001 000C0001 00000002            .... .... ....

S->C    00000002 001C0001 00000001 00000007   .... .... .... ....
        776C5f73 686d0000 00000001            wl_s hm.. ....
        [...]

C->S    00000002 00100000 00000001 00000003   .... .... .... ....
```

The first message is identical to the one we've already dissected. The second
one is an event from the server: object 2 (which the client assigned the
`wl_registry` to in the first message) opcode 0 ("global"), with arguments 1,
"wl_shm", and 1 - respectively the name, interface, and version of this global.
The client responds by calling opcode 0 on object ID 2 (`wl_registry::bind`) and
assigns object ID `3` to global name `1` - *binding* to the `wl_shm` global.
Future events and requests for this object are defined by the `wl_shm` protocol,
which you can find in `wayland.xml`.

Once you've created this object, you can utilize its interface to accomplish
various tasks - in the case of `wl_shm`, managing shared memory between the
client and server. Most of the remainder of this book is devoted to explaining
the usage of each of these globals.

Armed with this information, we can write our first useful Wayland client: one
which simply prints all of the globals available on the server.

```c
#include <stdint.h>
#include <stdio.h>
#include <wayland-client.h>

static void
registry_handle_global(void *data, struct wl_registry *registry,
		uint32_t name, const char *interface, uint32_t version)
{
	printf("interface: '%s', version: %d, name: %d\n",
			interface, version, name);
}

static void
registry_handle_global_remove(void *data, struct wl_registry *registry,
		uint32_t name)
{
	// This space deliberately left blank
}

static const struct wl_registry_listener
registry_listener = {
	.global = registry_handle_global,
	.global_remove = registry_handle_global_remove,
};

int
main(int argc, char *argv[])
{
	struct wl_display *display = wl_display_connect(NULL);
	struct wl_registry *registry = wl_display_get_registry(display);
	wl_registry_add_listener(registry, &registry_listener, NULL);
	wl_display_roundtrip(display);
	return 0;
}
```

Feel free to reference previous chapters to interpret this program. We connect
to the display (chapter 4.1), obtain the registry (this chapter), add a listener
to it (chapter 3.4), then round-trip, handling the global event by printing the
globals available on this compositor. Try it for yourself:

```c
$ cc -o globals -lwayland-client globals.c
```

**Note**: this chapter the last time we're going to show wire protocol dumps in
hexadecimal, and probably the last time you'll ever see them in general. A
better way to trace your Wayland client or server is to set the
`WAYLAND_DEBUG` variable in your environment to `1` before running your program.
Try it now with the "globals" program!
