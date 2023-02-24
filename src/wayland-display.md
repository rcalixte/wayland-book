# The Wayland display

Up to this point, we've left a crucial detail out of our explanation of how the
Wayland protocol manages joint ownership over objects between the client and
server: how those objects are created in the first place. The Wayland display,
or `wl_display`, implicitly exists on every Wayland connection. It has the
following interface:

```xml
<interface name="wl_display" version="1">
  <request name="sync">
    <arg name="callback" type="new_id" interface="wl_callback"
       summary="callback object for the sync request"/>
  </request>

  <request name="get_registry">
    <arg name="registry" type="new_id" interface="wl_registry"
      summary="global registry object"/>
  </request>

  <event name="error">
    <arg name="object_id" type="object" summary="object where the error occurred"/>
    <arg name="code" type="uint" summary="error code"/>
    <arg name="message" type="string" summary="error description"/>
  </event>

  <enum name="error">
    <entry name="invalid_object" value="0" />
    <entry name="invalid_method" value="1" />
    <entry name="no_memory" value="2" />
    <entry name="implementation" value="3" />
  </enum>

  <event name="delete_id">
    <arg name="id" type="uint" summary="deleted object ID"/>
  </event>
</interface>
```

The most interesting of these for the average Wayland user is `get_registry`,
which we'll talk about in detail in the following chapter. In short, the
registry is used to allocate other objects. The rest of the interface is used
for housekeeping on the connection, and are generally not important unless
you're writing your own libwayland replacement.

Instead, this chapter will focus on a number of functions that libwayland
associates with the `wl_display` object, for establishing and maintaining your
Wayland connection. These are used to manipulate libwayland's internal state,
rather than being directly related to wire protocol requests and events.

We'll start with the most important of these functions: establishing the
display. For clients, this will cover the actual process of connecting to the
server, and for servers, the process of configuring a display for clients to
connect to.
