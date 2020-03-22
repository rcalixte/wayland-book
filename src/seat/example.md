# Expanding our example code

In previous chapters, we built a simple client which can present its surfaces on
the display. Let's expand this code a bit to build a client which can receive
input events. For the sake of simplicity, we're just going to be logging input
events to stderr.

This is going to require a lot more code than we've worked with so far, so get
strapped in. The first thing we need to do is set up the seat.

## Setting up the seat

The first thing we'll need is a reference to a seat. We'll add it to our
`client_state` struct, and add keyboard, pointer, and touch objects for later
use as well:

```diff
        struct wl_shm *wl_shm;
        struct wl_compositor *wl_compositor;
        struct xdg_wm_base *xdg_wm_base;
+       struct wl_seat *wl_seat;
        /* Objects */
        struct wl_surface *wl_surface;
        struct xdg_surface *xdg_surface;
+       struct wl_keyboard *wl_keyboard;
+       struct wl_pointer *wl_pointer;
+       struct wl_touch *wl_touch;
        /* State */
        float offset;
        uint32_t last_frame;
        int width, height;
```

We'll also need to update `registry_global` to register a listener for that
seat.

```diff
                                wl_registry, name, &xdg_wm_base_interface, 1);
                xdg_wm_base_add_listener(state->xdg_wm_base,
                                &xdg_wm_base_listener, state);
+       } else if (strcmp(interface, wl_seat_interface.name) == 0) {
+               state->wl_seat = wl_registry_bind(
+                               wl_registry, name, &wl_seat_interface, 7);
+               wl_seat_add_listener(state->wl_seat,
+                               &wl_seat_listener, state);
        }
 }
```

Note that we bind to the latest version of the seat interface, version 7. Let's
also rig up that listener:

```diff
+static void
+wl_seat_capabilities(void *data, struct wl_seat *wl_seat, uint32_t capabilities)
+{
+       struct client_state *state = data;
+       /* TODO */
+}
+
+static void
+wl_seat_name(void *data, struct wl_seat *wl_seat, const char *name)
+{
+       fprintf(stderr, "seat name: %s\n", name);
+}
+
+const static struct wl_seat_listener wl_seat_listener = {
+       .capabilities = wl_seat_capabilities,
+       .name = wl_seat_name,
+};
```

If you compile (`cc -o client client.c xdg-shell-protocol.c`) and run this now,
you should seat the name of the seat printed to stderr.

## Rigging up pointer events

Let's get to pointer events. If you recall, pointer events from the Wayland
server are to be accumulated into a single logical event. For this reason, we'll
need to define a struct to store them in.

```diff
+enum pointer_event_mask {
+       POINTER_EVENT_ENTER = 1 << 0,
+       POINTER_EVENT_LEAVE = 1 << 1,
+       POINTER_EVENT_MOTION = 1 << 2,
+       POINTER_EVENT_BUTTON = 1 << 3,
+       POINTER_EVENT_AXIS = 1 << 4,
+       POINTER_EVENT_AXIS_SOURCE = 1 << 5,
+       POINTER_EVENT_AXIS_STOP = 1 << 6,
+       POINTER_EVENT_AXIS_DISCRETE = 1 << 7,
+};
+
+struct pointer_event {
+       uint32_t event_mask;
+       wl_fixed_t surface_x, surface_y;
+       uint32_t button, state;
+       uint32_t time;
+       uint32_t serial;
+       struct {
+               bool valid;
+               wl_fixed_t value;
+               int32_t discrete;
+       } axes[2];
+       uint32_t axis_source;
+};
```

We'll be using a bitmask here to identify which events we've received for a
single pointer frame, and storing the relevant information from each event in
their respective fields. Let's add this to our state struct as well:

```diff
        /* State */
        float offset;
        uint32_t last_frame;
        int width, height;
        bool closed;
+       struct pointer_event pointer_event;
 };
```

Then we'll need to update our `wl_seat_capabilities` to set up the pointer
object for seats which are capable of pointer input.

