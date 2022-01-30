# Positioners

When we introduced pop-ups a few pages ago, we noted that you had to provide a
positioner object when creating the pop-up. We asked you not to worry about it
and just use the defaults, because it's a complicated interface and was beside
the point. Now, we'll explore this complex interface in depth.

When you open a pop-up window, it's shown in a windowing system which has
constraints that your client is not privy to. For example, Wayland clients are
unaware of where their windows are being shown on-screen. Therefore, if you
right click a window, the client does not possess the necessary information to
determine that the resulting pop-up might end up running itself off the edge of
the screen. The positioner is designed to address these issues, by letting the
client specify certain constraints in how the pop-up can be moved or resized,
and then the compositor, being in full possession of the facts, can make the
final call on how to accommodate.

# The Basics

```xml
<request name="destroy" type="destructor"></request>
```

This destroys the positioner when you're done with it. You can call this after
your pop-up has been created.

```xml
<request name="set_size">
  <arg name="width" type="int" />
  <arg name="height" type="int" />
</request>
```

The set_size request is used to set the size of the pop-up window being created.

All clients which use a positioner will use these two requests. Now, let's get
to the interesting ones.

# Anchoring

```xml
```
