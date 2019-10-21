# XDG shell in depth

So far we've managed to display something on-screen in a top-level application
window, but there's more to XDG shell that we haven't fully appreciated yet.
Even the simplest application would be well-served to implement the
configuration lifecycle correctly, and xdg-shell offers useful features to more
complex application as well. The full breadth of xdg-shell's feature set
includes client/server negotiation on window size, multi-window hierarchies,
client-side decorations, and semantic positioning for windows like context
menus.

Before we dive in, there are a few xdg-toplevel events which don't really fit in
anywhere else. We'll cover these briefly first:

```xml
<request name="set_title">
  <arg name="title" type="string"/>
</request>
```

This one appeared in chapter 7 quite briefly, and is more or less
self-explanatory. The window title is often shown in the desktop shell, such as
the names of applications in the taskbar.

```xml
<request name="set_app_id">
  <arg name="app_id" type="string"/>
</request>
```

The application ID bears a little more explanation. It's somewhat analogous to
the X11 window class, and for many applications, this can be an arbitrary string
which helps to identify to what group of applications yours belongs. Some
compositors will group together windows by their application ID, and others
disregard it or allow the user to script window behaviors based on it. For
applications which support D-Bus activation, the app ID should be the D-Bus
service name.

Next, let's move on to the simplest and most essential of xdg-shell's features:
the configuration and lifecycle of xdg-shell windows.
