## Linux dmabuf

<!-- TODO: Move me to an appendix -->

Most Wayland compositors do their rendering on the GPU, and many Wayland clients
do their rendering on the GPU as well. With the shared memory approach, sending
buffers from the client to the compositor in such cases is very inefficient, as
the client has to read their data from the GPU to the CPU, then the compositor
has to read it from the CPU back to the GPU to be rendered.

The Linux DRM (Direct Rendering Manager) interface (which is also implemented on
some BSDs) provides a means for us to export handles to GPU resources. Mesa, the
predominant implementation of userspace Linux graphics drivers, implements a
protocol that allows EGL users to transfer handles to their GPU buffers from the
client to the compositor for rendering, without ever copying data to the CPU.

The internals of how this protocol works are out of scope for this book and
would be more appropriate for resources which focus on Mesa or Linux DRM in
particular. However, we can provide a short summary of its use.

1. Use `eglGetPlatformDisplayEXT` in concert with `EGL_PLATFORM_WAYLAND_KHR` to
   create an EGL display.
2. Configure the display normally, choosing a config appropriate to your
   circumstances with `EGL_SURFACE_TYPE` set to `EGL_WINDOW_BIT`.
3. Use `wl_egl_window_create` to create a `wl_egl_window` for a given
   `wl_surface`.
4. Use `eglCreatePlatformWindowSurfaceEXT` to create an `EGLSurface` for a
   `wl_egl_window`.
5. Proceed using EGL normally, e.g. `eglMakeCurrent` to make current the EGL
   context for your surface and `eglSwapBuffers` to send an up-to-date buffer to
   the compositor and commit the surface.

Should you need to change the size of the `wl_egl_window` later, use
`wl_egl_window_resize`.

### But I really want to know about the internals

Some Wayland programmers who don't use libwayland complain that this approach
ties Mesa and libwayland tightly together, which is true. However, untangling
them is not impossible &mdash; it just requires a lot of work for you in the 
form of implementing `linux-dmabuf` yourself. Consult the Wayland extension XML
for details on the protocol, and Mesa's implementation at
`src/egl/drivers/dri2/platform_wayland.c` (at the time of writing). Good luck
and godspeed.

### For the server

Unfortunately, the details for the compositor are both complicated and
out-of-scope for this book. I can point you in the right direction, however:
the wlroots implementation (found at `types/wlr_linux_dmabuf_v1.c` at the time
of writing) is straightforward and should set you on the right path.
