# XKB, briefly

The next input device on our list is keyboards, but we need to stop and give you
some additional context before we discuss them. Keymaps are an essential detail
involved in keyboard input, and XKB is the recommended way of handling them on
Wayland.

When you press a key on your keyboard, it sends a *scancode* to the computer,
which is simply a number assigned to that physical key. On my keyboard, scancode
1 is the Escape key, the '1' key is scancode 2, 'a' is 30, Shift is 42, and so
on.  I use a US ANSI keyboard layout, but there are many other layouts, and
their scancodes differ. On my friend's German keyboard, scancode 12 produces
'ß', while mine produces '-'.

To solve this problem, we use a library called "xkbcommon", which is named for
its role as the common code from XKB (X KeyBoard) extracted into a standalone
library. XKB defines a huge number of key *symbols*, such as XKB_KEY_A, and
XKB_KEY_ssharp (ß, from German), and XKB_KEY_kana_WO (を, from Japanese).

Identifying these keys and correlating them with key symbols like this is only
part of the problem, however. 'a' can produce 'A' if the shift key is held down,
'を' is written as 'ヲ' in Katakana mode, and while there is strictly speaking
an uppercase version of 'ß', it's hardly ever used and certainly never typed.
Keys like Shift are called *modifiers*, and groups like Hiragana and Katakana
are called *groups*. Some modifiers can *latch*, like Caps Lock. XKB has
primitives for dealing with all of these cases, and maintains a state machine
which tracks what your keyboard is doing and figures out exactly which *Unicode
codepoints* the user is trying to type.

## Using XKB

So how is xkbcommon actually used? Well, the first step is to link to it and
grab the header, `xkbcommon/xkbcommon.h`.[^1] Most programs which utilize
xkbcommon will have to manage three objects:

- xkb_context: a handle used for configuring other XKB resources
- xkb_keymap: a mapping from scancodes to key symbls
- xkb_state: a state machine that turns key symbols into UTF-8 strings

The process for setting this up usually goes as follows:

1. Use `xkb_context_new` to create a new xkb_context, passing it
   `XKB_CONTEXT_NO_FLAGS` unless you're doing something weird.
2. Obtain a key map as a string.*
3. Use `xkb_keymap_new_from_string` to create an `xkb_keymap` for this key map.
   There's only one key map format, `XKB_KEYMAP_FORMAT_TEXT_V1`, which you'll
   pass for the format parameter. Again, unless you're doing something weird,
   you'll use `XKB_KEYMAP_COMPILE_NO_FLAGS` for the flags.
4. Use `xkb_state_new` to create an xkb_state with your keymap. The state will
   increment the refcount for the keymap, so use `xkb_keymap_unref` if you're
   done with it yourself.
5. Obtain scancodes from a keyboard.*
5. Feed the scancodes into `xkb_state_key_get_one_sym` to get keysyms, and into
   `xkb_state_key_get_utf8` to get UTF-8 strings. Tada!

<div style="text-align: right">
  <em>* These steps are discussed in the next section.</em>
</div>

In terms of code, the process looks like the following:

```c
#include <xkbcommon/xkbcommon.h> // -lxkbcommon
/* ... */

const char *keymap_str = /* ... */;

/* Create an XKB context */
struct xkb_context *context = xkb_context_new(XKB_CONTEXT_NO_FLAGS);

/* Use it to parse a keymap string */
struct xkb_keymap *keymap = xkb_keymap_new_from_string(
    xkb_context, keymap_str, XKB_KEYMAP_FORMAT_TEXT_V1,
    XKB_KEYMAP_COMPILE_NO_FLAGS);

/* Create an XKB state machine */
struct xkb_state *state = xkb_state_new(keymap);
```

Then, to process scancodes:

```c
int scancode = /* ... */;

xkb_keysym_t sym = xkb_state_key_get_one_sym(xkb_state, scancode);
if (sym == XKB_KEY_F1) {
    /* Do the thing you do when the user presses F1 */
}

char buf[128];
xkb_state_key_get_utf8(xkb_state, scancode, buf, sizeof(buf));
printf("UTF-8 input: %s\n", buf);
```

Equipped with these details, we're ready to tackle processing keyboard input.

[^1]: xkbcommon ships with a pc file: use `pkgconf --cflags xkbcommon` and `pkgconf --libs xkbcommon`, or your build system's preferred way of consuming pc files.
