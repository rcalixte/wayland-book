# Configuration & lifecycle

Previously, we created a window at a fixed size of our choosing: 640x480.
However, the compositor will often have an opinion about what size our window
should assume, and we may want to communicate our preferences as well. Failure
to do so will often lead to undesirable behavior, like parts of your window
being cut off by a compositor who's trying to tell you to make your surface
smaller.

The compositor can offer additional clues to the application about the context
in which it's being shown. It can let you know if your application is maximized
or fullscreen, tiled on one or more sides against other windows or the edge of
the display, focused or idle, and so on. As `wl_surface` is used to atomically
communicate surface changes from client to server, the `xdg_surface` interface
provides the following two messages for the compositor to suggest changes and
the client to acknowledge them:

```xml
<request name="ack_configure">
  <arg name="serial" type="uint" />
</request>

<event name="configure">
  <arg name="serial" type="uint" />
</event>
```

On their own, these messages carry little meaning. However, each subclass of
`xdg_surface` (`xdg_toplevel` and `xdg_popup`) have additional events that the
server can send ahead of "configure", to make each of the suggestions we've
mentioned so far. The server will send all of this state; maximized, focused,
a suggested size; then a `configure` event with a serial. When the client has
assumed a state consistent with these suggestions, it sends an `ack_configure`
request with the same serial to indicate this. Upon the next commit to the
associated `wl_surface`, the compositor will consider the state consistent.

For `xdg_toplevel`, the kind of surface we've already seen in previous chapters,
the following events can be sent by the server as part of this process:

```xml
<event name="configure">
  <arg name="width" type="int"/>
  <arg name="height" type="int"/>
  <arg name="states" type="array"/>
</event>
```

The width and height are the compositor's preferred size for the window[^1], and
states is an array of the following values:

```xml
<enum name="state">
  <entry name="maximized" />
  <entry name="fullscreen" />
  <entry name="resizing" />
  <entry name="activated" />
  <entry name="tiled_left" />
  <entry name="tiled_right" />
  <entry name="tiled_top" />
  <entry name="tiled_bottom" />
</enum>
```

The client can also request that the compositor put the client into one of these
states, or place constraints on the size of the window.

```xml
<request name="set_max_size">
  <arg name="width" type="int"/>
  <arg name="height" type="int"/>
</request>

<request name="set_min_size">
  <arg name="width" type="int"/>
  <arg name="height" type="int"/>
</request>

<request name="set_maximized" />

<request name="unset_maximized" />

<request name="set_fullscreen" />
  <arg name="output"
    type="object"
    interface="wl_output"
    allow-null="true"/>
</request>

<request name="unset_fullscreen" />

<request name="set_minimized" />
```

There's one more event that the server can send your client to influence its
lifecycle:

```xml
<event name="close" />
```

This one is sent when the user is sick of you minimizing and maximizing and
fullscreening your window so much. You may interpret it in any way you wish -
ignore it, show a window prompting them to save their work, and so on - but
beware, if you ignore it you might have a SIGKILL coming your way soon.

[^1]: This takes into account the window geometry sent by the `set_window_geometry` request from the client. The suggested size only includes the space represented by the window geometry.
