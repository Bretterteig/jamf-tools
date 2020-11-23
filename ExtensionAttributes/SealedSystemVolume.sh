#!/bin/zsh
if /usr/bin/csrutil authenticated-root | grep -qi "enabled";then
	echo "<result>Enabled</result>"
else
	echo "<result>Disabled</result>"
fi