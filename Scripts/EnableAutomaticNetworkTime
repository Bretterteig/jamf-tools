#!/bin/zsh
/usr/sbin/systemsetup -setusingnetworktime on
/usr/sbin/systemsetup -setnetworktimeserver "time.apple.com"
/usr/bin/defaults write /private/var/db/timed/Library/Preferences/com.apple.timed.plist TMAutomaticTimeOnlyEnabled -bool YES
/usr/bin/defaults write /private/var/db/timed/Library/Preferences/com.apple.timed.plist TMAutomaticTimeZoneEnabled -bool YES
/usr/bin/killall timed
