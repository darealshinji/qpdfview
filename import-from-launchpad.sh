#!/bin/sh

#pacman -S bzr bzr-fastimport git

bzr branch lp:qpdfview
cd qpdfview
git init
bzr fast-export --plain . | git fast-import
git checkout -f master 2>/dev/null
rm -rf .bzr

#git remote add origin https://github.com/darealshinji/qpdfview.git
#git push -u origin master
#git push origin qpdfview-0.4.16

