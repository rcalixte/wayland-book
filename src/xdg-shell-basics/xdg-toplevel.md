# Application windows

We have shaved many yaks to get here, but it's time: XDG toplevel is the
interface which we will finally use to display an application window. Once we've
turned our `wl_surface` into an `xdg_surface` using
`xdg_wm_base.get_xdg_surface`, we can use `xdg_surface.get_toplevel` to obtain
an `xdg_toplevel`. Once we do, we have created an application window and we have
at our disposal a number of requests for its configuration, such as:

- Setting our window title
- Starting an interactive move or resize of the window
- Tracking states like maximized, minimized, focused, etc

We'll speak about each of these in detail later. For now, the following steps
are sufficient to present an application window:

1. Bind to `wl_compositor` and use it to create a `wl_surface`.
1. Bind to `xdg_wm_base` and use it to create an `xdg_surface`,
   using the `wl_surface` it created in step 1.
1. Create an `xdg_toplevel` from the `xdg_surface` with
   `xdg_surface.get_toplevel`.
1. Configure a listener for the `xdg_surface` and await the `configure` event.
1. Bind to the buffer allocation mechanism of your choosing (such as `wl_shm`)
   and allocate a shared buffer, then render your content to it.
1. Use `wl_surface.attach` to attach the `wl_buffer` to the `wl_surface`.
1. Use `xdg_surface.ack_configure`, passing it the serial from `configure`,
   acknowledging that you have prepared a suitable frame.
1. Send a `wl_surface.commit` request.

Using the sum of what we've learned so far, we can now write a Wayland client
which displays something on the screen. Here is a complete Wayland client which
opens an XDG toplevel and displays a 640x480 grid of squares on it:

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
	const int width = 640, height = 480;
	int stride = width * 4;
	int size = stride * height;

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
			width, height, stride, WL_SHM_FORMAT_XRGB8888);
	wl_shm_pool_destroy(pool);

	/* Draw checkerboxed background */
	for (int y = 0; y < height; ++y) {
		for (int x = 0; x < width; ++x) {
			if ((x + y / 8 * 8) % 16 < 8)
				data[y * width + x] = 0xFF666666;
			else
				data[y * width + x] = 0xFFEEEEEE;
		}
	}

	wl_buffer_add_listener(buffer, &wl_buffer_listener, NULL);
	return buffer;
}

static void
xdg_surface_configure(void *data,
		struct xdg_surface *xdg_surface, uint32_t serial)
{
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
	struct client_state state = { 0 };
	state.wl_display = wl_display_connect(NULL);
	state.wl_registry = wl_display_get_registry(state.wl_display);
	wl_registry_add_listener(state.wl_registry, &wl_registry_listener, &state);
	wl_display_roundtrip(state.wl_display);

	state.wl_surface = wl_compositor_create_surface(state.wl_compositor);
	state.xdg_surface = xdg_wm_base_get_xdg_surface(
			state.xdg_wm_base, state.wl_surface);
	xdg_surface_add_listener(state.xdg_surface, &xdg_surface_listener, &state);
	state.xdg_toplevel = xdg_surface_get_toplevel(state.xdg_surface);
	xdg_toplevel_set_title(state.xdg_toplevel, "Example client");
	wl_surface_commit(state.wl_surface);

	while (wl_display_dispatch(state.wl_display)) {
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
