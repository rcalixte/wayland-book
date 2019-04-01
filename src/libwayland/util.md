# wayland-util primitives

Common to both the client and server libraries is `wayland-util.h`, which
defines a number of structs, utility functions, and macros that establish a
handful of primitives for use in Wayland applications. Among these are:

- Structures for marshalling & unmarshalling Wayland protocol messages in
  generated code
- A linked list (`wl_list`) implementation
- An array (`wl_array`) implementation (rigged up to the
  corresponding Wayland primitive)
- Utilities for conversion between Wayland scalars (such as fixed-point
  numbers) and C types
- Debug logging facilities to bubble up information from libwayland internals

The header contains many comments which document itself. The documentation is
quite good - you should read through the header yourself. We'll go into detail
on how to apply these primitives in the next several pages.
