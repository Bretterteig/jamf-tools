#!/bin/zsh
# The user which should be added to FileVault
newUser="$4"
# The password of the user [plain/encrypted/blank - Depending of the method used] 
newUserPassword="$5"
# Message which is shown to the current logged in FileVault enabled user
displayMessage="$6"

# (opt) If you have an extesnion attribute that stores a user password provide API credentials to receive it.
apiUser="$7"
# (opt) Can be plain or encrypted
apiPass="$8"
jamfAttribute="$9"

# (opt) If specified the value above will be considered encrypted. Encryption used in this script is AES256
encSalt="${10}"
encKey="${11}"

# Pre populated variables
currentUser="$(/usr/sbin/scutil <<<"show State:/Users/ConsoleUser" | /usr/bin/awk -F': ' '/[[:space:]]+Name[[:space:]]:/ { print $2 }')"
icon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FileVaultIcon.icns"
altDisplayMessage="${displayMessage}\n\nWrong password. Please try again."

function get_password() {
    text="$1"
    icon_path="$2"
    icon_path="$(/usr/sbin/diskutil info / | /usr/bin/awk -F':' '/Volume Name:/ {print $2}' | /usr/bin/sed -e 's/^[ \t]*//')$(echo $icon_path | /usr/bin/sed s%/%:%g)"

    launchctl asuser "$(id -u $currentUser)" \
    /usr/bin/osascript <<EOF
        text returned of ( \
            display dialog "$text" default answer "" with hidden answer \
            buttons {"Authenticate"} default button "Authenticate" \
            with icon alias "$icon_path" \
            giving up after 300 \
        ) 
EOF
}

function parse_xml_friendly() {
    input="$1"
    output=${input//&/&amp;}
    output=${output//</&lt;}
    output=${output//>/&gt;}
    output=${output//\"/&quot;}
    output=${output//\'/&apos;}
    echo "$output"
}

function display_error() {
    launchctl asuser $(id -u $currentUser) osascript -e "display dialog \"$1\" with icon stop buttons {\"OK\"} default button \"OK\" giving up after 120"
}

function authenticate() {
    return $(dscl . auth "$1" "$2" &>/dev/null)
}

function decrypt_string() {
    echo "${1}" | /usr/bin/openssl enc -aes256 -d -a -A -S "${encSalt}" -k "${encKey}"
}



# Exit if user already in FileVault
if /usr/bin/fdesetup list | grep -q $newUser ;then
    echo "$newUser already FV activated!"
    exit 0
fi

# Exit if selected user cannot add people to FV
if ! /usr/bin/fdesetup list | grep -q $currentUser ;then
    echo "$currentUser is not FileVault enabled!"
    exit 1
fi

# Decrypt passwords
if [[ -n $encKey ]];then
	newUserPassword="$(decrypt_string "$newUserPassword")"
    apiPass="$(decrypt_string "$apiPass")"
fi

# Get the LAPS password
if [[ -n $jamfAttribute ]];then
	udid=$(/usr/sbin/system_profiler SPHardwareDataType | /usr/bin/awk '/Hardware UUID:/ { print $3 }')
	jamfPassword=$(/usr/bin/curl -s -f -u "$apiUser":"$apiPass" -H "Accept: application/xml" "$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)JSSResource/computers/udid/$udid/subset/extension_attributes" | xmllint --xpath "//extension_attribute[name=\"$jamfAttribute\"]//value/text()" - 2>/dev/null)
    if [[ -n $jamfPassword ]];then 
        echo "Retrival of password from JAMF successful."
        authenticate "$newUser" "$jamfPassword" && newUserPassword="$jamfPassword"
    else
        echo "Could not retrive password from JAMF"
    fi
fi

# Test password of the new user
if ! authenticate "$newUser" "$newUserPassword";then
	echo "Authentication of ${newUser} failed"
    exit 1
fi


# Try three times to get the password
trys=0
while ! authenticate "$currentUser" "$currentUserPassword" && (($trys<3));do
    if (($trys>0));then
        displayMessage="$altDisplayMessage"
        icon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns"
    fi
    currentUserPassword="$(get_password "$displayMessage" "$icon")"
    trys=$((trys+1))
done
if ! authenticate "$currentUser" "$currentUserPassword";then
    display_error "Authentication failed three times."
    exit 1
fi


# Add to FileVault
/usr/bin/fdesetup add -inputplist -verbose <<EOF
<plist>
    <dict>
        <key>Username</key>
        <string>$(parse_xml_friendly "$currentUser")</string>
        <key>Password</key>
        <string>$(parse_xml_friendly "$currentUserPassword")</string>
        <key>AdditionalUsers</key>
        <array>
            <dict>
                <key>Username</key>
                <string>$(parse_xml_friendly "$newUser")</string>
                <key>Password</key>
                <string>$(parse_xml_friendly "$newUserPassword")</string>
            </dict>
        </array>
    </dict>
</plist>
EOF


# Renew SecureToken just in case
/usr/sbin/sysadminctl -secureTokenOn "$newUser" -password "$newUserPassword" -adminUser "$currentUser" -adminPassword "$currentUserPassword"

if ! /usr/sbin/sysadminctl -secureTokenStatus "$newUser" 2>&1 | grep -q ENABLED && /usr/bin/fdesetup list | grep -q "${usertoadd}";then
	display_error "Something did went wrong while enabling $newUser for FileVault."
fi