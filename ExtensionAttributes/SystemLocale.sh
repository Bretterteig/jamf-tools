#!/bin/zsh

# Shows which system locale is beeing used

echo "<result>$(/usr/libexec/PlistBuddy -c 'Print :AppleLocale' /Library/Preferences/.GlobalPreferences.plist)</result>"