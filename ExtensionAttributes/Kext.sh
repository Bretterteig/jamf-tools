#!/bin/zsh
# This is only compatible with Big Sur. They changed the interfacing binary.

setopt sh_word_split
IFS=$'\n'

database_data="$(sqlite3 /var/db/SystemPolicyConfiguration/KextPolicy 'SELECT team_id,bundle_id,allowed FROM "kext_policy"')"
[[ -z $database_data ]] && exit 0

for line in $database_data;do
    data=("${(@s/|/)line}")

    teamid=$data[1]
    bundleid=$data[2]

    if [[ $data[3] == "1" ]];then
        allowed="GRANTED"
    else
        allowed="DENIED"
    fi

    if [[ -n "$(/usr/bin/kmutil showloaded --list-only --bundle-identifier "$bundleid" 2>/dev/null)" ]];then
        loaded="RUNNING"
    else
        loaded="INACTIVE"
    fi

    table=("[$allowed and $loaded] $bundleid ($teamid)" $table)
done

echo "<result>$(printf '%s\n' "${table[@]}" | sort)</result>"