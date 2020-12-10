#!/bin/zsh

# Grab the location key from the builtin keyboard

keyboards="$(ioreg -a -r -k KeyboardLanguage)"

i=0
while /usr/libexec/PlistBuddy -c "print $i" /dev/stdin <<< $keyboards &>/dev/null;do
    if "$(/usr/libexec/PlistBuddy -c "print $i:Built-In" /dev/stdin <<< $keyboards)";then
        echo "<result>$(/usr/libexec/PlistBuddy -c "print $i:KeyboardLanguage" /dev/stdin <<< $keyboards)</result>"
        exit 0
    fi
    i=$(($i+1))
done