```diff
 static void
 wl_seat_capabilities(void *data, struct wl_seat *wl_seat, uint32_t capabilities)
 {
        struct client_state *state = data;
-       /* TODO */
+
+       bool have_pointer = capabilities & WL_SEAT_CAPABILITY_POINTER;
+
+       if (have_pointer && state->wl_pointer == NULL) {
+               state->wl_pointer = wl_seat_get_pointer(state->wl_seat);
+               wl_pointer_add_listener(state->wl_pointer,
+                               &wl_pointer_listener, state);
+       } else if (!have_pointer && state->wl_pointer != NULL) {
+               wl_pointer_release(state->wl_pointer);
+               state->wl_pointer = NULL;
+       }
 }
```

This merits some explanation. Recall that `capabilities` is a bitmask of the
kinds of devices supported by this seat - a bitwise AND (&) with a capability
will produce a non-zero value if supported. Then, if we have a pointer and have
*not* already configured it, we take the first branch, using
`wl_seat_get_pointer` to obtain a pointer reference and storing it in our state.
If the seat does *not* support pointers, but we already have one configured, we
use `wl_pointer_release` to get rid of it. Remember that the capabilities of a
seat can change at runtime, for example when the user un-plugs and re-plugs
their mouse.

We also configured a listener for the pointer. Let's add the struct for that,
too:

```diff
+const static struct wl_pointer_listener wl_pointer_listener = {
+       .enter = wl_pointer_enter,
+       .leave = wl_pointer_leave,
+       .motion = wl_pointer_motion,
+       .button = wl_pointer_button,
+       .axis = wl_pointer_axis,
+       .frame = wl_pointer_frame,
+       .axis_source = wl_pointer_axis_source,
+       .axis_stop = wl_pointer_axis_stop,
+       .axis_discrete = wl_pointer_axis_discrete,
+};
```

Pointers have a lot of events. Let's have a look at them.

```diff
+static void
+wl_pointer_enter(void *data, struct wl_pointer *wl_pointer,
+               uint32_t serial, struct wl_surface *surface,
+               wl_fixed_t surface_x, wl_fixed_t surface_y)
+{
+       struct client_state *client_state = data;
+       client_state->pointer_event.event_mask |= POINTER_EVENT_ENTER;
+       client_state->pointer_event.serial = serial;
+       client_state->pointer_event.surface_x = surface_x,
+               client_state->pointer_event.surface_y = surface_y;
+}
+
+static void
+wl_pointer_leave(void *data, struct wl_pointer *wl_pointer,
+               uint32_t serial, struct wl_surface *surface)
+{
+       struct client_state *client_state = data;
+       client_state->pointer_event.serial = serial;
+       client_state->pointer_event.event_mask |= POINTER_EVENT_LEAVE;
+}
```

The "enter" and "leave" events are fairly straightforward, and they set the
stage for the rest of the implementation. We update the event mask to include
the appropriate event, then populate it with the data we were provided. The
"motion" and "button" events are rather similar:

```diff
+static void
+wl_pointer_motion(void *data, struct wl_pointer *wl_pointer, uint32_t time,
+               wl_fixed_t surface_x, wl_fixed_t surface_y)
+{
+       struct client_state *client_state = data;
+       client_state->pointer_event.event_mask |= POINTER_EVENT_MOTION;
+       client_state->pointer_event.time = time;
+       client_state->pointer_event.surface_x = surface_x,
+               client_state->pointer_event.surface_y = surface_y;
+}
+
+static void
+wl_pointer_button(void *data, struct wl_pointer *wl_pointer, uint32_t serial,
+               uint32_t time, uint32_t button, uint32_t state)
+{
+       struct client_state *client_state = data;
+       client_state->pointer_event.event_mask |= POINTER_EVENT_BUTTON;
+       client_state->pointer_event.time = time;
+       client_state->pointer_event.serial = serial;
+       client_state->pointer_event.button = button,
+               client_state->pointer_event.state = state;
+}
```

Axis events are somewhat more complex, because there are two axes: horizontal
and vertical. Thus, our `pointer_event` struct contains an array with two groups
of axis events. Our code to handle these ends up something like this:

