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

if ! defaults read ~/Library/Preferences/com.jamf.management.jamfAAD last_aad_token_timestamp &>/dev/null;then
    echo "Endpoint Manager [Pending]"
    exit 0
fi

lastInventoryTimestamp="$(defaults read ~/Library/Preferences/com.jamf.management.jamfAAD last_aad_token_timestamp | cut -d'.' -f1)"
currentTimestamp="$(/bin/date +%s)"
lastInventorySeconds=$(($currentTimestamp - $lastInventoryTimestamp))
formattedTime=$(displaytime $lastInventorySeconds)

echo "Endpoint Manager [Inventory ${formattedTime} ago]"
