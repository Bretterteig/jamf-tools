#!/bin/zsh
RESULT='Not installed'
if [[ -e '/Applications/TeamViewer.app' || -e '/Applications/TeamViewerHost.app' ]]; then
    RESULT='Not assigned'
    
    if [[ -e "/Library/Preferences/com.teamviewer.teamviewer.preferences.plist" ]];then
    	AccountName=$(/usr/libexec/PlistBuddy -c 'print OwningManagerAccountName' /Library/Preferences/com.teamviewer.teamviewer.preferences.plist 2>/dev/null)
    	CompanyName=$(/usr/libexec/PlistBuddy -c 'print OwningManagerCompanyName' /Library/Preferences/com.teamviewer.teamviewer.preferences.plist 2>/dev/null)

    	if [[ -n "$AccountName" && -n "$CompanyName" ]]; then
        	RESULT="$AccountName, $CompanyName"
    	fi
    fi
fi
/bin/echo "<result>$RESULT</result>"