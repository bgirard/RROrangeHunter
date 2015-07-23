#!/bin/bash

set -e

# system setup, run once
sudo apt-get update
sudo apt-get install -qq gdb python-pip Xvfb unzip firefox mailutils libgtk-3-dev libcairo2-dev
if [ ! -e "rr-3.2.0-Linux-$(uname -m).deb" ]; then
  wget https://mozilla.github.io/rr/releases/rr-3.2.0-Linux-$(uname -m).deb
fi
sudo dpkg -i rr-3.2.0-Linux-$(uname -m).deb

hash uuidgen || {
  echo "Must have uuidgen installed"
  exit 1
}
