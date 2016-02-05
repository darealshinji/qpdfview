#!/bin/sh

#pacman -S bzr bzr-fastimport git

git clone https://github.com/darealshinji/qpdfview
cd qpdfview
bzr branch lp:qpdfview
bzr fast-export --plain qpdfview | git fast-import
git checkout -f master 2>/dev/null
rm -rf qpdfview

#git push origin qpdfview-0.4.16

