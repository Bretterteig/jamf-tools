#!/bin/zsh

# Script to add/remove devices form a static group. Useful for opt in style policys

# API User data
USER="$4"
PASS="$5"

# Request parameter
GROUPID="$6"
GROUPNAME="$7"
# You can use either ADD or DEL
OPTION="$8"
APIURL="$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)JSSResource"
APIENDPOINT="computergroups/id"

if echo $OPTION | grep -qiE "^DEL.*$";then
	OPTION="computer_deletions"
elif echo $OPTION | grep -qiE "^ADD.*$";then
	OPTION="computer_additions"
else
	echo "OPTION was not defined correctly"
	exit 1
fi

# Build data
SERIAL="$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')"
DATA="<?xml version=\"1.0\" encoding=\"UTF-8\"?><computer_group><id>${GROUPID}</id><name>${GROUPNAME}</name><${OPTION}><computer><serial_number>${SERIAL}</serial_number></computer></${OPTION}></computer_group>"
DATA=$(echo "$DATA" | tidy -xml -utf8 -i 2>/dev/null)

REQUESTRESULT=`curl -H "accept: application/xml" -H "Content-Type: application/xml" -u "${USER}:${PASS}" "${APIURL}/${APIENDPOINT}/${GROUPID}" -d "${DATA}" -X PUT -s`

echo "$REQUESTRESULT"