#!/bin/bash

set -e

# Kill background (&) jobs
trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

DEBUGGER=--debugger=/home/mozilla/rr/obj/bin/rr 
DEBUGGER_ARGS="--debugger-args=-M"
#CHUNK="--total-chunks 50 --this-chunk 3"
SUITE=reftest
TESTS=
RUN_UNTIL_FAILURE="--run-until-failure"
export MOZ_CHAOSMODE=true

export _RR_TRACE_DIR=$PWD/rr-recording
rm -rf $_RR_TRACE_DIR
mkdir $_RR_TRACE_DIR

while true; do
  # POS!
  ./mach mercurial-setup --update-only
  #Xvfb :99 -screen 0 1280x1024x24 &
  #sleep 5
  #avconv -y -r 30 -g 300 -f x11grab -s 1280x1024 -i :99 -vcodec qtrle out.mov &
  #SCREENRECORD_PID=$!
  export DISPLAY=":99"
  xvfb-run -n 99 -s "-screen 0 1280x1024x24" dbus-launch --exit-with-session ./mach $SUITE $CHUNK $DEBUGGER $RUN_UNTIL_FAILURE --setpref gfx.xrender.enabled=false $DEBUGGER_ARGS $TESTS | tee run.log
  #dbus-launch --exit-with-session ./mach $SUITE $CHUNK $DEBUGGER $RUN_UNTIL_FAILURE --setpref gfx.xrender.enabled=false "--debugger-args=record -M -h" $TESTS | tee run.log
  #kill $SCREENRECORD_PID
  FAILURE_LINE=`grep TEST-UNEXPECTED run.log | cat`

  if [ -n "$FAILURE_LINE" ]; then
    exit 1
  fi
done
