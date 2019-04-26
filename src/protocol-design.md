# Protocol design

The Wayland protocol is built from several layers of abstraction. It starts with
a basic wire protocol format, which is a stream of messages decodable with
interfaces agreed upon in advance. Then we have higher level procedures for
enumerating interfaces, creating resources which conform to these interfaces,
and exchanging messages about them - the Wayland protocol and its extensions. On
top of this we have some broader patterns which are frequently used in Wayland
protocol design. We'll cover all of these in this chapter.

Let's work our way from the bottom-up.
