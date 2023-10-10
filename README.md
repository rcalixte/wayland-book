# WAYLAND BOOK

This repository is a clone of the repository for [Wayland Book](https://wayland-book.com/), located at
[~sircmpwn/wayland-book](https://git.sr.ht/~sircmpwn/wayland-book).

The original author of this work is [Drew DeVault](https://github.com/ddevault).

## GENERATING A PDF

Every commit or push to the master branch will generate a PDF that can then be
downloaded under the Releases tab. There are two local scripts available if
that is preferred as well.

The PDF can also be generated on a local client by cloning this repository and
running `pandoc.sh` in a shell, assuming the dependencies below are installed
locally and accessible.

The `pandoc-docker.sh` script can be used with the [pandoc/latex Docker images](https://hub.docker.com/r/pandoc/latex)
to similarly generate the same output PDF as the one in the Releases tab.

## DEPENDENCIES

The local execution of the script depends on two packages being installed:

- pandoc
- tex

Check with your distribution for how to install those packages.

## CONTRIBUTING

All issues to report or contributions to be made should be done upstream at the
source content repository linked above. This repository will then be rebased so
that a new PDF can be generated with the changes. The only exception would be
the case where something specific to the PDF generation should be addressed.
