#!/bin/bash
# If Conditional Access is enabled via Company Portal (Workplace Join) display the Azure AAD ID of that device
user="$(/usr/sbin/scutil <<<"show State:/Users/ConsoleUser" | /usr/bin/awk -F': ' '/[[:space:]]+Name[[:space:]]:/ { print $2 }')"

echo "<result>$(su "$user" -c "security find-certificate -a -Z" | grep -B 9 "MS-ORGANIZATION-ACCESS" | awk '/\"alis\"<blob>=\"/ {print $NF}' | sed 's/  \"alis\"<blob>=\"//;s/.$//'")</result>"