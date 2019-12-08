# XDG shell in depth

So far we've managed to display something on-screen in a top-level application
window, but there's more to XDG shell that we haven't fully appreciated yet.
Even the simplest application would be well-served to implement the
configuration lifecycle correctly, and xdg-shell offers useful features to more
complex application as well. The full breadth of xdg-shell's feature set
includes client/server negotiation on window size, multi-window hierarchies,
client-side decorations, and semantic positioning for windows like context
menus.
