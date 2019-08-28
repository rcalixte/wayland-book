# Application windows

We have shaved many yaks to get here, but it's time: XDG toplevel is the
interface which we will finally use to display an application window. Once we
use the `get_xdg_surface` request from `xdg_wm_base` to obtain one, our surface
will be shown as a top-level application window, and we have at our disposal a
number of requests for things such as:

- Setting our window title
- Starting an interactive move or resize of the window
- Tracking states like maximized, minimized, focused, etc

And beyond the basics, many more exist still. I want to focus now on one event
in particular, however: `configure`.

```xml
<interface name="xdg_toplevel" version="2">
  <!-- ... -->
  <event name="configure">
    <arg name="width" type="int"/>
    <arg name="height" type="int"/>
    <arg name="states" type="array"/>
  </event>
  <!-- ... -->
</interface>
```

In Wayland, clients are the authority over the size of their windows[^1], but
the configure event provides the server with a means of requesting that the
client assume some specific dimensions. This mechanism plays into the lifecycle
we mentioned in the previous chapter, and in concert they provide a means of
atomically agreeing upon the state of your window. In summary, the flow for
creating and presenting an xdg toplevel atomically, such that the very first
frame is correct and consistent, looks something like the following:

1. The client binds to `wl_compositor` and uses it to create a `wl_surface`.
2. The client binds to `xdg_wm_base` and uses it to create an `xdg_surface`,
   using the `wl_surface` it created in step 1.
3. The client creates an `xdg_toplevel` from the `xdg_surface`.
4. The client configures some initial states for the `xdg_toplevel`, such as the
   window title, and uses `wl_surface.commit` on the associated surface to
   indicate that it is done.
5. The compositor makes its own preparations, and decides where it would like to
   present the new window. It allocates it a size and sends an
   `xdg_toplevel.configure` event, also including any preference on initial
   maximized or fullscreen states, etc. It sends an `xdg_surface.configure`
   event with a serial representing this known state of affairs. If the
   compositor prefers the client to pick a size, it'll send &lt;0,0&gt;.
6. Armed with this information, the client allocates a buffer at the requested
   dimensions and renders a frame into it.
7. It shares this buffer with the compositor through whatever method is most
   appropriate (e.g. `wl_shm`), and uses `wl_surface.attach` to attach the
   `wl_buffer` to the `wl_surface`.
8. The client uses the `xdg_toplevel.ack_configure` request, using the serial
   from before, to indicate that it has configured the surface in accordance
   with the terms agreed to for that serial. Then it uses `wl_surface.commit` to
   commit all of this new state to the record.

Through this process, the compositor and client negotiated their wishes for the
new window, prepared a buffer based on those terms, and the compositor can now
present the window. A complex dance for sure, but I hope that you're now
equipped with an understanding of each step and an appreciation for the design
that went into it.

Using the sum of what we've learned so far, we can now write a Wayland client
which displays something on the screen. Here is a complete Wayland client which
opens an XDG toplevel and displays a grid of squares on it:

