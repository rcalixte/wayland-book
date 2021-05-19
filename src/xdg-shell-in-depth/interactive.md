# Interactive move and resize

Many application windows have interactive UI elements the user can use to drag
around or resize windows. Many Wayland clients, by default, expect to be
responsible for their own window decorations to provide these interactive
elements. On X11, application windows could position themselves independently
anywhere on the screen, and used this to facilitate these interactions.

However, a deliberate design trait of Wayland makes application windows ignorant
of their exact placement on screen or relative to other windows. This decision
affords Wayland compositors a greater deal of flexibility &mdash; windows could 
be shown in several places at once, arranged in the 3D space of a VR scene, or
presented in any other novel way. Wayland is designed to be generic and widely
applicable to many devices and form factors.

To balance these two design needs, XDG toplevels offer two requests which can be
used to ask the compositor to begin an interactive move or resize operation. The
relevant parts of the interface are:

```xml
<request name="move">
  <arg name="seat" type="object" interface="wl_seat" />
  <arg name="serial" type="uint" />
</request>
```

Like the popup creation request explained in the previous chapter, you have to
provide an input event serial to start an interactive operation. For example,
when you receive a mouse button down event, you can use that event's serial to
begin an interactive move operation. The compositor will take over from here,
and begin an interactive operation to your window in its internal coordinate
space.

Resizing is a bit more complex, due to the need to specify which edges or
corners of the window are implicated in the operation:

```xml
<enum name="resize_edge">
  <entry name="none" value="0"/>
  <entry name="top" value="1"/>
  <entry name="bottom" value="2"/>
  <entry name="left" value="4"/>
  <entry name="top_left" value="5"/>
  <entry name="bottom_left" value="6"/>
  <entry name="right" value="8"/>
  <entry name="top_right" value="9"/>
  <entry name="bottom_right" value="10"/>
</enum>

<request name="resize">
  <arg name="seat" type="object" interface="wl_seat" />
  <arg name="serial" type="uint" />
  <arg name="edges" type="uint" />
</request>
```

But otherwise, it functions much the same. If the user clicks and drags along
the bottom-left corner of your window, you may want to send an interactive
resize request with the corresponding seat & serial, and set the edges argument
to bottom_left.

There's one additional request necessary for clients to totally implement
interactive client-side window decorations:

```xml
<request name="show_window_menu">
  <arg name="seat" type="object" interface="wl_seat" />
  <arg name="serial" type="uint" />
  <arg name="x" type="int" />
  <arg name="y" type="int" />
</request>
```

A contextual menu offering window operations, such as closing or minimizing the
window, is often raised when clicking on window decorations. For clients where
window decorations are managed by the client, this serves to link the
client-driven interactions with compositor-driven meta operations like
minimizing windows. If your client uses client-side decorations, you may use
this request for this purpose.

## xdg-decoration

The last detail which bears mentioning when discussing the behavior of
client-side decorations is the protocol which governs the negotiation of their
use in the first place. Different Wayland clients and servers may have different
preferences about the use of server-side or client-side window decorations. To
express these intentions, a protocol extension is used: `xdg-decoration`. It can
be found in wayland-protocols. The protocol provides a global:

```xml
<interface name="zxdg_decoration_manager_v1" version="1">
  <request name="destroy" type="destructor" />

  <request name="get_toplevel_decoration">
    <arg name="id" type="new_id" interface="zxdg_toplevel_decoration_v1"/>
    <arg name="toplevel" type="object" interface="xdg_toplevel"/>
  </request>
</interface>
```

You may pass your xdg_toplevel object into the `get_toplevel_decoration` request
to obtain an object with the following interface:

```xml
<interface name="zxdg_toplevel_decoration_v1" version="1">
  <request name="destroy" type="destructor" />

  <enum name="mode">
    <entry name="client_side" value="1" />
    <entry name="server_side" value="2" />
  </enum>

  <request name="set_mode">
    <arg name="mode" type="uint" enum="mode" />
  </request>

  <request name="unset_mode" />

  <event name="configure">
    <arg name="mode" type="uint" enum="mode" />
  </event>
</interface>
```

The `set_mode` request is used to express a preference from the client, and
`unset_mode` is used to express no preference. The compositor will then use the
`configure` event to tell the client whether or not to use client-side
decorations. For more details, consult the full XML.
