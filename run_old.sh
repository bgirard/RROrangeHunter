#!/bin/bash
set -e
set -x

if [ ! -e config.sh ]; then
  echo "Must setup config.sh first."
  exit 1
fi
source config.sh

BASE_DIR="$PWD"
WORK_DIR="$PWD/working"
UNTRIAGED_DIR="$PWD/untriaged"

prepare_record() {
  #pip install mozdownload
  if [ ! -e "fetch-symbols.py" ]; then
    wget http://hg.mozilla.org/users/jwatt_jwatt.org/fetch-symbols/raw-file/default/fetch-symbols.py
  fi
  
  # download a build + test package + symbols
  #mozdownload --type=daily
  version=`curl -s https://hg.mozilla.org/mozilla-central/raw-file/default/config/milestone.txt | tail -n1`
  filename=firefox-${version}.en-US.linux-`uname -p`.tar.bz2
  if [ ! -e "$filename" ]; then
    wget http://ftp.mozilla.org/pub/mozilla.org/firefox/nightly/latest-mozilla-central/$filename
  fi
  tar xaf $filename
  test_filename=firefox-${version}.en-US.linux-`uname -p`.tests.zip
  if [ ! -e "$test_filename" ]; then
    wget http://ftp.mozilla.org/pub/mozilla.org/firefox/nightly/latest-mozilla-central/${test_filename}
  fi
  unzip $test_filename
  python fetch-symbols.py firefox/ https://symbols.mozilla.org/firefox
}

result_line() {
  echo "************************"
  echo "  RR Run Result: $1"
  echo "************************"
}

while true; do

  # clean up
  cd "$BASE_DIR"
  rm -rf "$WORK_DIR"
  mkdir -p "$UNTRIAGED_DIR"

  # Make sure we're not overflowing our disk
  SIZE=`du -sm "$UNTRIAGED_DIR" | awk '{print $1}'`
  if [ "$SIZE" -gt "$ORANGEHUNTER_UNTRIAGE_SIZE" ]; then
    echo "Waiting for replay triage"
  fi
  while [ "$SIZE" -gt "$ORANGEHUNTER_UNTRIAGE_SIZE" ]; do
    SIZE=`du -sm "$UNTRIAGED_DIR" | awk '{print $1}'`
    sleep 1 # Wait for these replay to get triaged
  done
  echo "untriage size check: $SIZE < $ORANGEHUNTER_UNTRIAGE_SIZE"

  FREESPACE=`df -Pm . | awk 'NR==2 {print $4}'`
  if [ "$FREESPACE" -lt "$ORANGEHUNTER_MIN_SPACE" ]; then
    echo "Waiting for at least $ORANGEHUNTER_MIN_SPACE Mb of free space."
  fi
  while [ "$FREESPACE" -lt "$ORANGEHUNTER_MIN_SPACE" ]; do
    FREESPACE=`df -Pm . | awk 'NR==2 {print $4}'`
    sleep 1 # Wait for space to be cleared
  done
  echo "space check: $SIZE > $ORANGEHUNTER_MIN_SPACE"

  # Refresh configuration file
  source config.sh

  # prepare a new recording
  #mkdir -p "$WORK_DIR"
  #cd "$WORK_DIR"

  # Work around for https://github.com/mozilla/rr/issues/1518,
  # use the replay directory as the work direcory for now.
  REPLAY_UUID=`uuidgen`
  REPLAY_DIR="$UNTRIAGED_DIR"/"$REPLAY_UUID"
  mkdir -p "$REPLAY_DIR"
  cd "$REPLAY_DIR"
  prepare_record

  # record until we get a failure
  WAIT_FAILURE=true
  while $WAIT_FAILURE; do
    rm -rf $PWD/rr-recording
    mkdir $PWD/rr-recording
    # --run-until-failure
    _RR_TRACE_DIR=$PWD/rr-recording xvfb-run ./mach mochitest --appname=./firefox/firefox --debugger=rr --setpref gfx.xrender.enabled=false --debugger-args=-M --repeat 50 docshell/test/navigation/test_sessionhistory.html | tee run.log

    # analyze the results
    LOG_TXT=`tail -n 50 run.log`
    FAILURE_LINE=`grep TEST-UNEXPECTED run.log | cat`

    if [ -n "$FAILURE_LINE" ]; then
      if [ -n "$ORANGEHUNTER_EMAIL" ]; then
        # TODO Reformat this
        echo -e "There is a replay ready for debugging:\n\nssh $ORANGEHUNTER_SSH_ADDRESS\ncd $REPLAY_DIR\nrr replay rr-recording/latest-trace\n\n$LOG_TXT" | mail $ORANGEHUNTER_EMAIL --subject="OrangeHunter: RR-Replay ready for ${FAILURE_LINE}"
      fi
      WAIT_FAILURE=false
      result_line "Failure saved to $REPLAY_DIR"
    else
      result_line "No failure found, continuing"
    fi
  done

  # move to untriaged
  # Can't move the replay for now: https://github.com/mozilla/rr/issues/1518
  # mv "$WORK_DIR" "$UNTRIAGED_DIR"/"$REPLAY_UUID"
done
