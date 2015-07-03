#!/bin/bash

set -e

if [ ! -e config.sh ]; then
  echo "Must setup config.sh first."
  exit 1
fi

while true; do

  source config.sh

  xvfb-run ./mach mochitest --run-until-failure --appname=./firefox/firefox --debugger=rr dom/canvas | tee run.log

  LOG_TXT=`tail -n 50 run.log`
  FAILURE_LINE=`grep TEST-UNEXPECTED run.log || true`

  if [ -n "$FAILURE_LINE" ]; then
    if [ -n "$ORANGEHUNTER_EMAIL" ]; then
      echo -e "There is a replay ready for debugging: ssh $ORANGEHUNTER_SSH_ADDRESS\n\n$LOG_TXT" | mail $ORANGEHUNTER_EMAIL --subject="OrangeHunter: RR-Replay ready for ${FAILURE_LINE}"
    fi
    echo "Failed, exiting"
    exit 1
  fi

  echo $rv

done
