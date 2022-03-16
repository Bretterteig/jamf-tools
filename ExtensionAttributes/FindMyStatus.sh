#!/bin/zsh
if /usr/libexec/PlistBuddy -c 'print fmm-mobileme-token-FMM' /dev/stdin &>/dev/null <<< $(/usr/sbin/nvram -x -p);then
    echo "<result>Activated</result>"
else
    echo "<result>Deactivated</result>"
fi
