#!/bin/sh
# Creates a zip file of the release Visor.bundle, which name contains
# the current git revision.


GIT_REV=`git rev-parse --short=4 HEAD`
VERSION=1.5r$GIT_REV


rm -f Visor.*.zip

cd build/Release
zip -r ../../Visor.$VERSION.zip Visor.bundle
cd -
