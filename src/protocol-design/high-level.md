## The high-level protocol

In chapter 1.3, I mentioned that `wayland.xml` is probably installed with the
Wayland package on your system. Find and pull up that file now in your favorite
text editor. It's through this file, and others like it, that we define the
interfaces supported by a Wayland client or server.

Each interface is defined in this file, along with its requests and events, and
their respective signatures. We use XML, everyone's favorite file format, for
this purpose. Let's look at the examples we discussed in the previous chapter
for `wl_surface`. Here's a sample:

```xml
<interface name="wl_surface" version="4">
  <request name="damage">
    <arg name="x" type="int" />
    <arg name="y" type="int" />
    <arg name="width" type="int" />
    <arg name="height" type="int" />
  </request>

  <event name="enter">
    <arg name="output" type="object" interface="wl_output" />
  </event>
</interface>
```

**Note**: I've trimmed this snippet for brevity, but if you have the
`wayland.xml` file in front of you, seek out this interface and examine it
yourself &mdash; included is additional documentation explaining the purpose and
precise semantics of each request and event.

When processing this XML file, we assign each request and event an opcode in the
order that they appear, numbered from zero and incrementing independently.
Combined with the list of arguments, you can decode the request or event when it
comes in over the wire, and based on the documentation shipped in the XML file
you can decide how to program your software to behave accordingly.  This usually
comes in the form of code generation &mdash; we'll talk about how libwayland
does this in chapter 3.

Starting from chapter 4, most of the remainder of this book is devoted to
explaining this file, as well as some supplementary protocol extensions.
