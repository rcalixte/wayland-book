# Using wl_compositor

They say naming things is one of the most difficult problems in computer
science, and here we are, with evidence in hand. The `wl_compositor` global is
the Wayland compositor's, er, compositor. Through this interface, you may
send the server your windows for presentation, to be *composited* with the
other windows being shown alongside it. The compositor has two jobs: the
creation of surfaces and regions.

To quote the spec, a Wayland *surface* has a rectangular area which may be
displayed on zero or more outputs, present buffers, receive user input, and
define a local coordinate system. We'll take all of these apart in detail later,
but let's start with the basics: obtaining a surface and attaching a buffer to
it. To obtain a surface, we first bind to the `wl_compositor` global. By
extending the example from chapter 5.1 we get the following:

```
struct our_state {
    // ...
    struct wl_compositor *compositor;
    // ...
};

static void
registry_handle_global(void *data, struct wl_registry *registry,
		uint32_t name, const char *interface, uint32_t version)
{
    struct our_state *state = data;
    if (strcmp(interface, wl_compositor_interface.name) == 0) {
        state->compositor = wl_registry_bind(
            wl_registry, name, &wl_compositor_interface, 4);
    }
}

int
main(int argc, char *argv[])
{
    struct our_state state = { 0 };
    // ...
    wl_registry_add_listener(registry, &registry_listener, &state);
    // ...
}
```

Note that we've specified version 4 when calling `wl_registry_bind`, which is
the latest version at the time of writing. With this reference secured, we can
create a `wl_surface`:

```
struct wl_surface *surface = wl_compositor_create_surface(state.compositor);
```

Before we can present it, we must first attach a source of pixels to it: a
`wl_buffer`.
