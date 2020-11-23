#!/bin/zsh
echo -n "<result>"
i=0
while true;do
    item=$(/usr/libexec/plistbuddy -c "print ItemsToInstall:${i}:name" /Library/Managed\ Installs/ManagedInstallReport.plist 2>/dev/null)
    if [[ $? != 0 ]] ;then
        echo -n "</result>"
        break
    fi
    echo "$item"
    i=$(($i+1))
done