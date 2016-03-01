#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -xe

# Kill background (&) jobs
trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

DEBUGGER=--debugger=rr 
DEBUGGER_ARGS="--debugger-args= record -M -V -h"
CHUNK="--total-chunks 5 --this-chunk 2"
SUITE=reftest
#TESTS=image/test/reftest/bmp/bmpsuite/b
RUN_UNTIL_FAILURE="--run-until-failure"
export MOZ_CHAOSMODE=true

export _RR_TRACE_DIR="$PWD/rr-recording"

while true; do
  # Setup
  rm -rf $_RR_TRACE_DIR
  mkdir $_RR_TRACE_DIR
  ./mach mercurial-setup --update-only

  # Pick a test to run
  source "$DIR/tests.sh"
  echo ${HUNT_TESTS_SIZE}
  TEST_ID=$[ RANDOM % ${HUNT_TESTS_SIZE} ]
  TEST_ID=0
  echo TEST_ID $TEST_ID
  SUITE=${HUNT_TESTS[$[${TEST_ID} * 2]]}
  TESTS=${HUNT_TESTS[$[${TEST_ID} * 2 + 1]]}
  echo Running: $SUITE $TESTS

  # Run the test
  #Xvfb :99 -screen 0 1280x1024x24 &
  #sleep 5
  #avconv -y -r 30 -g 300 -f x11grab -s 1280x1024 -i :99 -vcodec qtrle out.mov &
  #SCREENRECORD_PID=$!
  export DISPLAY=":99"
  xvfb-run -n 99 -s "-screen 0 1280x1024x24" dbus-launch --exit-with-session ./mach $SUITE $CHUNK $DEBUGGER $RUN_UNTIL_FAILURE --setpref gfx.xrender.enabled=false "$DEBUGGER_ARGS" $TESTS | tee "$_RR_TRACE_DIR/run.log"
  #dbus-launch --exit-with-session ./mach $SUITE $CHUNK $DEBUGGER $RUN_UNTIL_FAILURE --setpref gfx.xrender.enabled=false "--debugger-args=record -M -h" $TESTS | tee run.log
  #kill $SCREENRECORD_PID
  FAILURE_LINE=`grep TEST-UNEXPECTED "$_RR_TRACE_DIR/run.log" | cat`

  if [ -n "$FAILURE_LINE" ]; then
    exit 1
  fi
done
