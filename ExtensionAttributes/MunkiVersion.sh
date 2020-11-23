#!/bin/zsh

ver=$(/usr/local/munki/managedsoftwareupdate -V)

if [[ -n $ver ]];then
	echo "<result>$ver</result>"
else
	echo "<result>None</result>"
fi