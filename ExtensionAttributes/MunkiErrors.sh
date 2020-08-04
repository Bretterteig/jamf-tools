#!/bin/zsh

# All errors munki encountered during the last run.

if [[ -r /Library/Managed\ Installs/ManagedInstallReport.plist ]];then
	errors=$(/usr/libexec/PlistBuddy -c 'Print Errors' /Library/Managed\ Installs/ManagedInstallReport.plist | grep -E '^ ' || echo "None")
    if [[ -z $errors ]];then
    	echo "<result>None</result>"
    	exit 0
    fi
	echo "<result>$errors</result>"
else
	echo "<result>None</result>"
fi