```diff
+static void
+wl_pointer_axis(void *data, struct wl_pointer *wl_pointer, uint32_t time,
+               uint32_t axis, wl_fixed_t value)
+{
+       struct client_state *client_state = data;
+       client_state->pointer_event.event_mask |= POINTER_EVENT_AXIS;
+       client_state->pointer_event.time = time;
+       client_state->pointer_event.axes[axis].valid = true;
+       client_state->pointer_event.axes[axis].value = value;
+}
+
+static void
+wl_pointer_axis_source(void *data, struct wl_pointer *wl_pointer,
+               uint32_t axis_source)
+{
+       struct client_state *client_state = data;
+       client_state->pointer_event.event_mask |= POINTER_EVENT_AXIS_SOURCE;
+       client_state->pointer_event.axis_source = axis_source;
+}
+
+static void
+wl_pointer_axis_stop(void *data, struct wl_pointer *wl_pointer,
+               uint32_t time, uint32_t axis)
+{
+       struct client_state *client_state = data;
+       client_state->pointer_event.time = time;
+       client_state->pointer_event.event_mask |= POINTER_EVENT_AXIS_STOP;
+       client_state->pointer_event.axes[axis].valid = true;
+}
+
+static void
+wl_pointer_axis_discrete(void *data, struct wl_pointer *wl_pointer,
+               uint32_t axis, int32_t discrete)
+{
+       struct client_state *client_state = data;
+       client_state->pointer_event.event_mask |= POINTER_EVENT_AXIS_STOP;
+       client_state->pointer_event.axes[axis].valid = true;
+       client_state->pointer_event.axes[axis].discrete = discrete;
+}
```

Similarly straightforward, aside from the main change of updating whichever axis
was affected. Note the use of the "valid" boolean as well: it's possible that
we'll receive a pointer frame which updates one axis, but not another, so we use
this "valid" value to determine which axes were updated in the frame event.

Speaking of which, it's time for the main attraction: our "frame" handler.

```diff
+static void
+wl_pointer_frame(void *data, struct wl_pointer *wl_pointer)
+{
+       struct client_state *client_state = data;
+       struct pointer_event *event = &client_state->pointer_event;
+       fprintf(stderr, "pointer frame @ %d: ", event->time);
+
+       if (event->event_mask & POINTER_EVENT_ENTER) {
+               fprintf(stderr, "entered %f, %f ",
+                               wl_fixed_to_double(event->surface_x),
+                               wl_fixed_to_double(event->surface_y));
+       }
+
+       if (event->event_mask & POINTER_EVENT_LEAVE) {
+               fprintf(stderr, "leave");
+       }
+
+       if (event->event_mask & POINTER_EVENT_MOTION) {
+               fprintf(stderr, "motion %f, %f ",
+                               wl_fixed_to_double(event->surface_x),
+                               wl_fixed_to_double(event->surface_y));
+       }
+
+       if (event->event_mask & POINTER_EVENT_LEAVE) {
+               fprintf(stderr, "leave");
+       }
+
+       if (event->event_mask & POINTER_EVENT_MOTION) {
+               fprintf(stderr, "motion %f, %f ",
+                               wl_fixed_to_double(event->surface_x),
+                               wl_fixed_to_double(event->surface_y));
+       }
+
+       if (event->event_mask & POINTER_EVENT_BUTTON) {
+               char *state = event->state == WL_POINTER_BUTTON_STATE_RELEASED ?
+                       "released" : "pressed";
+               fprintf(stderr, "button %d %s ", event->button, state);
+       }
+
+       uint32_t axis_events = POINTER_EVENT_AXIS
+               | POINTER_EVENT_AXIS_SOURCE
+               | POINTER_EVENT_AXIS_STOP
+               | POINTER_EVENT_AXIS_DISCRETE;
+       char *axis_name[2] = {
+               [WL_POINTER_AXIS_VERTICAL_SCROLL] = "vertical",
+               [WL_POINTER_AXIS_HORIZONTAL_SCROLL] = "horizontal",
+       };
+       char *axis_source[4] = {
+               [WL_POINTER_AXIS_SOURCE_WHEEL] = "wheel",
+               [WL_POINTER_AXIS_SOURCE_FINGER] = "finger",
+               [WL_POINTER_AXIS_SOURCE_CONTINUOUS] = "continuous",
+               [WL_POINTER_AXIS_SOURCE_WHEEL_TILT] = "wheel tilt",
+       };
+       if (event->event_mask & axis_events) {
+               for (size_t i = 0; i < 2; ++i) {
+                       if (!event->axes[i].valid) {
+                               continue;
+                       }
+                       fprintf(stderr, "%s axis ", axis_name[i]);
+                       if (event->event_mask & POINTER_EVENT_AXIS) {
+                               fprintf(stderr, "value %d ", wl_fixed_to_double(
+                                                       event->axes[i].value));
+                       }
+                       if (event->event_mask & POINTER_EVENT_AXIS_DISCRETE) {
+                               fprintf(stderr, "discrete %d ",
+                                               event->axes[i].discrete);
+                       }
+                       if (event->event_mask & POINTER_EVENT_AXIS_SOURCE) {
+                               fprintf(stderr, "via %s ",
+                                               axis_source[event->axis_source]);
+                       }
+                       if (event->event_mask & POINTER_EVENT_AXIS_STOP) {
+                               fprintf(stderr, "(stopped) ");
+                       }
+               }
+       }
+
+       fprintf(stderr, "\n");
+       memset(event, 0, sizeof(*event));
+}
```

