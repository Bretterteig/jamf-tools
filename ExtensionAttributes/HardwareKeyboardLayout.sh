#!/bin/zsh

# The location where the keyboard layout is saved varies from release to release. Just added both

keyboardLayout="$(/usr/libexec/PlistBuddy -c 'Print :AppleDefaultAsciiInputSource:"KeyboardLayout Name"' /Library/Preferences/com.apple.HIToolbox.plist)"
[[ -z "$keyboardLayout" ]] && keyboardLayout="$(/usr/libexec/PlistBuddy -c 'Print :AppleSelectedInputSources:0:"KeyboardLayout Name"' /Library/Preferences/com.apple.HIToolbox.plist)"
echo "<result>$keyboardLayout</result>"