```
#define _POSIX_C_SOURCE 200112L
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdbool.h>
#include <string.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>
#include <wayland-client.h>
#include "xdg-shell-client-protocol.h"

/* Shared memory support code */
static void
randname(char *buf)
{
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    long r = ts.tv_nsec;
    for (int i = 0; i < 6; ++i) {
        buf[i] = 'A'+(r&15)+(r&16)*2;
        r >>= 5;
    }
}

static int
create_shm_file(void)
{
    int retries = 100;
    do {
        char name[] = "/wl_shm-XXXXXX";
        randname(name + sizeof(name) - 7);
        --retries;
        int fd = shm_open(name, O_RDWR | O_CREAT | O_EXCL, 0600);
        if (fd >= 0) {
            shm_unlink(name);
            return fd;
        }
    } while (retries > 0 && errno == EEXIST);
    return -1;
}

static int
allocate_shm_file(size_t size)
{
    int fd = create_shm_file();
    if (fd < 0)
        return -1;
    int ret;
    do {
        ret = ftruncate(fd, size);
    } while (ret < 0 && errno == EINTR);
    if (ret < 0) {
        close(fd);
        return -1;
    }
    return fd;
}

/* Wayland code */
struct client_state {
    /* Globals */
    struct wl_display *wl_display;
    struct wl_registry *wl_registry;
    struct wl_shm *wl_shm;
    struct wl_compositor *wl_compositor;
    struct xdg_wm_base *xdg_wm_base;
    /* Objects */
    struct wl_surface *wl_surface;
    struct xdg_surface *xdg_surface;
    struct xdg_toplevel *xdg_toplevel;
    /* State */
    bool closed;
    int width, height;
};

static void wl_buffer_release(void *data, struct wl_buffer *wl_buffer) {
    wl_buffer_destroy(wl_buffer);
}

static const struct wl_buffer_listener wl_buffer_listener = {
    .release = wl_buffer_release,
};

static struct wl_buffer *
draw_frame(struct client_state *state)
{
    int stride = state->width * 4;
    int size = stride * state->height;

    int fd = allocate_shm_file(size);
    if (fd == -1) {
        return NULL;
    }

    uint32_t *data = mmap(NULL, size,
            PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (data == MAP_FAILED) {
        close(fd);
        return NULL;
    }

    struct wl_shm_pool *pool = wl_shm_create_pool(state->wl_shm, fd, size);
    struct wl_buffer *buffer = wl_shm_pool_create_buffer(pool, 0,
            state->width, state->height, stride, WL_SHM_FORMAT_XRGB8888);
    wl_shm_pool_destroy(pool);

    /* Draw checkerboxed background */
    for (int y = 0; y < state->height; ++y) {
        for (int x = 0; x < state->width; ++x) {
            if ((x + y / 8 * 8) % 16 < 8)
                data[y * state->width + x] = 0xFF666666;
            else
                data[y * state->width + x] = 0xFFEEEEEE;
        }
    }

    wl_buffer_add_listener(buffer, &wl_buffer_listener, NULL);
    return buffer;
}

static void
xdg_toplevel_configure(void *data, struct xdg_toplevel *xdg_toplevel,
        int32_t width, int32_t height, struct wl_array *states)
{
    if (width == 0 || height == 0) {
        width = 640, height = 480;
    }
    struct client_state *state = data;
    state->width = width;
    state->height = height;
}

static void
xdg_toplevel_close(void *data, struct xdg_toplevel *xdg_toplevel)
{
    struct client_state *state = data;
    state->closed = true;
}

const static struct xdg_toplevel_listener xdg_toplevel_listener = {
    .configure = xdg_toplevel_configure,
    .close = xdg_toplevel_close,
};

static void
xdg_surface_configure(void *data,
        struct xdg_surface *xdg_surface, uint32_t serial)
{
    /* Acknowledge and commit a frame for this configure event */
    struct client_state *state = data;
    xdg_surface_ack_configure(xdg_surface, serial);

    struct wl_buffer *buffer = draw_frame(state);
    wl_surface_attach(state->wl_surface, buffer, 0, 0);
    wl_surface_damage_buffer(state->wl_surface, 0, 0, INT32_MAX, INT32_MAX);
    wl_surface_commit(state->wl_surface);
}

const static struct xdg_surface_listener xdg_surface_listener = {
    .configure = xdg_surface_configure,
};

static void
xdg_wm_base_ping(void *data, struct xdg_wm_base *xdg_wm_base, uint32_t serial)
{
    xdg_wm_base_pong(xdg_wm_base, serial);
}

const static struct xdg_wm_base_listener xdg_wm_base_listener = {
    .ping = xdg_wm_base_ping,
};

static void
registry_global(void *data, struct wl_registry *wl_registry,
        uint32_t name, const char *interface, uint32_t version)
{
    /* Bind to globals */
    struct client_state *state = data;
    if (strcmp(interface, wl_shm_interface.name) == 0) {
        state->wl_shm = wl_registry_bind(
                wl_registry, name, &wl_shm_interface, 1);
    } else if (strcmp(interface, wl_compositor_interface.name) == 0) {
        state->wl_compositor = wl_registry_bind(
                wl_registry, name, &wl_compositor_interface, 4);
    } else if (strcmp(interface, xdg_wm_base_interface.name) == 0) {
        state->xdg_wm_base = wl_registry_bind(
                wl_registry, name, &xdg_wm_base_interface, 1);
        xdg_wm_base_add_listener(state->xdg_wm_base,
                &xdg_wm_base_listener, state);
    }
}

static void
registry_global_remove(void *data,
        struct wl_registry *wl_registry, uint32_t name)
{
    /* This space deliberately left blank */
}

const static struct wl_registry_listener wl_registry_listener = {
    .global = registry_global,
    .global_remove = registry_global_remove,
};

int
main(int argc, char *argv[])
{
    /* Connect to the display */
    struct client_state state = { 0 };
    state.wl_display = wl_display_connect(NULL);
    state.wl_registry = wl_display_get_registry(state.wl_display);
    wl_registry_add_listener(state.wl_registry, &wl_registry_listener, &state);
    wl_display_roundtrip(state.wl_display);

    /* Allocate our surface */
    state.wl_surface = wl_compositor_create_surface(state.wl_compositor);
    state.xdg_surface = xdg_wm_base_get_xdg_surface(
            state.xdg_wm_base, state.wl_surface);
    xdg_surface_add_listener(state.xdg_surface, &xdg_surface_listener, &state);
    state.xdg_toplevel = xdg_surface_get_toplevel(state.xdg_surface);
    xdg_toplevel_add_listener(state.xdg_toplevel,
            &xdg_toplevel_listener, &state);
    xdg_toplevel_set_title(state.xdg_toplevel, "Example client");
    wl_surface_commit(state.wl_surface);

    /* Main loop */
    while (wl_display_dispatch(state.wl_display) && !state.closed) {
        /* This space deliberately left blank */
    }

    return 0;
}
```

Compile this like so:

```
wayland-scanner private-code \
  < /usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml \
  > xdg-shell-protocol.c
wayland-scanner client-header \
  < /usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml \
  > xdg-shell-client-protocol.h
cc -o client client.c xdg-shell-protocol.c -lwayland-client
```

Then run `./client` to see it in action, or `WAYLAND_DEBUG=1 ./client` to
include a bunch of useful debugging information. Tada! In future chapters we
will be building upon this client, so stow this code away somewhere safe.
