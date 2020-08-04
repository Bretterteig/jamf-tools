#!/bin/zsh

# Reads the battery health status directly from system_profiler

result=$(/usr/libexec/PlistBuddy -c 'Print :0:_items:0:sppower_battery_health_info:sppower_battery_health' /dev/stdin <<< $(system_profiler SPPowerDataType -xml) 2>/dev/null)

if [[ -n $result ]];then
	echo "<result>$result</result>"
else
	echo "<result>Not available</result>"
fi