#!/bin/zsh

# Version number of virus data release

echo "<result>$(/usr/libexec/PlistBuddy -c 'Print SAVIVersion:DataVersion' /Library/Preferences/com.sophos.sav.plist)</result>"