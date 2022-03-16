#!/bin/zsh
/usr/bin/defaults write "/var/db/locationd/Library/Preferences/ByHost/com.apple.locationd" LocationServicesEnabled -boolean YES
/bin/launchctl kickstart -k system/com.apple.locationd
