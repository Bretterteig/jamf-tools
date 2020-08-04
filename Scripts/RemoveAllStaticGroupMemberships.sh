#!/bin/zsh

# Remove all static group memberships. Useful for wiping a device.

APIUSER=$4
APIPASS=$5

setopt sh_word_split

JSSURL="$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)"
GROUPS="$(curl -s -u "${APIUSER}:${APIPASS}" "${JSSURL}JSSResource/computers/udid/$(system_profiler SPHardwareDataType | awk '/UUID/ { print $3; }')/subset/GroupsAccounts" | xpath "/computer/groups_accounts/computer_group_memberships/group" 2>/dev/null | tidy -xml 2>/dev/null)"
SERIAL="$(ioreg -c IOPlatformExpertDevice -d 2 | awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}')"

IFS=$'\n'
for GROUP in $GROUPS;do
    GROUP_FORMAT="$(echo "$GROUP" | awk -F'>' '{print $2}' | awk -F'<' '{print $1}')"
    HTML_GROUP="$(echo "$GROUP_FORMAT" | sed 's/ /'%20'/g')"

	echo -n "Processing $GROUP_FORMAT: "

    GROUP_DATA="$(curl -s -u "${APIUSER}:${APIPASS}" "${JSSURL}JSSResource/computergroups/name/${HTML_GROUP}")"
    
    SMART="$(echo $GROUP_DATA | xpath "/computer_group/is_smart" 2>/dev/null | awk -F'>' '{print $2}' | awk -F'<' '{print $1}')"

    if [[ "$SMART" == "false" ]];then
    	echo "Static. Sending deletion request."
        ID="$(echo $GROUP_DATA | xpath "/computer_group/id" 2>/dev/null | awk -F'>' '{print $2}' | awk -F'<' '{print $1}')"
        DATA="<?xml version=\"1.0\" encoding=\"UTF-8\"?><computer_group><id>${ID}</id><name>${GROUP_FORMAT}</name><computer_deletions><computer><serial_number>${SERIAL}</serial_number></computer></computer_deletions></computer_group>"
        DATA=$(echo "$DATA" | tidy -xml -utf8 -i 2>/dev/null)
        curl -H "accept: application/xml" -H "Content-Type: application/xml" -u "${APIUSER}:${APIPASS}" "${JSSURL}JSSResource/computergroups/id/${ID}" -d "${DATA}" -X PUT -s
    	echo ""
    else
    	echo "Not static."
    fi
done