It certainly is the longest of the bunch, isn't it? Hopefully it isn't too
confusing, though. All we're doing here is pretty-printing the accumulated state
for this frame to stderr. If you compile and run this again now, you should be
able to wiggle your mouse over the window and see input events printed out!

## Rigging up keyboard events

Let's update our `client_state` struct with some fields to store XKB state.

```diff
@@ -105,6 +107,9 @@ struct client_state {
        int width, height;
        bool closed;
        struct pointer_event pointer_event;
+       struct xkb_state *xkb_state;
+       struct xkb_context *xkb_context;
+       struct xkb_keymap *xkb_keymap;
};
```

We need the xkbcommon headers to define these. While we're at it, I'm going to
pull in `assert.h` as well:

```diff
@@ -1,4 +1,5 @@
 #define _POSIX_C_SOURCE 200112L
+#include <assert.h>
 #include <errno.h>
 #include <fcntl.h>
 #include <limits.h>
@@ -9,6 +10,7 @@
 #include <time.h>
 #include <unistd.h>
 #include <wayland-client.h>
+#include <xkbcommon/xkbcommon.h>
 #include "xdg-shell-client-protocol.h"
```

We'll also need to initialize the xkb_context in our main function:

```diff
@@ -603,6 +649,7 @@ main(int argc, char *argv[])
        state.height = 480;
        state.wl_display = wl_display_connect(NULL);
        state.wl_registry = wl_display_get_registry(state.wl_display);
+       state.xkb_context = xkb_context_new(XKB_CONTEXT_NO_FLAGS);
        wl_registry_add_listener(state.wl_registry, &wl_registry_listener, &state);
        wl_display_roundtrip(state.wl_display);
```

Next, let's update our seat capabilities function to rig up our keyboard
listener, too.

```diff
        } else if (!have_pointer && state->wl_pointer != NULL) {
                wl_pointer_release(state->wl_pointer);
                state->wl_pointer = NULL;
        }
+
+       if (have_keyboard && state->wl_keyboard == NULL) {
+               state->wl_keyboard = wl_seat_get_keyboard(state->wl_seat);
+               wl_keyboard_add_listener(state->wl_keyboard,
+                               &wl_keyboard_listener, state);
+       } else if (!have_keyboard && state->wl_keyboard != NULL) {
+               wl_keyboard_release(state->wl_keyboard);
+               state->wl_keyboard = NULL;
+       }
 }
```

We'll have to define the `wl_keyboard_listener` we use here, too.

```diff
+const static struct wl_keyboard_listener wl_keyboard_listener = {
+       .keymap = wl_keyboard_keymap,
+       .enter = wl_keyboard_enter,
+       .leave = wl_keyboard_leave,
+       .key = wl_keyboard_key,
+       .modifiers = wl_keyboard_modifiers,
+       .repeat_info = wl_keyboard_repeat_info,
+};
```

And now, the meat of the changes. Let's start with the keymap:

```diff
+static void
+wl_keyboard_keymap(void *data, struct wl_keyboard *wl_keyboard,
+               uint32_t format, int32_t fd, uint32_t size)
+{
+       struct client_state *client_state = data;
+       assert(format == WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1);
+
+       char *map_shm = mmap(NULL, size, PROT_READ, MAP_SHARED, fd, 0);
+       assert(map_shm != MAP_FAILED);
+
+       struct xkb_keymap *xkb_keymap = xkb_keymap_new_from_string(
+                       client_state->xkb_context, map_shm,
+                       XKB_KEYMAP_FORMAT_TEXT_V1, XKB_KEYMAP_COMPILE_NO_FLAGS);
+       munmap(map_shm, size);
+       close(fd);
+
+       struct xkb_state *xkb_state = xkb_state_new(xkb_keymap);
+       xkb_keymap_unref(client_state->xkb_keymap);
+       xkb_state_unref(client_state->xkb_state);
+       client_state->xkb_keymap = xkb_keymap;
+       client_state->xkb_state = xkb_state;
+}
```

