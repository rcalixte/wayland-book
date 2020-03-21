# Pointer input

Using the `wl_seat.get_pointer` request, clients may obtain a `wl_pointer`
object. The server will send events to it whenever the user moves their pointer,
presses mouse buttons, uses the scroll wheel, etc &mdash; whenever the pointer
is over one of your surfaces. We can determine if this condition is met with the
`wl_pointer.enter` event:

```xml
<event name="enter">
  <arg name="serial" type="uint" />
  <arg name="surface" type="object" interface="wl_surface" />
  <arg name="surface_x" type="fixed" />
  <arg name="surface_y" type="fixed" />
</event>
```

The server sends this event when the pointer moves over one of our surfaces, and
specifies both the surface that was "entered", as well as the surface-local
coordinates (from the top-left corner) that the pointer is positioned over.
Coordinates here are specified with the "fixed" type, which you may remember
from chapter 2.1 represents a 24.8-bit fixed-precision number
(`wl_fixed_to_double` will convert this to C's `double` type).

When the pointer is moved away from your surface, the corresponding event is
more brief:

```xml
<event name="leave">
  <arg name="serial" type="uint" />
  <arg name="surface" type="object" interface="wl_surface" />
</event>
```

Once a pointer has entered your surface, you'll start receiving additional
events for it, which we'll discuss shortly. The first thing you will likely want
to do, however, is provide a cursor image. The process is as such:

1. Create a new `wl_surface` with the `wl_compositor`.
2. Use `wl_pointer.set_cursor` to attach that surface to the pointer.
3. Attach a cursor image `wl_buffer` to the surface and commit it.

The only new API introduced here is `wl_pointer.set_cursor`:

```xml
<request name="set_cursor">
  <arg name="serial" type="uint" />
  <arg name="surface" type="object" interface="wl_surface" allow-null="true" />
  <arg name="hotspot_x" type="int" />
  <arg name="hotspot_y" type="int" />
</request>
```

The `serial` here has to come from the `enter` event. The `hotspot_x` and
`hotspot_y` arguments specify the cursor-surface-local coordinates of the
"hotspot", or the effective position of the pointer within the cursor image
(e.g. at the tip of an arrow). Note also that the surface can be null &mdash;
use this to hide the cursor entirely.

If you're looking for a good source of cursor images, libwayland ships with a
separate `wayland-cursor` library, which can load X cursor themes from disk and
create `wl_buffers` for them. See `wayland-cursor.h` for details, or the updates
to our example client in chapter 9.5.

<small>
  <em>
    Note: wayland-cursor includes code for dealing with animated cursors, which
    weren't even cool in 1998. If I were you, I wouldn't bother with that.  No
    one has ever complained that my Wayland clients don't support animated
    cursors.
  </em>
</small>

After the cursor has entered your surface and you have attached an appropriate
cursor, you're ready to start processing input events. There are motion, button,
and axis events.

## Pointer frames

A single frame of input processing on the server could carry information about
lots of changes &mdash; for example, polling the mouse once could return, in a
single packet, an updated position and the release of a button. The server sends
these changes as separate *Wayland* events, and uses the "frame" event to group
them together.

```
<event name="frame"></event>
```

Clients should accumulate all `wl_pointer` events as they're received, then
process pending inputs as a single pointer event once the "frame" event is
received.

## Motion events

Motion events are specified in the same coordinate space as the `enter` event
uses, and are straightforward enough:

```xml
<event name="motion">
  <arg name="time" type="uint" />
  <arg name="surface_x" type="fixed" />
  <arg name="surface_y" type="fixed" />
</event>
```

Like all input events which include a timestamp, the `time` value is a
monotonically increasing millisecond-precision timestamp associated with this
input event.

## Button events

Button events are mostly self-explanatory:

```xml
<enum name="button_state">
  <entry name="released" value="0" />
  <entry name="pressed" value="1" />
</enum>

<event name="button">
  <arg name="serial" type="uint" />
  <arg name="time" type="uint" />
  <arg name="button" type="uint" />
  <arg name="state" type="uint" enum="button_state" />
</event>
```

However, the `button` argument merits some additional explanation. This number
is a platform-specific input event, though note that FreeBSD reuses the Linux
values. You can find these values for Linux in `linux/input-event-codes.h`, and
the most useful ones will probably be represented by the constants `BTN_LEFT`,
`BTN_RIGHT`, and `BTN_MIDDLE`. There are more, I'll leave you to peruse the
header at your leisure.

## Axis events

The axis event is used for scrolling actions, such as rotating your scroll wheel
or rocking it from left to right. The most basic form looks like this:

```xml
<enum name="axis">
  <entry name="vertical_scroll" value="0" />
  <entry name="horizontal_scroll" value="1" />
</enum>

<event name="axis">
  <arg name="time" type="uint" />
  <arg name="axis" type="uint" enum="axis" />
  <arg name="value" type="fixed" />
</event>
```

However, axis events are complex, and this is the part of the `wl_pointer`
interface which has received the most attention over the years. Several
additional events exist which increase the specificity of the axis event:

```xml
<enum name="axis_source">
  <entry name="wheel" value="0" />
  <entry name="finger" value="1" />
  <entry name="continuous" value="2" />
  <entry name="wheel_tilt" value="3" />
</enum>

<event name="axis_source" since="5">
  <arg name="axis_source" type="uint" enum="axis_source" />
</event>
```

The axis_source event tells you what kind of axis was actuated - a scroll wheel,
or a finger on a touchpad, tilting a rocker to the side, or something more
novel. This event is simple, but the remainder are less so:

```xml
<event name="axis_stop" since="5">
  <arg name="time" type="uint" />
  <arg name="axis" type="uint" enum="axis" />
</event>

<event name="axis_discrete" since="5">
  <arg name="axis" type="uint" enum="axis" />
  <arg name="discrete" type="int" />
</event>
```

The precise semantics of these two events are complex, and if you wish to
leverage them I recommend a careful reading of the summaries in `wayland.xml`.
In short, the `axis_discrete` event is used to disambiguate axis events on an
arbitrary scale from discrete steps of, for example, a scroll wheel where each
"click" of the wheel represents a single discrete change in the axis value.  The
`axis_stop` event signals that a discrete user motion has completed, and is used
when accounting for a scrolling event which takes place over several frames. Any
future events should be interpreted as a separate motion.
