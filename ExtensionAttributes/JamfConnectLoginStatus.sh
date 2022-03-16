#!/bin/zsh
if /usr/bin/security authorizationdb read "system.login.console" | /usr/bin/grep -q "JamfConnectLogin:LoginUI"; then
	result="Enabled"
else
	result="Disabled"
fi
echo "<result>$result</result>"
