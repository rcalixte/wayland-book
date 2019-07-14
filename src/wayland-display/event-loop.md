# Incorporating an event loop

libwayland provides its own event loop implementation for Wayland servers to
take advantage of, but the maintainers have acknowledged this as a design
overstep. For clients, there is no such equivalent. However, the Wayland server
event loop is useful enough, even if it's out-of-scope.

## Wayland server event loop

Each `wl_display` created by libwayland-server has a corresponding
`wl_event_loop`, which you may obtain a reference to with
`wl_display_get_event_loop`. If you're writing a new Wayland compositor, you
will likely want to use this as your only event loop. You can add file
descriptors to it with `wl_event_loop_add_fd`, and timers with
`wl_event_loop_add_timer`. It also handles signals via
`wl_event_loop_add_signal`, which can be pretty convenient.

With the event loop configured to your liking to monitor all of the events your
compositor has to respond to, you can process events and dispatch Wayland
clients all at once by calling `wl_display_run`, which will process the event
loop and block until the display terminates (via `wl_display_terminate`). Most
Wayland compositors which were built from the ground-up with Wayland in mind (as
opposed to being ported from X11) use this approach.

However, it's also possible to take the wheel and incorporate the Wayland
display into your own event loop. `wl_display` uses the event loop internally
for processing clients, and you can choose to either monitor the Wayland event
loop from your own, dispatching it as necessary, or you can disregard it
entirely and manually process client updates. If you wish to allow the Wayland
event loop to look after itself and treat it as subservient to your own event
loop, you can use `wl_event_loop_get_fd` to obtain a [poll][poll]-able file
descriptor, then call `wl_event_loop_dispatch` to process events when activity
occurs on that file descriptor. You will also need to call
`wl_display_flush_clients` when you have data which needs writing to clients.

[poll]: https://pubs.opengroup.org/onlinepubs/009695399/functions/poll.html

## Wayland client event loop

libwayland-client, on the other hand, does not have its own event loop. However,
since there is only generally one file descriptor, it's easier to manage
without. If Wayland events are the only sort which your program expects, then
this simple loop will suffice:

```c
while (wl_display_dispatch(display) != -1) {
    /* This space deliberately left blank */
}
```

However, if you have a more sophisticated application, you can build your own
event loop in any manner you please, and obtain the Wayland display's file
descriptor with `wl_display_get_fd`. Upon `POLLIN` events, call
`wl_display_dispatch` to process incoming events. To flush outgoing requests,
call `wl_display_flush`.

## Almost there!

At this point you have all of the context you need to set up a Wayland
display and process events and requests. The only remaining step is to allocate
objects to chat about with the other side of your connection. For this, we use
the registry. At the end of the next chapter, we will have our first useful
Wayland client!
