# Surface regions

We've already used the `wl_compositor` interface to create `wl_surfaces` via
`wl_compositor.create_surface`. Note, however, that it has a second request:
`create_region`.

```xml
<interface name="wl_compositor" version="4">
  <request name="create_surface">
    <arg name="id" type="new_id" interface="wl_surface" />
  </request>

  <request name="create_region">
    <arg name="id" type="new_id" interface="wl_region" />
  </request>
</interface>
```

The `wl_region` interface defines a group of rectangles, which collectively make
up an arbitrarily shaped region of geometry. Its requests allow you to do
bitwise operations against the geometry it defines by adding or subtracting
rectangles from it>

```xml
<interface name="wl_region" version="1">
  <request name="destroy" type="destructor" />

  <request name="add">
    <arg name="x" type="int" />
    <arg name="y" type="int" />
    <arg name="width" type="int" />
    <arg name="height" type="int" />
  </request>

  <request name="subtract">
    <arg name="x" type="int" />
    <arg name="y" type="int" />
    <arg name="width" type="int" />
    <arg name="height" type="int" />
  </request>
</interface>
```

To make, for example, a rectangle with a hole in it, you could:

1. Send `wl_compositor.create_region` to allocate a `wl_region` object.
2. Send `wl_region.add(0, 0, 512, 512)` to create a 512x512 rectangle.
3. Send `wl_region.subtract(128, 128, 256, 256)` to remove a 256x256 rectangle
   from the middle of the region.

These areas can be disjoint as well; it needn't be a single continuous polygon.
Once you've created one of these regions, you can pass it into the `wl_surface`
interface, namely with the `set_opaque_region` and `set_input_region` requests.

```xml
<interface name="wl_surface" version="4">
  <request name="set_opaque_region">
    <arg name="region" type="object" interface="wl_region" allow-null="true" />
  </request>

  <request name="set_input_region">
    <arg name="region" type="object" interface="wl_region" allow-null="true" />
  </request>
</interface>
```

The opaque region is a hint to the compositor as to which parts of your surface
are considered opaque. Based on this information, they can optimize their
rendering process. For example, if your surface is completely opaque and
occludes another window beneath it, then the compositor won't waste any time on
redrawing the window beneath yours. By default, this is empty, which assumes
that any part of your surface might be transparent. This makes the default case
the least efficient but the most correct.

The input region indicates which parts of your surface accept pointer and touch
input events. You might, for example, draw a drop-shadow underneath your
surface, but input events which happen in this region should be passed to the
client beneath you. Or, if your window is an unusual shape, you could create an
input region in that shape. For most surface types by default, your entire
surface accepts input.

Both of these requests can be used to set an empty region by passing in null
instead of a `wl_region` object. They're also both double-buffered - so send a
`wl_surface.commit` to make your changes effective. You can destroy the
`wl_region` object to free up its resources as soon as you've sent the
`set_opaque_region` or `set_input_region` requests with it. Updating the region
after you send these requests will not update the state of the surface.
