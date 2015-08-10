#!/bin/sh

cd home/pi/destinationmetricsv2/Programability/Pi

git fetch origin
reslog=$(git log HEAD origin/master --oneline)

if [ "${reslog}" != "" ] ; then
  git merge origin/master # completing the pull
fi
