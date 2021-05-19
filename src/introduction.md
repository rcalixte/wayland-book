# Introduction

Wayland is the next-generation display server for Unix-like systems, designed
and built by the alumni of the venerable Xorg server, and is the best way to get
your application windows onto your user's screens. Readers who have worked with
X11 in the past will be pleasantly surprised by Wayland's improvements, and
those who are new to graphics on Unix will find it a flexible and powerful
system for building graphical applications and desktops.

This book will help you establish a firm understanding of the concepts, design,
and implementation of Wayland, and equip you with the tools to build your own
Wayland client and server applications. Over the course of your reading, we'll
build a mental model of Wayland and establish the rationale that went into its
design. Within these pages you should find many "aha!" moments as the intuitive
design choices of Wayland become clear, which should help to keep the pages
turning. Welcome to the future of open source graphics!

**Notice**: this is a *draft*. Chapters 1-10 are more or less complete, but may
be updated later. Chapters 11 forward in large part remain to be written.

**TODO**

- Expand on resource lifetimes and avoiding race conditions in chapter 2.4
- Move linux-dmabuf details to the appendix, add note about wl_drm & Mesa
- Rewrite the introduction text
- Add example code for interactive move, to demonstrate the use of serials
- Prepare PDFs and EPUBs

## About the book

This work is licensed under a <a rel="license"
href="http://creativecommons.org/licenses/by-sa/4.0/">Creative Commons
Attribution-ShareAlike 4.0 International License</a>. The source code is
[available here][source].

<a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-sa/4.0/88x31.png" /></a>

[source]: https://git.sr.ht/~sircmpwn/wayland-book

## About the author

<small>
  In the words of Preston Carpenter, a close collaborator of Drew's:
</small>

Drew DeVault got his start in the Wayland world by building sway, a clone of the
popular tiling window manager i3. It is now the most popular tiling Wayland
compositor by any measure: users, commit count, and influence. Following its
success, Drew gave back to the Wayland community by starting wlroots:
unopinionated, composable modules for building a Wayland compositor. Today it is
the foundation for dozens of independent compositors, and Drew is one of the
foremost experts in Wayland.
