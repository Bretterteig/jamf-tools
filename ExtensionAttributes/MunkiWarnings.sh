#!/bin/zsh

# Shows all munki warnings.

if [[ -r /Library/Managed\ Installs/ManagedInstallReport.plist ]];then
	echo "<result>$(/usr/libexec/PlistBuddy -c 'Print Warnings' /Library/Managed\ Installs/ManagedInstallReport.plist | grep -E '^ ' || echo "None")</result>"
else
	echo "<result>None</result>"
fi