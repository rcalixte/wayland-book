# Application windows

We have shaved many yaks to get here, but it's time: XDG toplevel is the
interface which we will finally use to display an application window. The XDG
toplevel interface has many requests and events for managing application
windows, including dealing with minimized and maximized states, setting window
titles, and so on. We'll be discussing each part of it in detail in future
chapters, so let's just concern ourselves with the basics now.

Based on our knowledge from the last chapter, we know that we can obtain an
`xdg_surface` from a `wl_surface`, but that it only constitutes the first step:
bringing a surface into the fold of XDG shell. The next step is to turn that XDG
surface into an XDG toplevel &mdash; a "top-level" application window, so named
for its top-level position in the hierarchy of windows and popup menus we will
eventually create with XDG shell. To create one of these, we can use the
appropriate request from the `xdg_surface` interface:

```xml
<request name="get_toplevel">
  <arg name="id" type="new_id" interface="xdg_toplevel"/>
</request>
```

This new `xdg_toplevel` interface puts many requests and events at our disposal
for managing the lifecycle of application windows. Chapter 10 explores these in
depth, but I know you're itching to get something on-screen. If you follow these
steps, handling the `configure` and `ack_configure` riggings for XDG surface
discussed in the previous chapter, and attach and commit a `wl_buffer` to our
`wl_surface`, an application window will appear and present your buffer's
contents to the user. Example code which does just this is provided in the next
chapter. It also leverages one additional XDG toplevel request which we haven't
covered yet:

```xml
<request name="set_title">
  <arg name="title" type="string"/>
</request>
```

This should be fairly self-explanatory. There's a similar one that we don't use
in the example code, but which may be appropriate for your application:

```xml
<request name="set_app_id">
  <arg name="app_id" type="string"/>
</request>
```

The title is often shown in window decorations, tasksbars, etc, whereas the app
ID is used to identify your application or group your windows together. You
might utilize these by setting your window title to "Application windows &mdash; 
The Wayland Protocol &mdash; Firefox", and your app ID to "firefox".

In summary, the following steps will take you from zero to a window on-screen:

1. Bind to `wl_compositor` and use it to create a `wl_surface`.
1. Bind to `xdg_wm_base` and use it to create an `xdg_surface` with your
   `wl_surface`.
1. Create an `xdg_toplevel` from the `xdg_surface` with
   `xdg_surface.get_toplevel`.
1. Configure a listener for the `xdg_surface` and await the `configure` event.
1. Bind to the buffer allocation mechanism of your choosing (such as `wl_shm`)
   and allocate a shared buffer, then render your content to it.
1. Use `wl_surface.attach` to attach the `wl_buffer` to the `wl_surface`.
1. Use `xdg_surface.ack_configure`, passing it the serial from `configure`,
   acknowledging that you have prepared a suitable frame.
1. Send a `wl_surface.commit` request.

Turn the page to see these steps in action.
