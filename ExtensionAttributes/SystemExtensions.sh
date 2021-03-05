#!/bin/zsh
extensions=$(/usr/libexec/PlistBuddy -x -c 'print extensions' /Library/SystemExtensions/db.plist)

i=0
while data=$(/usr/libexec/PlistBuddy -x -c "print $i" /dev/stdin <<< $extensions 2>/dev/null);do
    teamid="$(/usr/libexec/PlistBuddy -c 'print teamID' /dev/stdin <<< $data)"
    identifier="$(/usr/libexec/PlistBuddy -c 'print identifier' /dev/stdin <<< $data)"
    state="$(/usr/libexec/PlistBuddy -c 'print state' /dev/stdin <<< $data)"

    table=("[${state:u}] $identifier ("$teamid")" $table)

    i=$(($i+1))
done

echo "<result>$(printf '%s\n' "${table[@]}" | sort)</result>"