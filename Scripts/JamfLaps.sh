#!/bin/zsh
apiUser="$4"
apiPass="$5"
extAttName="$6"
resetUser="$7"
startPassword="$8"
salt="$9"
encryptPass="${10}"

apiURL="$(/usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)"
LogLocation="/var/log/jamf.log"

# Logging Function for reporting actions
function ScriptLogging() {
    DATE="$(date +%Y-%m-%d\ %H:%M:%S)"
    LOG="$LogLocation"
    echo "[$DATE] $1" >>$LOG
    echo "$1"
}

function DecryptString() {
    echo "${1}" | /usr/bin/openssl enc -aes256 -d -md md5 -a -A -S "${2}" -k "${3}"
}


echo ""
ScriptLogging "======== Starting LAPS Update ========"
ScriptLogging "Checking parameters."

# Verify parameters are present
if [[ "$apiUser" == "" ]]; then
    ScriptLogging "Error:  The parameter 'API Username' is blank.  Please specify a user."
    ScriptLogging "======== Aborting LAPS Update ========"
    exit 1
fi

if [[ "$apiPass" == "" ]]; then
    ScriptLogging "Error:  The parameter 'API Password' is blank.  Please specify a password."
    ScriptLogging "======== Aborting LAPS Update ========"
    exit 1
fi

if [[ "$resetUser" == "" ]]; then
    ScriptLogging "Error:  The parameter 'User to Reset' is blank.  Please specify a user to reset."
    ScriptLogging "======== Aborting LAPS Update ========"
    exit 1
fi

if [[ "$extAttName" == "" ]]; then
    ScriptLogging "Error:  The parameter 'extAttName' is blank.  Please specify the attribute to fill with the new password."
    ScriptLogging "======== Aborting LAPS Update ========"
    exit 1
fi

if ! /usr/sbin/dseditgroup -o checkmember -m "$resetUser" localaccounts &>/dev/null; then
    ScriptLogging "Error: $checkUser is not a local user on the Computer!"
    ScriptLogging "======== Aborting LAPS Update ========"
    exit 1
fi

apiPass="$(DecryptString "$apiPass" "$salt" "$encryptPass")"
startPassword="$(DecryptString "$startPassword" "$salt" "$encryptPass")"

bearerToken=$(/usr/bin/curl -X POST -s -u "${apiUser}:${apiPass}" ${apiURL}/api/v1/auth/token | /usr/bin/plutil -extract token raw -)
if [[ -z $bearerToken ]];then
    echo "Could not acquire bearer token."
    exit 1
fi

ScriptLogging "Parameters Verified."

# Gather further information
ScriptLogging "Getting LAPS info."
udid=$(/usr/sbin/system_profiler SPHardwareDataType | /usr/bin/awk '/Hardware UUID:/ { print $3 }')
oldPass=$(/usr/bin/curl -s -f --max-time 30 -H "Authorization: Bearer ${bearerToken}" -H "Accept: application/xml" "${apiURL}JSSResource/computers/udid/$udid/subset/extension_attributes" | xmllint --xpath "//extension_attribute[name=\"$extAttName\"]//value/text()" - 2>/dev/null)


words=($(grep -x '.\{4,7\}' /usr/share/dict/words))
word_count=${#words[@]}
word1=$words[$((${RANDOM} % ${word_count} + 1))]
word2=$words[$((${RANDOM} % ${word_count} + 1))]
word_part="${word1}-${word2}-"
word_part_count=${#word_part}

newPass="${word_part}$(openssl rand -base64 16 | tr -d OoIi1lL/+zZyY | head -c $((18-$word_part_count)))"

xmlString="<?xml version=\"1.0\" encoding=\"UTF-8\"?><computer><extension_attributes><extension_attribute><name>$extAttName</name><value>$newPass</value></extension_attribute></extension_attributes></computer>"

# Check password stored in JAMF
ScriptLogging "Verifying password stored in LAPS."
if [[ "$oldPass" == "" ]]; then
    ScriptLogging "No Password is received from LAPS."
    if [[ -z "$startPassword" ]]; then
        ScriptLogging "Could not initiate LAPS as there is no starting password."
        exit 1
    else
        ScriptLogging "Trying starting password."
        oldPass="$startPassword"
    fi
else
    ScriptLogging "A Password was found in LAPS."
fi
if dscl /Local/Default -authonly "$resetUser" "$oldPass" &>/dev/null; then
    ScriptLogging "Password is correct."
else
    ScriptLogging "Error: Password stored is not valid for $resetUser."
    if [[ "$oldPass" != "$startPassword" ]];then
        ScriptLogging "Trying start password as an alternative."
        if ! /usr/bin/dscl /Local/Default -authonly "$resetUser" "$startPassword" &>/dev/null; then
            ScriptLogging "Could not determine admin user password."
            ScriptLogging "======== Aborting LAPS Update ========"
            exit 1
        else
            ScriptLogging "Authentication with starting password was successful."
            oldPass="$startPassword"
        fi
    else
        ScriptLogging "======== Aborting LAPS Update ========"
        exit 0
    fi
fi

# Set new password
ScriptLogging "Updating password for $resetUser."
/usr/local/bin/jamf changePassword -username $resetUser -oldPassword "$oldPass" -password "$newPass"
ScriptLogging "Verifying new password for $resetUser."
if /usr/bin/dscl /Local/Default -authonly "$resetUser" "$newPass" &>/dev/null; then
    ScriptLogging "New password for $resetUser is verified."
else
    ScriptLogging "Error: Password reset for $resetUser was not successful!"
    ScriptLogging "======== Aborting LAPS Update ========"
    exit 1
fi

# Send updated password to JAMF
ScriptLogging "Uploading new password for $resetUser."
/usr/bin/curl -s -f --max-time 30 -H "Authorization: Bearer ${bearerToken}" -X PUT -H "Content-Type: text/xml" -d "${xmlString}" "${apiURL}JSSResource/computers/udid/$udid" 1>/dev/null
sleep 3
LAPSpass=$(/usr/bin/curl -s -f --max-time 30 -H "Authorization: Bearer ${bearerToken}" -H "Accept: application/xml" "${apiURL}JSSResource/computers/udid/$udid/subset/extension_attributes" | xmllint --xpath "//extension_attribute[name=\"$extAttName\"]//value/text()" - 2>/dev/null)

ScriptLogging "Verifying LAPS password for $resetUser."
if /usr/bin/dscl /Local/Default -authonly "$resetUser" "$LAPSpass" &>/dev/null; then
    ScriptLogging "LAPS password for $resetUser is verified."
else
    ScriptLogging "Error: LAPS password for $resetUser is not correct!"
    if [[ -n "$startPassword" ]];then
        ScriptLogging "Resetting to starting password."
        /usr/local/bin/jamf changePassword -username $resetUser -oldPassword "$newPass" -password "$startPassword"
    fi
    ScriptLogging "======== LAPS Update Password failed. Warning! ========"
    exit 1
fi

ScriptLogging "======== LAPS Update Finished ========"