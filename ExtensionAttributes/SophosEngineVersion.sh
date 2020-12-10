#!/bin/zsh
echo "<result>$(/usr/libexec/PlistBuddy -c 'Print SAVIVersion:EngineVersion' /Library/Preferences/com.sophos.sav.plist)</result>"