# Creating a display

Fire up your text editor - it's time to write our first lines of code.

## For Wayland clients

Connecting to a Wayland server and creating a `wl_display` to manage the
connection's state is quite easy:

```c
#include <stdio.h>
#include <wayland-client.h>

int
main(int argc, char *argv[])
{
    struct wl_display *display = wl_display_connect(NULL);
    if (!display) {
        fprintf(stderr, "Failed to connect to Wayland display.\n");
        return 1;
    }
    fprintf(stderr, "Connection established!\n");

    wl_display_disconnect(display);
    return 0;
}
```

Let's compile and run this program. Assuming you're using a Wayland compositor
as you read this, the result should look like this:

```sh
$ cc -o client client.c -lwayland-client
$ ./client
Connection established!
```

`wl_display_connect` is the most common way for clients to establish a Wayland
connection. The signature is:

```c
struct wl_display *wl_display_connect(const char *name);
```

The "name" argument is the name of the Wayland display, which is typically
`"wayland-0"`. You can swap the `NULL` for this in our test client and try for
yourself - it's likely to work. This corresponds to the name of a Unix socket in
`$XDG_RUNTIME_DIR`. `NULL` is preferred, however, in which case libwayland will:

1. If `$WAYLAND_DISPLAY` is set, attempt to connect to
   `$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY`
2. Attempt to connect to `$XDG_RUNTIME_DIR/wayland-0`
3. Fail :(

This allows users to specify the Wayland display they want to run their clients
on by setting the `$WAYLAND_DISPLAY` to the desired display. If you have more
complex requirements, you can also establish the connection yourself and create
a Wayland display from a file descriptor:

```c
struct wl_display *wl_display_connect_to_fd(int fd);
```

You can also obtain the file descriptor that the `wl_display` is using via
`wl_display_get_fd`, regardless of how you created the display.

```c
int wl_display_get_fd(struct wl_display *display);
```

## For Wayland servers

The process is fairly simple for servers as well. The creation of the display
and binding to a socket are separate, to give you time to configure the display
before any clients are able to connect to it. Here's another minimal example
program:

```c
#include <stdio.h>
#include <wayland-server.h>

int
main(int argc, char *argv[])
{
    struct wl_display *display = wl_display_create();
    if (!display) {
        fprintf(stderr, "Unable to create Wayland display.\n");
        return 1;
    }

    const char *socket = wl_display_add_socket_auto(display);
    if (!socket) {
        fprintf(stderr, "Unable to add socket to Wayland display.\n");
        return 1;
    }

    fprintf(stderr, "Running Wayland display on %s\n", socket);
    wl_display_run(display);

    wl_display_destroy(display);
    return 0;
}
```

Let's compile and run this, too:

```sh
$ cc -o server -lwayland-server server.c
$ ./server &
Running Wayland display on wayland-1
$ WAYLAND_DISPLAY=wayland-1 ./client
Connection established!
```

Using `wl_display_add_socket_auto` will allow libwayland to decide the name for
the display automatically, which defaults to `wayland-0`, or `wayland-$n`,
depending on if any other Wayland compositors have sockets in
`$XDG_RUNTIME_DIR`. However, as with the client, you have some other options for
configuring the display:

```c
int wl_display_add_socket(struct wl_display *display, const char *name);

int wl_display_add_socket_fd(struct wl_display *display, int sock_fd);
```

After adding the socket, calling `wl_display_run` will run libwayland's internal
event loop and block until `wl_display_terminate` is called. What's this event
loop? Turn the page and find out!
