#!/bin/sh

#pacman -S bzr bzr-fastimport git

# bzr-fastimport is not available in 16.04:
# https://packages.ubuntu.com/trusty/bzr-fastimport

git clone https://github.com/darealshinji/qpdfview
cd qpdfview
bzr branch lp:qpdfview
bzr fast-export --plain qpdfview | git fast-import
git checkout -f master 2>/dev/null
rm -rf qpdfview

#git push origin `git tag | tr '\n' ' '`

