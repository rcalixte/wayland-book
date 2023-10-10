## Configuration & lifecycle

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

### XDG top-level lifecycle

Our example code from chapter 7 works, but it's not the best citizen of the
desktop right now. It does not assume the compositor's recommended size, and if
the user tries to close the window, it won't go away. Responding to these
compositor-supplied events implicates two Wayland events: `configure` and
`close`.

```xml
<event name="configure">
  <arg name="width" type="int"/>
  <arg name="height" type="int"/>
  <arg name="states" type="array"/>
</event>

<event name="close" />
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

The close event can be ignored, a typical reason being to show the user a
confirmation to save their unsaved work. Our example code from chapter 7 can be
updated fairly easily to support these events:

```diff
diff --git a/client.c b/client.c
--- a/client.c
+++ b/client.c
@@ -70,9 +70,10 @@ struct client_state {
 	struct xdg_surface *xdg_surface;
 	struct xdg_toplevel *xdg_toplevel;
 	/* State */
-	bool closed;
 	float offset;
 	uint32_t last_frame;
+	int width, height;
+	bool closed;
 };
 
 static void wl_buffer_release(void *data, struct wl_buffer *wl_buffer) {
@@ -86,7 +87,7 @@ static const struct wl_buffer_listener wl_buffer_listener = {
 static struct wl_buffer *
 draw_frame(struct client_state *state)
 {
-	const int width = 640, height = 480;
+	int width = state->width, height = state->height;
 	int stride = width * 4;
 	int size = stride * height;
 
@@ -124,6 +125,32 @@ draw_frame(struct client_state *state)
 	return buffer;
 }
 
+static void
+xdg_toplevel_configure(void *data,
+		struct xdg_toplevel *xdg_toplevel, int32_t width, int32_t height,
+		struct wl_array *states)
+{
+	struct client_state *state = data;
+	if (width == 0 || height == 0) {
+		/* Compositor is deferring to us */
+		return;
+	}
+	state->width = width;
+	state->height = height;
+}
+
+static void
+xdg_toplevel_close(void *data, struct xdg_toplevel *toplevel)
+{
+	struct client_state *state = data;
+	state->closed = true;
+}
+
+static const struct xdg_toplevel_listener xdg_toplevel_listener = {
+	.configure = xdg_toplevel_configure,
+	.close = xdg_toplevel_close,
+};
+
 static void
 xdg_surface_configure(void *data,
 		struct xdg_surface *xdg_surface, uint32_t serial)
@@ -163,7 +190,7 @@ wl_surface_frame_done(void *data, struct wl_callback *cb, uint32_t time)
 	cb = wl_surface_frame(state->wl_surface);
 	wl_callback_add_listener(cb, &wl_surface_frame_listener, state);
 
-	/* Update scroll amount at 8 pixels per second */
+	/* Update scroll amount at 24 pixels per second */
 	if (state->last_frame != 0) {
 		int elapsed = time - state->last_frame;
 		state->offset += elapsed / 1000.0 * 24;
@@ -217,6 +244,8 @@ int
 main(int argc, char *argv[])
 {
 	struct client_state state = { 0 };
+	state.width = 640;
+	state.height = 480;
 	state.wl_display = wl_display_connect(NULL);
 	state.wl_registry = wl_display_get_registry(state.wl_display);
 	wl_registry_add_listener(state.wl_registry, &wl_registry_listener, &state);
@@ -227,6 +256,8 @@ main(int argc, char *argv[])
 			state.xdg_wm_base, state.wl_surface);
 	xdg_surface_add_listener(state.xdg_surface, &xdg_surface_listener, &state);
 	state.xdg_toplevel = xdg_surface_get_toplevel(state.xdg_surface);
+	xdg_toplevel_add_listener(state.xdg_toplevel,
+			&xdg_toplevel_listener, &state);
 	xdg_toplevel_set_title(state.xdg_toplevel, "Example client");
 	wl_surface_commit(state.wl_surface);
 
```

If you compile and run this client again, you'll notice that it's a lot more
well-behaved than before.

### Requesting state changes

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

The compositor indicates its acknowledgement of these requests by sending a
corresponding configure event.

[^1]: This takes into account the window geometry sent by the `set_window_geometry` request from the client. The suggested size only includes the space represented by the window geometry.
