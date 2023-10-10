## Popups

When designing software which utilizes application windows, there are many cases
where smaller secondary surfaces are used for various purposes. Some examples
include context menus which appear on right click, dropdown boxes to select a
value from several options, contextual hints which are shown when you hover the
mouse over a UI element, or menus and toolbars along the top and bottom of a
window. Often these will be nested, for example, by following a path like "File
→ Recent Documents → Example.odt".

For Wayland, the XDG shell provides facilities for managing these windows:
popups. We looked at `xdg_surface`'s "`get_toplevel`" request for creating
top-level application windows earlier. In the case of popups, the "`get_popup`"
request is used instead.

```xml
<request name="get_popup">
  <arg name="id" type="new_id" interface="xdg_popup"/>
  <arg name="parent" type="object" interface="xdg_surface" allow-null="true"/>
  <arg name="positioner" type="object" interface="xdg_positioner"/>
</request>
```

The first and second arguments are reasonably self-explanatory, but the third
one introduces a new concept: positioners. The purpose of the positioner is, as
the name might suggest, to *position* the new popup. This is used to allow the
compositor to participate in the positioning of popups using its privileged
information, for example to avoid having the popup extend past the edge of the
display. We'll discuss positioners in chapter 10.4, for now you can simply create
one and pass it in without further configuration to achieve reasonably sane
default behavior, utilizing the appropriate `xdg_wm_base` request:

```xml
<request name="create_positioner">
  <arg name="id" type="new_id" interface="xdg_positioner"/>
</request>
```

So, in short, we can:

1. Create a new `wl_surface`
2. Obtain an `xdg_surface` for it
3. Create a new `xdg_positioner`, saving its configuration for chapter 10.4
4. Create an `xdg_popup` from our XDG surface and XDG positioner, assigning its
   parent to the `xdg_toplevel` we created earlier.

Then we can render and attach buffers to our popup surface with the same
lifecyle discussed earlier. We also have access to a few other popup-specific
features.

### Configuration

Like the XDG toplevel configure event, the compositor has an event which it may
use to suggest the size for your popup to assume. Unlike toplevels, however,
this also includes a positioning event, which informs the client as to the
position of the popup relative to its parent surface.

```xml
<event name="configure">
  <arg name="x" type="int"
 summary="x position relative to parent surface window geometry"/>
  <arg name="y" type="int"
 summary="y position relative to parent surface window geometry"/>
  <arg name="width" type="int" summary="window geometry width"/>
  <arg name="height" type="int" summary="window geometry height"/>
</event>
```

The client can influence these values with the XDG positioner, to be discussed
in chapter 10.4.

### Popup grabs

Popup surfaces will often want to "grab" all input, for example to allow the
user to use the arrow keys to select different menu items. This is facilitated
through the grab request:

```xml
<request name="grab">
  <arg name="seat" type="object" interface="wl_seat" />
  <arg name="serial" type="uint" />
</request>
```

A prerequisite of this request is having received a qualifying input event, such
as a right click. The serial from this input event should be used in this
request. These semantics are covered in detail in chapter 9. The compositor can
cancel this grab later, for example if the user presses escape or clicks outside
of your popup.

### Dismissal

In these cases where the compositor dismisses your popup, such as when the
escape key is pressed, the following event is sent:

```xml
<event name="popup_done" />
```

To avoid race conditions, the compositor keeps the popup structures in memory
and services requests for them even after their dismissal. For more detail about
object lifetimes and race conditions, see chapter 2.4.

### Destroying popups

Client-initiated destruction of a popup is fairly straightforward:

```xml
<request name="destroy" type="destructor" />
```

However, one detail bears mentioning: you must destroy all popups from the
top-down. The only popup you can destroy at any given moment is the top-most
one. If you don't, you'll be disconnected with a protocol error.
