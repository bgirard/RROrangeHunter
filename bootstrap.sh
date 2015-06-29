#!/bin/bash

set -e

# system setup, run once
sudo apt-get update
sudo apt-get install -qq gdb python-pip Xvfb unzip firefox mailutils
if [ ! -e "rr-3.2.0-Linux-$(uname -m).deb" ]; then
  wget https://mozilla.github.io/rr/releases/rr-3.2.0-Linux-$(uname -m).deb
fi
sudo dpkg -i rr-3.2.0-Linux-$(uname -m).deb

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

