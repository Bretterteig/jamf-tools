#!/bin/zsh

# Process will change password for the user currently logged in at the device. Please make sure that the username on the device and the username in AD are the same.

# Config
# FQDN
domain="${4:u}"
# One of the key distribution servers. If all DCs are KDC you can use the FQDN
kdc="$5"
# Specify a ldap server. If all DCs have ldap active you can use the FQDN
ldap="$6"


# Predefined values
user="$(/usr/sbin/scutil <<<"show State:/Users/ConsoleUser" | /usr/bin/awk -F': ' '/[[:space:]]+Name[[:space:]]:/ { print $2 }')"

# Query password via prompt
function getpassword() {
    if [[ ${2:l} == "true" ]];then
        output="$(launchctl asuser $(id -u $user) osascript -e "text returned of (display dialog \"$1\" default answer \"\" with hidden answer buttons {\"Abort\", \"Authenticate\"} default button \"Authenticate\" with icon caution giving up after 300)")"
    else
        output="$(launchctl asuser $(id -u $user) osascript -e "text returned of (display dialog \"$1\" default answer \"\" with hidden answer buttons {\"Abort\", \"Authenticate\"} default button \"Authenticate\" with icon alias \"$(iconpath "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/LockedIcon.icns")\" giving up after 300)")"
    fi
    echo $output
}

# Display error message via prompt
function displayerror() {
    if [[ "$2" == "true" ]];then
        launchctl asuser $(id -u $user) osascript -e "display dialog \"$1\" with icon stop buttons {\"OK\"} default button \"OK\" giving up after 120"
    else
        nohup launchctl asuser $(id -u $user) osascript -e "display dialog \"$1\" with icon stop buttons {\"OK\"} default button \"OK\" giving up after 120" &>/dev/null &
    fi
}

# Check if the password entered is correct
function ldappasswordcheck() {
    if [[ -z "$(ldapwhoami -H "ldaps://${ldap}:636" -x -w "${2}" -D "${1}@${domain:l}")" ]];then
        echo "LDAP Auth failed."
        return 1
    else
        echo "LDAP Auth success."
        return 0
    fi
}

# Convert normal paths to osascript icon paths
function iconpath(){
    volname="$(diskutil info / | awk -F':' '/Volume Name:/ {print $2}' | sed -e 's/^[ \t]*//')"
    pathconv="$(echo $1|sed s%/%:%g)"
    echo "$volname$pathconv"
}

# A function to check password complexity. Rules:
# 8 characters
# Does not contain username
# Is not old password
# Has atleast 3 of the following: Uppercase letter, lowercase letter, numerical, special character
function checkpassword() {
    if ((${#1} <= 7)); then # Not atleast 8 characters
    	echo "Password does not have atleast 8 characters"
        return 1
    elif echo $1 | grep -q $user; then # Contains the username
    	echo "Password must not contain the username"
        return 1
    elif [[ $1 == $pass ]];then # Is the old password
    	echo "You cannot use your old password again"
    	return 1
    elif [[ $1 =~ [[:upper:]] ]] && [[ $1 =~ [[:lower:]] ]] && [[ $1 =~ [^[:alnum:]] ]]; then # Has lower,upper,special
        return 0
    elif [[ $1 =~ [[:upper:]] ]] && [[ $1 =~ [[:lower:]] ]] && [[ $1 =~ [[:digit:]] ]]; then # Has lower,upper,number
        return 0
    elif [[ $1 =~ [[:upper:]] ]] && [[ $1 =~ [^[:alnum:]] ]] && [[ $1 =~ [[:digit:]] ]]; then # Has upper,special,number
        return 0
    elif [[ $1 =~ [[:lower:]] ]] && [[ $1 =~ [^[:alnum:]] ]] && [[ $1 =~ [[:digit:]] ]]; then # Has lower,special,number
        return 0
    else
    	echo "Your password does not meet the complexity requirement"
        return 1
    fi
}

# Check if services is reachable
echo "Checking connections"
if ! nc -z "${kdc}" "464" &>/dev/null || ! nc -z "${ldap}" "636" &>/dev/null;then
    displayerror "Cannot reach a required service. 
Namechange currently not possible."
    exit 1
fi

# Modify Kerberos config file. (Which is needed for devices that are not bounded. kpasswd would not start otherwise.)
if ! [[ -r /etc/krb5.conf ]];then
echo "[libdefaults]
   default_realm = ${domain}
 
[realms]
${domain} = {
   kdc = ${kdc}
}" > /etc/krb5.conf
else
	if ! cat /etc/krb5.conf | grep -q "default_realm = ${domain}";then
    	displayerror "Something does not seem to be correct with your kerberos configuration file."
    fi
fi



# Get Input
### First try
echo "Queryingm password for ${user}"
pass="$(getpassword "Please enter the CURRENT password for ${user}.")"
if [[ -z $pass ]];then
    echo "Empty password field. Aborting."
    exit 1
fi

### Try 2 more times with different message
trys=1
while ! ldappasswordcheck "${user}" "${pass}" && (($trys<3));do
    pass="$(getpassword "Wrong password for user ${user}. Please try again." "true")"
    if [[ -z $pass ]];then
        echo "Empty password field. Aborting."
        exit 1
    fi
    trys=$((trys+1))
done
if ! ldappasswordcheck "${user}" "${pass}";then
    displayerror "Authentication failed three times."
    exit 1
fi




### Get new password.
newpass=""
while [[ $newpass != $newpass_confirm ]] || [[ -z $newpass ]];do
    newpass="$(getpassword "Enter your NEW password.")"
    passreturn="$(checkpassword "$newpass")"
    if [[ -z $newpass ]];then
        echo "Empty resonse. Aborting."
        exit 1
    elif [[ -n "$passreturn" ]];then
        displayerror "$passreturn" "true"
        continue
    fi
    
    newpass_confirm="$(getpassword "Please CONFIRM your NEW password")"
    if [[ -z $newpass_confirm ]];then
       	echo "Empty resonse. Aborting."
        exit 1
    elif [[ $newpass != $newpass_confirm ]];then
        displayerror "Your new password and the confirmation do not match. Try again." "true"
    fi
done



# Remove kerberos tickers because we will generate a new one to the domain we want
if klist &>/dev/null;then
    kdestroy
    echo ""
fi

# Script kpasswd interactive input with acquired data
echo "Scripting user input for kpasswd..."
output="$(/usr/bin/expect -f - <<EOD
log_user 0
spawn kpasswd "${user}@${domain}"
expect "Password:"
send "${pass}\r"
expect "password"
send "${newpass}\r"
expect "password"
send "${newpass}\r"
log_user 1
expect eof
EOD
)"

echo "### Response
$output
### END Response"

# If reponse is not success display it to user and mark process as failure
if ! echo $output | grep -iwq "success";then
    if [[ -z $output ]];then
        displayerror "Unknown error response. Most likely your password did not meet the requirements. Requirements can be read in the description."
    elif [[ $output =~ "Soft error :" ]];then
        displayerror "The directory service rejected your password. This may be because it does not meet the requirements or you have used it before."
    else
        displayerror "Password change was not successful.
Error:$output"
    fi
    exit 1
fi

# Inform user everything is o.k.
nohup launchctl asuser $(id -u $user) osascript -e "display dialog \"Your password was changed successfully.\" buttons {\"OK\"} giving up after 60" &>/dev/null &
exit 0