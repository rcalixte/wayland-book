# Surface roles

We have created a pixel buffer, sent it to the server, and attached it to a
surface through which we can allegedly present it to the user. However, one
crucial piece is missing to imbue the surface with meaning: its role.

There are a lot of different situations where a pixel buffer might be presented
to the user, and each calls for different semantics. Some examples include
application windows, sure, but others include a cursor image or your desktop
wallpaper. To contrast the semantics of application windows with cursors,
consider that your cursor cannot be minimized, and application windows should
not be stuck to the mouse. For this reason, *roles* provide another layer of
abstraction which allows you to assign the appropriate semantics to the surface.

The role you're probably dying to assign to it, 6 chapters in, is an application
window. The following chapter introduces the mechanism by which this is
achieved: XDG shell.
