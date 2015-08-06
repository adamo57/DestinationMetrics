#!/bin/sh

cd home/pi/DestinationMetricsLLC/Programability/Pi

git fetch origin
reslog=$(git log HEAD origin/master --oneline)

if [ "${reslog}" != "" ] ; then
  git merge origin/master # completing the pull
fi
