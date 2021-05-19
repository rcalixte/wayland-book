# The libwayland implementation

We spoke briefly about libwayland in chapter 1.3 &mdash; the most popular 
Wayland implementation. Much of this book is applicable to any implementation,
but we're going to spend the next two chapters familiarizing you with this one.

The Wayland package includes pkg-config specs for wayland-client and
wayland-server &mdash; consult your build system's documentation for 
instructions on linking with them. Naturally, most applications will only link
to one or the other. The library includes a few simple primitives (such as a
linked list) and a pre-compiled version of `wayland.xml` &mdash; the core
Wayland protocol.

We'll start by introducing the primitives.
