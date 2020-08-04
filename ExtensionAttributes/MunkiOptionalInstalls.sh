#!/bin/zsh

# List of optinal installs selected by user

if [[ -r /Library/Managed\ Installs/ManagedInstallReport.plist ]];then
	list=$(/usr/libexec/PlistBuddy -c 'Print managed_installs' "/Library/Managed Installs/manifests/SelfServeManifest" | grep -E '^\s' | sed -e 's/^[ \t]*//')
    if [[ -z $list ]];then
    	echo "<result>None</result>"
        exit 0
    fi
	echo "<result>$list</result>"
else
	echo "<result>None</result>"
fi
