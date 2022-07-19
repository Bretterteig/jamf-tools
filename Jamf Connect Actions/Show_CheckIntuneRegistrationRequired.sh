#!/bin/zsh
REGISTERED="$(/usr/local/jamf/bin/jamfAAD gatherAADInfo | grep -q "No AAD ID found" || echo "true")"
CERTIFICATE_AVAILABLE="$(/usr/bin/security find-certificate -a | /usr/bin/grep -q "MS-ORGANIZATION-ACCESS" && echo "true")"

if [[ "$REGISTERED" == "true" ]] && [[ "$CERTIFICATE_AVAILABLE" == "true" ]];then
    echo "false"
else
    echo "true"
fi