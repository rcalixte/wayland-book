# Shared memory buffers

The simplest means of getting pixels from client to compositor, and the only one
enshrined in `wayland.xml`, is `wl_shm` - shared memory. Simply put, it allows
you to transfer a file descriptor for the compositor to mmap with `MAP_SHARED`,
then share pixel buffers out of this pool. Add some simple syncronization
primitives to keep everyone from fighting over each buffer, and you have a
workable - and portable - solution.

## Binding to wl_shm

The registry global listener explained in chapter 5.1 will advertise the
`wl_shm` global when it's available. Binding to it is fairly straightforward.
Extending the example given in chapter 5.1, we get the following:

```c
struct our_state {
    struct wl_shm *shm;
    // ...
};

static void
registry_handle_global(void *data, struct wl_registry *registry,
		uint32_t name, const char *interface, uint32_t version)
{
    struct our_state *state = data;
    if (strcmp(interface, wl_shm_interface.name) == 0) {
        state->shm = wl_registry_bind(
            wl_registry, name, &wl_shm_interface, 1);
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

Once bound, we can optionally add a listener via `wl_shm_add_listener`. The
compositor will advertise its supported pixel formats via this listener. The
full list of possible pixel formats is given in `wayland.xml`. Two formats are
required to be supported: `ARGB8888`, and `XRGB8888`, which are 24-bit color,
with and without an alpha channel respectively.

## Allocating a shared memory pool

A combination of POSIX `shm_open` and random file names can be utilized to
create a file suitable for this purpose, and `ftruncate` can be utilized to
bring it up to the appropriate size. The following boilerplate may be freely
used under public domain or CC0:

```c
#define _POSIX_C_SOURCE 200112L
#include <errno.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>

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

int
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
```

Hopefully the code is fairly self-explanatory (famous last words). Armed with
this, the client can create a shared memory pool fairly easily. Let's say, for
example, that we want to show a 1920x1080 window. We'll need two buffers for
double-buffering, so that'll be 4,147,200 pixels. Assuming the pixel format is
`WL_SHM_FORMAT_XRGB8888`, that'll be 4 bytes to the pixel, for a total pool size
of 16,588,800 bytes. Bind to the `wl_shm` global from the registry as explained
in chapter 5.1, then use it like so to create an shm pool which can hold these
buffers:

```c
const int width = 1920, height = 1080;
const int stride = width * 4;
const int shm_pool_size = height * stride * 2;

int fd = allocate_shm_file(shm_pool_size);
uint8_t *pool_data = mmap(NULL, size,
    PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);

struct wl_shm *shm = ...; // Bound from registry
struct wl_shm_pool *pool = wl_shm_create_pool(shm, fd, shm_pool_size);
```

## Creating buffers from a pool

Once word of this gets to the compositor, it will `mmap` this file descriptor as
well. Wayland is asyncronous, though, so we can start allocating buffers from
this pool right away. Since we allocated space for two buffers, we can assign
each an index and convert that index into a byte offset in the pool. Equipped
with this information, we can create a `wl_buffer`:

```c
int index = 0;
int offset = height * stride * index;
struct wl_buffer *buffer = wl_shm_pool_create_buffer(pool, offset,
    width, height, stride, WL_SHM_FORMAT_XRGB8888);
```

We can write an image to this buffer now as well. For example, to set it to
solid white:

```c
uint32_t *pixels = (uint32_t *)pool_data[offset];
memset(pixels, 0, width * height * 4);
```

Or, for something more interesting, here's a checkerboard pattern:

```c
uint32_t *pixels = (uint32_t *)pool_data[offset];
for (int y = 0; y < height; ++y) {
  for (int x = 0; x < width; ++x) {
    if ((x + y / 8 * 8) % 16 < 8) {
      pixels[y * width + x] = 0xFF666666;
    } else {
      pixels[y * width + x] = 0xFFEEEEEE;
    }
  }
}
```

With the stage set, we'll attach our buffer to our surface, mark the whole
surface as damaged[^1], and commit it:

```c
wl_surface_attach(surface, buffer, 0, 0);
wl_surface_damage(surface, 0, 0, UINT32_MAX, UINT32_MAX);
wl_surface_commit(surface);
```

If you were to apply all of this newfound knowledge to writing a Wayland client
yourself, you may arrive at this point confused when your buffer is not shown
on-screen. We're missing a critical final step - assigning your surface a role.
Turn to chapter 6.4 to learn more, or turn to the next page to learn about
another kind of buffer storage first.

[^1]: "Damaged" meaning "this area needs to be redrawn"
