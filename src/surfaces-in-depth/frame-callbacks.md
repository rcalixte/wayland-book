# Frame callbacks

The simplest way to update your surface is to simply render and attach new
frames when it needs to change. This approach works well, for example, with
event-driven applications. The user presses a key and the textbox needs to be
re-rendered, so you can just re-render it immediately, damage the appropriate
area, and attach a new buffer to be presented on the next frame.

However, some applications may want to render frames continuously. You might be
rendering frames of a video game, playing back a video, or rendering an
animation. Your display has an inherent *refresh rate*, or the fastest rate at
which it's able to display updates (generally this is a number like 60 Hz, 144
Hz, etc). It doesn't make sense to render frames any faster than this, and doing
so would be a waste of resources - CPU, GPU, even the user's battery. If you
send several frames between each display refresh, all but the last will be
discarded and have been rendered for naught.

Additionally, the compositor might not even want to show new frames for you.
Your application might be off-screen, minimized, or hidden behind other windows;
or only a small thumbnail of your application is being shown, so they might want
to render you at a slower framerate to conserve resources. For this reason, the
best way to continuously render frames in a Wayland client is to let the
compositor tell you when it's ready for a new frame: using *frame callbacks*.

```xml
<interface name="wl_surface" version="4">
  <!-- ... -->

  <request name="frame">
    <arg name="callback" type="new_id" interface="wl_callback" />
  </request>

  <!-- ... -->
</interface>
```

This request will allocate a `wl_callback` object, which has a pretty simple
interface:

```xml
<interface name="wl_callback" version="1">
  <event name="done">
    <arg name="callback_data" type="uint" />
  </event>
</interface>
```

When you request a frame callback on a surface, the compositor will send a
`done` event to the callback object once it's ready for a new frame for this
surface. In the case of `frame` events, the `callback_data` is set to the
current time in millisecond, from an unspecified epoch. You can compare this
with your last frame to calculate the progress of an animation or to scale input
events.[^1]

With frame callbacks in our toolbelt, why don't we update our application from
chapter 7.2 so it scrolls a bit each frame? Let's start by adding a little bit
of state to our `client_state` struct:

```diff
--- a/client.c
+++ b/client.c
@@ -71,6 +71,8 @@ struct client_state {
 	struct xdg_toplevel *xdg_toplevel;
 	/* State */
 	bool closed;
+	float offset;
+	uint32_t last_frame;
 };
 
 static void wl_buffer_release(void *data, struct wl_buffer *wl_buffer) {
```

Then we'll update our `draw_frame` function to take the offset into account:

```diff
@@ -107,9 +109,10 @@ draw_frame(struct client_state *state)
 	close(fd);
 
 	/* Draw checkerboxed background */
+	int offset = (int)state->offset % 8;
 	for (int y = 0; y < height; ++y) {
 		for (int x = 0; x < width; ++x) {
-			if ((x + y / 8 * 8) % 16 < 8)
+			if (((x + offset) + (y + offset) / 8 * 8) % 16 < 8)
 				data[y * width + x] = 0xFF666666;
 			else
 				data[y * width + x] = 0xFFEEEEEE;
```

In the `main` function, let's register a callback for our first new frame:

```diff
@@ -195,6 +230,9 @@ main(int argc, char *argv[])
 	xdg_toplevel_set_title(state.xdg_toplevel, "Example client");
 	wl_surface_commit(state.wl_surface);
 
+	struct wl_callback *cb = wl_surface_frame(state.wl_surface);
+	wl_callback_add_listener(cb, &wl_surface_frame_listener, &state);
+
 	while (wl_display_dispatch(state.wl_display) && !state.closed) {
 		/* This space deliberately left blank */
 	}
```

Then implement it like so:

```diff
@@ -147,6 +150,38 @@ const static struct xdg_wm_base_listener xdg_wm_base_listener = {
 	.ping = xdg_wm_base_ping,
 };
 
+const static struct wl_callback_listener wl_surface_frame_listener;
+
+static void
+wl_surface_frame_done(void *data, struct wl_callback *cb, uint32_t time)
+{
+	/* Destroy this callback */
+	wl_callback_destroy(cb);
+
+	/* Request another frame */
+	struct client_state *state = data;
+	cb = wl_surface_frame(state->wl_surface);
+	wl_callback_add_listener(cb, &wl_surface_frame_listener, state);
+
+	/* Update scroll amount at 8 pixels per second */
+	if (state->last_frame != 0) {
+		int elapsed = time - state->last_frame;
+		state->offset += elapsed / 1000.0 * 24;
+	}
+
+	/* Submit a frame for this event */
+	struct wl_buffer *buffer = draw_frame(state);
+	wl_surface_attach(state->wl_surface, buffer, 0, 0);
+	wl_surface_damage_buffer(state->wl_surface, 0, 0, INT32_MAX, INT32_MAX);
+	wl_surface_commit(state->wl_surface);
+
+	state->last_frame = time;
+}
+
+const static struct wl_callback_listener wl_surface_frame_listener = {
+	.done = wl_surface_frame_done,
+};
+
 static void
 registry_global(void *data, struct wl_registry *wl_registry,
 		uint32_t name, const char *interface, uint32_t version)
```

Now, with each frame, we'll

1. Destroy the now-used frame callback.
2. Request a new callback for the next frame.
3. Render and submit the new frame.

The third step, broken down, is:

1. Update our state with a new offset, using the time since the last frame to
   scroll at a consistent rate.
2. Prepare a new `wl_buffer` and render a frame for it.
3. Attach the new `wl_buffer` to our surface.
4. Damage the entire surface.
5. Commit the surface.

Steps 3 and 4 update the *pending* state for the surface, giving it a new buffer
and indicating the entire surface has changed. Step 5 commits this pending
state, applying it to the surface's current state, and using it on the following
frame. Applying this new buffer atomically means that we never show half of the
last frame, resulting in a nice tear-free experience. Compile and run the
updated client to try it out for yourself!

[^1]: Want something more accurate? In chapter 12.1 we talk about a protocol extension which tells you with nanosecond resolution exactly when each frame was presented to the user.
