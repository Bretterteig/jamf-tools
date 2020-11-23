#!/bin/zsh
echo "<result>$(PlistBuddy -x -c 'print Conditions:catalogs' /Library/Managed\ Installs/ManagedInstallReport.plist | xmllint --xpath "//string/text()" -)</result>"