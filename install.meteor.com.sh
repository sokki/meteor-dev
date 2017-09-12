#!/bin/sh
git clone --recursive -b release-1.6 --single-branch https://github.com/meteor/meteor.git /usr/local/meteor-git
/usr/local/meteor-git/meteor --help