Now we can see why we added `assert.h` &mdash; we're using it here to make sure
that the keymap format is the one we expect. Then, we use mmap to map the file
descriptor the compositor sent us to a `char *` pointer we can pass into
`xkb_keymap_new_from_string`. Don't forget to munmap and close that fd
afterwards &mdash; then we set up our XKB state. Note as well that we have also
unrefed any previous XKB keymap or state that we had set up in a prior call to
this function, in case the compositor changes the keymap at runtime.[^1]

```diff
+static void
+wl_keyboard_enter(void *data, struct wl_keyboard *wl_keyboard,
+               uint32_t serial, struct wl_surface *surface,
+               struct wl_array *keys)
+{
+       struct client_state *client_state = data;
+       fprintf(stderr, "keyboard enter; keys pressed are:\n");
+       uint32_t *key;
+       wl_array_for_each(key, keys) {
+               char buf[128];
+               xkb_keysym_t sym = xkb_state_key_get_one_sym(
+                               client_state->xkb_state, *key + 8);
+               xkb_keysym_get_name(sym, buf, sizeof(buf));
+               fprintf(stderr, "sym: %-12s (%d), ", buf, sym);
+               xkb_state_key_get_utf8(client_state->xkb_state,
+                               *key + 8, buf, sizeof(buf));
+               fprintf(stderr, "utf8: '%s'\n", buf);
+       }
+}
```

When the keyboard "enters" our surrface, we have received keyboard focus. The
compositor forwards a list of keys which were already pressed at that time, and
here we just enumerate them and log their keysym names and UTF-8 equivalent.
We'll do something similar when keys are pressed:

```diff
+static void
+wl_keyboard_key(void *data, struct wl_keyboard *wl_keyboard,
+               uint32_t serial, uint32_t time, uint32_t key, uint32_t state)
+{
+       struct client_state *client_state = data;
+       char buf[128];
+       uint32_t keycode = key + 8;
+       xkb_keysym_t sym = xkb_state_key_get_one_sym(
+                       client_state->xkb_state, keycode);
+       xkb_keysym_get_name(sym, buf, sizeof(buf));
+       const char *action =
+               state == WL_KEYBOARD_KEY_STATE_PRESSED ? "press" : "release";
+       fprintf(stderr, "key %s: sym: %-12s (%d), ", action, buf, sym);
+       xkb_state_key_get_utf8(client_state->xkb_state, keycode,
+                       buf, sizeof(buf));
+       fprintf(stderr, "utf8: '%s'\n", buf);
+}
```

And finally, we add small implementations of the three remaining events:

```diff
+static void
+wl_keyboard_leave(void *data, struct wl_keyboard *wl_keyboard,
+               uint32_t serial, struct wl_surface *surface)
+{
+       fprintf(stderr, "keyboard leave\n");
+}
+
+static void
+wl_keyboard_modifiers(void *data, struct wl_keyboard *wl_keyboard,
+               uint32_t mods_latched, uint32_t mods_locked,
+               uint32_t group)
+{
+       struct client_state *client_state = data;
+       xkb_state_update_mask(client_state->xkb_state,
+               mods_depressed, mods_latched, mods_locked, 0, 0, group);
+}
+
+static void
+wl_keyboard_repeat_info(void *data, struct wl_keyboard *wl_keyboard,
+               int32_t rate, int32_t delay)
+{
+       /* Left as an exercise for the reader */
+}
```

For modifiers, we could decode these further, but most applications won't need
to. We just update the XKB state here. As for handling key repeat &mdash; this
has a lot of constraints particular to your application. Do you want to repeat
text input? Do you want to repeat keyboard shortcuts? How does the timing of
these interact with your event loop? The answers to these questions is left for
you to decide.

If you compile this again, you should be able to start typing into the window
and see your input printed into the log. Huzzah!

## TODO

- touch input

[^1]: This actually does happen in practice!
