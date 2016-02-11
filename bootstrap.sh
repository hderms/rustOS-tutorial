#!/usr/bin/env bash
apt-get update
apt-get install -y make vim
cd /vagrant/src
chmod +x ./fetch.sh
./fetch.sh
