#!/bin/sh
set -e
set -x

# required packages: bzr bzr-fastimport git

git clone --branch master https://github.com/darealshinji/qpdfview
cd qpdfview
bzr branch lp:qpdfview
bzr fast-export --plain qpdfview | git fast-import
git checkout -f master 2>/dev/null
rm -rf qpdfview
#git push origin master
#git push origin $(git tag | tr '\n' ' ')
