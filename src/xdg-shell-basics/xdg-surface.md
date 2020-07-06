# XDG surfaces

Surfaces in the domain of xdg-shell are referred to as `xdg_surfaces`, and this
interface brings with it a small amount of functionality common to both kinds of
XDG surfaces - toplevels and popups. The semantics for each kind of XDG
surface are different enough still that they must be specified explicitly
through an additional role.

The `xdg_surface` interface provides additional requests for assigning the more
specific roles of popup and toplevel. Once we've bound an object to the
`xdg_wm_base` global, we can use the `get_xdg_surface` request to obtain one for
a `wl_surface`.

```xml
<request name="get_xdg_surface">
  <arg name="id" type="new_id" interface="xdg_surface"/>
  <arg name="surface" type="object" interface="wl_surface"/>
</request>
```

The `xdg_surface` interface, in addition to requests for assigning a more
specific role of toplevel or popup to your surface, also includes some important
functionality common to both roles. Let's review these before we move on to the
toplevel- and popup-specific semantics.

```xml
<event name="configure">
  <arg name="serial" type="uint" summary="serial of the configure event"/>
</event>

<request name="ack_configure">
  <arg name="serial" type="uint" summary="the serial from the configure event"/>
</request>
```

The most important API of xdg-surface is this pair: `configure` and
`ack_configure`. You may recall that a goal of Wayland is to make every frame
perfect. That means no frames are shown with a half-applied state change, and to
accomplish this we have to synchronize these changes between the client and
server. For XDG surfaces, this pair of messages is the mechanism which supports
this.

We're only covering the basics for now, so we'll summarize the importance of
these two events as such: as events from the server inform your configuration
(or reconfiguration) of a surface, apply them to a pending state. When a
`configure` event arrives, apply the pending changes, use `ack_configure` to
acknowledge you've done so, and render and commit a new frame. We'll show this
in practice in the next chapter, and explain it in detail in chapter 8.1.

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
