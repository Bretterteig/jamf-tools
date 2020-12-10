#!/bin/zsh

# Check if firmwarepassword is set

if firmwarepasswd -check | grep -qi "Yes";then
	echo "<result>Enabled</result>"
else
	echo "<result>Disabled</result>"
fi