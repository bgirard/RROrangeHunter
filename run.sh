#!/bin/bash

set -e
xvfb-run ./mach mochitest --run-until-failure --appname=./firefox/firefox --debugger=rr dom/canvas | tee run.log

IP=`curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//'`
LOG_TXT=`tail -n 50 run.log`
FAILURE_LINE=`grep TEST-UNEXPECTED run.log`
echo -e "There is a replay ready for debugging: ssh mozilla@${IP}\n\n$LOG_TXT" | mail b56girard@gmail.com --subject="OrangeHunter: RR-Replay ready for ${FAILURE_LINE}"
