#!/bin/zsh

# Release date of currently used virus info 
# Configure as date extension attribute
echo "<result>$(/bin/date -jf "%d.%m.%y" "$(/usr/libexec/PlistBuddy -c 'Print SAVIVersion:DataReleaseDate' /Library/Preferences/com.sophos.sav.plist)" "+%Y-%m-%d %H:%M:%S")</result>"