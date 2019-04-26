# Protocol design

The Wayland protocol is built from several layers of abstraction. It starts with
a basic wire protocol format, which is a stream of data which is decoded based
on a interfaces which are agreed upon in advance by both parties. Then we have
the higher level procedure for enumerating interfaces, creating resources which
conform to these interfaces, and exchanging messages about them - Wayland
protocols. On top of this we have some broader patterns which are frequently
used in Wayland protocol design.

Let's work our way from the bottom-up.
