## Keyboard input

Equipped with an understanding of how to use XKB, let's extend our Wayland code
to provide us with key events to feed into it. Similarly to how we obtained a
`wl_pointer` resource, we can use the `wl_seat.get_keyboard` request to create a
`wl_keyboard` for a seat whose capabilities include
`WL_SEAT_CAPABILITY_KEYBOARD`. When you're done with it, you should send the
"release" request:

```
<request name="release" type="destructor" since="3">
</request>
```

This will allow the server to clean up the resources associated with this
keyboard.

But how do you actually use it? Let's start with the basics.

### Key maps

When you bind to `wl_keyboard`, the first event that the server is likely to
send is `keymap`.

```
<enum name="keymap_format">
  <entry name="no_keymap" value="0" />
  <entry name="xkb_v1" value="1" />
</enum>

<event name="keymap">
  <arg name="format" type="uint" enum="keymap_format" />
  <arg name="fd" type="fd" />
  <arg name="size" type="uint" />
</event>
```

The `keymap_format` enum is provided in the event that we come
up with a new format for keymaps, but at the time of writing, XKB keymaps are
the only format which the server is likely to send.

Bulk data like this is transferred over file descriptors. We could simply read
from the file descriptor, but in general it's recommended to mmap it instead.
In C, this could look similar to the following code:

```
#include <sys/mman.h>
// ...

static void wl_keyboard_keymap(void *data, struct wl_keyboard *wl_keyboard,
        uint32_t format, int32_t fd, uint32_t size) {
    assert(format == WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1);
    struct my_state *state = (struct my_state *)data;

    char *map_shm = mmap(NULL, size, PROT_READ, MAP_PRIVATE, fd, 0);
    assert(map_shm != MAP_FAILED);

    struct xkb_keymap *keymap = xkb_keymap_new_from_string(
        state->xkb_context, map_shm, XKB_KEYMAP_FORMAT_TEXT_V1,
        XKB_KEYMAP_COMPILE_NO_FLAGS);
    munmap(map_shm, size);
    close(fd);

    // ...do something with keymap...
}
```

Once we have a keymap, we can interpret future keypress events for this
`wl_keyboard`. Note that the server can send a new keymap at any time, and all
future key events should be interpreted in that light.

### Keyboard focus

```
<event name="enter">
  <arg name="serial" type="uint" />
  <arg name="surface" type="object" interface="wl_surface" />
  <arg name="keys" type="array" />
</event>

<event name="leave">
  <arg name="serial" type="uint" />
  <arg name="surface" type="object" interface="wl_surface" />
</event>
```

Like `wl_pointer`'s "enter" and "leave" events are issued when a pointer is
moved over your surface, the server sends `wl_keyboard.enter` when a surface
receives keyboard focus, and `wl_keyboard.leave` when it's lost. Many
applications will change their appearance under these conditions &mdash; for
example, to start drawing a blinking caret.

The "enter" event also includes an array of currently pressed keys. This is an
array of 32-bit unsigned integers, each representing the scancode of a pressed
key.

### Input events

Once the keyboard has entered your surface, you can expect to start receiving
input events.

```
<enum name="key_state">
  <entry name="released" value="0" />
  <entry name="pressed" value="1" />
</enum>

<event name="key">
  <arg name="serial" type="uint" />
  <arg name="time" type="uint" />
  <arg name="key" type="uint" />
  <arg name="state" type="uint" enum="key_state" />
</event>

<event name="modifiers">
  <arg name="serial" type="uint" />
  <arg name="mods_depressed" type="uint" />
  <arg name="mods_latched" type="uint" />
  <arg name="mods_locked" type="uint" />
  <arg name="group" type="uint" />
</event>
```

The "key" event is sent when the user presses or releases a key. Like many input
events, a serial is included which you can use to associate future requests with
this input event. The "key" is the scancode of the key which was pressed or
released, and the "state" is the pressed or released state of that key.

**Important**: the scancode from this event is the Linux evdev scancode. To
translate this to an XKB scancode, you must add 8 to the evdev scancode.

The modifiers event includes a similar serial, as well as masks of the
depressed, latched, and locked modifiers, and the index of the input group
currently in use. A modifier is depressed, for example, while you hold down
Shift. A modifier can latch, such as pressing Shift with sticky keys enabled -
it'll stop taking effect after the next non-modifier key is pressed. And a
modifier can be locked, such as when caps lock is toggled on or off. Input
groups are used to switch between various keyboard layouts, such as toggling
between ISO and ANSI layouts, or for more language-specific features.

The interpretation of modifiers is keymap-specific. You should forward them both
to XKB to deal with. Most implementations of the "modifiers" event are
straightforward:

```
static void wl_keyboard_modifiers(void *data, struct wl_keyboard *wl_keyboard,
        uint32_t serial, uint32_t depressed, uint32_t latched,
        uint32_t locked, uint32_t group) {
    struct my_state *state = (struct my_state *)data;
    xkb_state_update_mask(state->xkb_state,
        depressed, latched, locked, 0, 0, group);
}
```

### Key repeat

The last event to consider is the "repeat_info" event:

```
<event name="repeat_info" since="4">
  <arg name="rate" type="int" />
  <arg name="delay" type="int" />
</event>
```

In Wayland, the client is responsible for implementing "key repeat" &mdash; the
feature which continues to type characters as long as you've got the key held
doooooown. This event is sent to inform the client of the user's preferences
for key repeat settings. The "delay" is the number of milliseconds a key should
be held down for before key repeat kicks in, and the "rate" is the number of
characters per second to repeat until the key is released.
