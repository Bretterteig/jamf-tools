#!/bin/zsh
echo "<result>$(/usr/sbin/ioreg -l | /usr/bin/awk -F ' ' '/KeyboardLanguage/{gsub("\"","");print $NF}')</result>"