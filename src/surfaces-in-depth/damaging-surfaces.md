## Damaging surfaces

You may have noticed in the last example that we added this line of code when we
committed a new frame for the surface:

```
wl_surface_damage_buffer(state->wl_surface, 0, 0, INT32_MAX, INT32_MAX);
```

If so, sharp eye! This code *damages* our surface, indicating to the compositor
that it needs to be redrawn. Here we damage the entire surface (and well beyond
it), but we could instead only damage part of it.

Let's say, for example, that you've written a GUI toolkit and the user is typing
into a textbox. That textbox probably only takes up a small part of the window,
and each new character takes up a smaller part still. When the user presses a
key, you could render just the new character appended to the text they're
writing, then damage only that part of the surface. The compositor can then copy
just a fraction of your surface, which can speed things up considerably -
especially for embedded devices. As you blink the caret between characters,
you'll want to submit damage for its updates, and when the user changes views,
you'll likely damage the entire surface. This way, everyone does less work, and
the user will thank you for their improved battery life.

**Note**: The Wayland protocol provides two requests for damaging surfaces:
`damage` and `damage_buffer`. The former is effectively deprecated, and you
should only use the latter. The difference between them is that `damage` takes
into account all of the transforms affecting the surface, such as rotations,
scale factor, and buffer position and clipping. The latter instead applies
damage relative to the buffer, which is generally easier to reason about.
