# XDG shell basics

The XDG (cross-desktop group) shell is a standard protocol extension for Wayland
which describes the semantics for application windows. It defines two
`wl_surface` roles: "toplevel", for your top-level application windows, and
"popup", for things like context menus, dropdown menus, tooltips, and so on -
which are children of top-level windows. With these together, you can form a
tree of surfaces, with a toplevel at the top and popups or additional toplevels
at the leaves. The protocol also defines a *positioner* interface, which is used
for help positioning popups with limited information about the things around
your window.

xdg-shell, as a protocol *extension*, is not defined in `wayland.xml`. Instead
you'll find it in the `wayland-protocols` package. It's probably installed at a
path somewhat like `/usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml`
on your system.

## xdg_wm_base

`xdg_wm_base` is the only global defined by the specification, and it provides
requests for creating each of the other objects you need. The most basic
implementation starts by handling the "ping" event - when the compositor sends
it, you should respond with a "pong" request in a timely manner to hint that you
haven't become deadlocked. Another request deals with the creation of
positioners, the objects mentioned earlier, and we'll save the details on these
for chapter 9. The request we want to look into first is `get_xdg_surface`.
