#!/bin/zsh
setopt sh_word_split

APIUSER="$4"
APIPASS="$5"

ENCSALT="$6"
ENCKEY="$7"

if [[ -n $ENCKEY ]];then
    APIPASS="$(echo "$APIPASS" | /usr/bin/openssl enc -aes256 -d -a -A -S "$ENCSALT" -k "$ENCKEY")"
fi

JSSURL="$(/usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)"
SERIAL="$(/usr/sbin/ioreg -c IOPlatformExpertDevice -d 2 | /usr/bin/awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}')"
BEARER="$(/usr/bin/curl -X POST -s -u "${apiUser}:${apiPass}" "${apiURL}/api/v1/auth/token" | /usr/bin/plutil -extract token raw -)"
GROUPS="$(/usr/bin/curl -s -H "Authorization: Bearer ${BEARER}" "${JSSURL}JSSResource/computers/serialnumber/${SERIAL}/subset/groups_accounts" | /usr/bin/xmllint --xpath "/computer/groups_accounts/computer_group_memberships" - 2>/dev/null)"

if [[ -z $GROUPS ]];then
	echo "Getting group memberships failed."
    exit 1
fi

IFS=$'\n'
i=1
while echo "$GROUPS" | /usr/bin/xmllint --xpath "/computer_group_memberships/group[$i]" - &>/dev/null;do
    GROUP="$(echo "$GROUPS" | /usr/bin/xmllint --xpath "/computer_group_memberships/group[$i]/text()" -)"
	echo -n "Processing $GROUP: "
    
    HTML_ENC_GROUP="$(echo "$GROUP" | /usr/bin/sed 's/ /'%20'/g')"
    GROUP_DATA="$(/usr/bin/curl -s -H "Authorization: Bearer ${BEARER}" "${JSSURL}JSSResource/computergroups/name/${HTML_ENC_GROUP}")"
    
    if [[ -z $GROUP_DATA ]];then
    	echo "Could not receive group data."
        exit 1
    fi
    
    SMART="$(echo $GROUP_DATA | /usr/bin/xmllint --xpath "/computer_group/is_smart/text()" -)"


    if [[ "$SMART" == "false" ]];then
    	echo "Sending deletion request."
        ID="$(echo $GROUP_DATA | /usr/bin/xmllint --xpath "/computer_group/id/text()" -)"
        DATA="<?xml version=\"1.0\" encoding=\"UTF-8\"?><computer_group><computer_deletions><computer><serial_number>${SERIAL}</serial_number></computer></computer_deletions></computer_group>"
        /usr/bin/curl -H "accept: application/xml" -H "Content-Type: application/xml" -H "Authorization: Bearer ${BEARER}" "${JSSURL}JSSResource/computergroups/id/${ID}" -d "${DATA}" -X PUT -s
    	echo ""
    else
    	echo "Skip."
    fi

    i=$(($i+1))
done