#!/bin/sh

#pacman -S bzr bzr-fastimport git

# bzr-fastimport is not available in 16.04:
# http://archive.ubuntu.com/ubuntu/pool/universe/b/bzr-fastimport/bzr-fastimport_0.13.0+bzr361-1ubuntu1_all.deb

git clone https://github.com/darealshinji/qpdfview
cd qpdfview
bzr branch lp:qpdfview
bzr fast-export --plain qpdfview | git fast-import
git checkout -f master 2>/dev/null
rm -rf qpdfview

#git push origin `git tag | tr '\n' ' '`

