#!/bin/zsh

# JAMF sadly does not show all interfaces connected to a device. This will give your IP & MAC of all connected NICs

data=$(/usr/libexec/PlistBuddy -x -c "Print :0:_items" /dev/stdin <<< $(system_profiler -xml SPNetworkDataType))

echo -n "<result>"

i=0
while /usr/libexec/PlistBuddy -x -c "Print $i" /dev/stdin <<< $data &>/dev/null;do
    if /usr/libexec/PlistBuddy -c "Print \"$i:Ethernet:MAC Address\"" /dev/stdin <<< $data &>/dev/null;then
        echo "$(/usr/libexec/PlistBuddy -c "Print $i:_name" /dev/stdin <<< $data) ($(/usr/libexec/PlistBuddy -c "Print $i:interface" /dev/stdin <<< $data)) IP: $(/usr/libexec/PlistBuddy -c "Print $i:ip_address:0" /dev/stdin <<< $data) MAC: $(/usr/libexec/PlistBuddy -c "Print \"$i:Ethernet:MAC Address\"" /dev/stdin <<< $data)"
    fi
    i=$(($i+1))
done

echo "</result>"