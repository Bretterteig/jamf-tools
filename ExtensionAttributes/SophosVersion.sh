#!/bin/zsh

# Get the version on the currently installed Sophos Client

version=$(defaults read "/Library/Sophos Anti-Virus/product-info.plist" ProductVersion)

if [[ -n $version ]];then
	echo "<result>$version</result>"
else
	echo "<result>Not installed</result>"
fi