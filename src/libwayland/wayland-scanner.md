# wayland-scanner

The Wayland package comes with one binary: `wayland-scanner`. This tool is used
to generate C headers & glue code from the Wayland protocol XML files discussed
in chapter 2.3. This tool is used in the "wayland" package's build process to
pre-generate headers & glue code for the core protocol, `wayland.xml`. The
headers become `wayland-client-protocol.h` and `wayland-server-protocol.h` -
though you normally include `wayland-client.h` and `wayland-server.h` instead of
using these directly.

The usage of this tool is fairly simple (and summarized by `wayland-scanner
-h`), but can be summed up as follows. To generate a client header:

    wayland-scanner client-header < protocol.xml > protocol.h

To generate a server header:

    wayland-scanner server-header < protocol.xml > protocol.h

And to generate the glue code:

    wayland-scanner private-code < protocol.xml > protocol.c

Different build systems will have different approaches to configuring custom
commands - consult your build system's docs. Generally speaking, you'll want to
run `wayland-scanner` at build time, then compile and link your application to
the glue code.

Go ahead and do this with any Wayland protocol now, if you have one handy
(`wayland.xml` is probably available in `/usr/share/wayland`, for example). Open
up the glue code & header and consult it as you read the following chapters, to
understand how the primitives offered by libwayland are applied in practice in
the generated code.
