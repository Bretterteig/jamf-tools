#!/bin/zsh

# Check when the last connection to Sophos Central has been made

echo "<result>$(date -jf "%H:%M:%S %b %d, %Y (UTC%z)" "$(/usr/libexec/PlistBuddy -c 'Print SMEMcsLastCommunications:SMEMcsLastSuccessCommunicationTimestamp' /Library/Preferences/com.sophos.mcs.plist)" "+%Y-%m-%d %H:%M:%S")</result>"