#!/bin/zsh

# Last time munki has run.
# Use date type extension attribute
export TZ="GMT-1"


if [[ -r /Library/Managed\ Installs/ManagedInstallReport.plist ]];then
	echo "<result>$(date -jf "%Y-%m-%d %H:%M:%S %z" "$(/usr/libexec/PlistBuddy -c 'Print EndTime' /Library/Managed\ Installs/ManagedInstallReport.plist)" "+%Y-%m-%d %H:%M:%S")</result>"
fi