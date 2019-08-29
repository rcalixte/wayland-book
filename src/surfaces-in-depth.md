# Surfaces in depth

The basic areas of the surface interface that we've shown until now are
sufficient to present data to the user, but the surface interface offers many
additional requests and events for more efficient use. Many - if not most -
applications do not need to redraw the entire surface each frame. Even deciding
*when* to draw the next frame is best done with the assistance of the
compositor. In this chapter, we'll explore more deeply the various features of
`wl_surface`.
