# XDG surfaces

Surfaces under the authority of xdg-shell are referred to as `xdg_surface`s, and
this interface brings with it a small amount of functionality common to both
kinds of XDG surfaces. Creating an `xdg_surface` is not, however, sufficient to
get the compositor to display it. The semantics for each kind of XDG surface -
toplevels and popups - are different enough still that they must be specified
explicitly through an additional role.

Before we can do this, we must obtain an `xdg_surface`, which provides
additional requests for assigning a more specific role. Once we've bound an
object to the `xdg_wm_base` global, we can use the `get_xdg_surface` request for
this purpose.

```xml
<request name="get_xdg_surface">
  <arg name="id" type="new_id" interface="xdg_surface"/>
  <arg name="surface" type="object" interface="wl_surface"/>
</request>
```

The `xdg_surface` interface, in addition to requests for assigning a more
specific role of toplevel or popup to your surface, contains some important
requests addressing behavior common to both roles. Let's consider these before
we move on to the toplevel and popup semantics.

```xml
<request name="set_window_geometry">
  <arg name="x" type="int"/>
  <arg name="y" type="int"/>
  <arg name="width" type="int"/>
  <arg name="height" type="int"/>
</request>
```

The `set_window_geometry` request is used primarily for applications using
client-side decorations, to distinguish the parts of their surface which are
considered a part of the window, and the parts which are not. Most commonly,
this is used to exclude client-side drop-shadows rendered behind the window from
being considered a part of it. The compositor may apply this information to
govern its own behaviors for arranging and interacting with the window.

```xml
<request name="ack_configure">
  <arg name="serial" type="uint" summary="the serial from the configure event"/>
</request>

<event name="configure">
  <arg name="serial" type="uint" summary="serial of the configure event"/>
</event>
```

This pair is more complicated. You'll recall that a fundamental goal of Wayland:
every frame ought to be perfect. For this reason, nearly all of Wayland's
interfaces are designed to be atomic, even when updating lots of information
over several requests. For surfaces in particular, this is an involved process.
Because the semantics of services span several interfaces, orchestrating atomic
changes to of all of their respective states is not trivial.

Consider for example the problem of maximizing a window. When the window is not
maximized, it has been drawn a certain way. It's shown at a certain resolution,
and client-side decorations, if present, often indicate this state visually. The
toplevel interface we'll explore in the next chapter offers a means of
maximizing a window, but how do we synchronize this? The client must render a new
buffer at the desired resolution, with any necessary changes to its appearance
to indicate the new state, then provide the compositor with the updated buffer.
Until then, the compositor will continue showing the last good buffer it has,
and only once the client has replied can it present the changes. This all must
be accomplished asynchronously.

Though this sounds complicated, the consequences of it are simple. As changes to
the state and appearance of your window are negotiated through events in the
higher-level toplevel and popup interfaces, you should queue up the changes
until you receive a configure event. When you do, you may apply the changes,
render and attach a new buffer, and send an ack configure request with the same
serial. Or, if you're a server, you should allocate a serial and queue up the
changes similarly, keyed by that serial. When you receive a configure event,
you'll know that the client has arrived at a state consistent with the
corresponding serial and you may safely apply the changes.
