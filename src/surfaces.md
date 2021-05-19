# Buffers & surfaces

Apparently, the whole point of this system is to display information to users
and receive their feedback for additional processing. In this chapter, we'll
explore the first of these tasks: showing pixels on the screen.

There are two primitives which are used for this purpose: buffers and surfaces,
governed respectively by the `wl_buffer` and `wl_surface` interfaces. Buffers
act as an opaque container for some underlying pixel storage, and are supplied
by clients with a number of methods &mdash; shared memory buffers and GPU 
handles being the most common.
