#!/bin/zsh
AzureDeviceID=$(/usr/bin/security find-certificate -a | /usr/bin/grep "MS-ORGANIZATION-ACCESS" -B4 | awk -F'"' '/alis/ {print $4}')
/usr/bin/open https://portal.manage.microsoft.com/devices/${AzureDeviceID}