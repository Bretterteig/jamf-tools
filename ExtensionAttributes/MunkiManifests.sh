#!/bin/zsh

# List of all manifests munki is using. Highlights the main manifest

if ! [[ -r "/Library/Managed Installs/ManagedInstallReport.plist" ]];then
	echo "<result>None</result>"
    exit 0
fi

main_manifest="$(/usr/libexec/PlistBuddy -c 'Print ManifestName' "/Library/Managed Installs/ManagedInstallReport.plist")"
additional_manifests="$(ls /Library/Managed\ Installs/manifests | sed -E /$main_manifest|SelfServeManifest/d)"

echo "<result>$main_manifest (ID)"
if [[ -n $additional_manifests ]];then
    echo "\n$additional_manifests</result>"
else
    "</result>"
fi
