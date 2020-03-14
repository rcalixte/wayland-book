# Touch input

On the surface, touchscreen input is fairly simple, and your implementation can
be simple as well. However, the protocol offers you a lot of depth, which
applications may take advantage of to provide more nuanced touch-driven gestures
and feedback.

Most touch-screen devices support *multitouch*: they can track multiple
locations where the screen has been touched. Each of these "touch points" is
assigned an ID which is unique among all currently active points where the
screen is being touched, but might be reused if you lift your finger and press
again.[^1]

Like the other input devices, you can obtain a `wl_touch` resource by using
`wl_seat.get_touch`, and you can send a "release" request when you're done with
it.

## Touch frames

Like pointers, a single frame of touch processing on the server could carry
information about lots of changes, but the server sends each change as discrete
Wayland events. The `wl_touch.frame` event is used to group these together.

```
<event name="frame"></event>
```

Clients should accumulate all `wl_touch` events as they're received, then
process pending inputs as a single touch event when the "frame" event is
received.

## Touch and release

The first events we'll look at are "down" and "up", which are respectively
raised when you press your finger against the device, and remove your finger
from the device.

```
<event name="down">
  <arg name="serial" type="uint" />
  <arg name="time" type="uint" />
  <arg name="surface" type="object" interface="wl_surface" />
  <arg name="id" type="int" />
  <arg name="x" type="fixed" />
  <arg name="y" type="fixed" />
</event>

<event name="up">
  <arg name="serial" type="uint" />
  <arg name="time" type="uint" />
  <arg name="id" type="int" />
</event>
```

The "x" and "y" coordinates are fixed-point coordinates in the coordinate space
of the surface which was touched - specified by the "surface" argument. The time
is a monotonically increasing timestamp with an arbitrary epoch, in
milliseconds.[^2] Note also the inclusion of a serial, which can be included in
future requests to associate them with this input event.

## Motion

After you receive a "down" event with a specific touch ID, you will begin to
receive motion events which describe the movement of that touch point across the
device.

```
<event name="motion">
  <arg name="time" type="uint" />
  <arg name="id" type="int" />
  <arg name="x" type="fixed" />
  <arg name="y" type="fixed" />
</event>
```

The "x" and "y" coordinates here are in the relative coordinate space of the
surface which the "enter" event was sent for.

## Guesture cancellation

Touch events often have to meet some threshold before they're recognized as a
gesture. For example, swiping across the screen from left to right could be used
by the Wayland compositor to switch between applications. However, it's not
until some threshold has been crossed &mdash; say, reaching the midpoint of the
screen in a certain amount of time &mdash; that the compositor recognizes this
behavior as a gesture.

Until this threshold is reached, the compositor will be sending normal touch
events for the surface that is being touched. Once the gesture is identified,
the compositor will send a "cancel" event to let you know that the compositor is
taking over.

```
<event name="cancel"></event>
```

When you receive a "cancel" event, all active touch points become invalid.

## Shape and orientation

Some high-end touch hardware is capable of determining more information about
the way the user is interacting with it. For users of suitable hardware and
applications wishing to employ more advanced interactions or touch feedback, the
"shape" and "orientation" events are provided.

```
<event name="shape" since="6">
  <arg name="id" type="int" />
  <arg name="major" type="fixed" />
  <arg name="minor" type="fixed" />
</event>

<event name="orientation" since="6">
  <arg name="id" type="int" />
  <arg name="orientation" type="fixed" />
</event>
```

The "shape" event defines an elliptical approximation of the shape of the object
which is touching the screen, with a major and minor axis represented in units
in the coordinate space of the touched surface. The orientation event rotates
this ellipse by specifying the angle between the major axis and the Y-axis of
the touched surface, in degrees.

[^1]: Emphasis on "might" &mdash; don't make any assumptions based on the repeated use of a touch point ID.
[^2]: This means that separate timestamps can be compared to each other to obtain the time between events, but are not comparible to wall-clock time.
