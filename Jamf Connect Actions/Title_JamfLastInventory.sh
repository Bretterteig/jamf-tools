#!/bin/zsh
function displaytime {
    local T=$1
    local D=$((T / 60 / 60 / 24))
    local H=$((T / 60 / 60 % 24))
    local M=$((T / 60 % 60))
    local S=$((T % 60))
    [[ $D > 0 ]] && printf '%dd ' $D
    [[ $H > 0 ]] && printf '%dh ' $H
    printf '%dmin' $M
}

lastInventory="$(/usr/bin/grep "com.jamfsoftware.task.bgrecon" /var/log/jamf.log | tail -n1 | cut -d' ' -f2-4)"

if [[ -z $lastInventory ]];then
    echo "jamf"
    exit 0
fi

lastInventoryTimestamp="$(LANG=en-US /bin/date -jf '%b %d %T' $lastInventory +%s)"
currentTimestamp="$(/bin/date +%s)"
lastInventorySeconds=$(($currentTimestamp - $lastInventoryTimestamp))
formattedTime=$(displaytime $lastInventorySeconds)

echo "jamf [Inventory ${formattedTime} ago]"
