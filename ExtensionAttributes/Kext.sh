#!/bin/zsh
setopt sh_word_split
IFS=$'\n'

database_data="$(sqlite3 /var/db/SystemPolicyConfiguration/KextPolicy 'SELECT team_id,bundle_id,allowed FROM "kext_policy"')"
if [[ -z $database_data ]];then
    echo "<result>Could not read KextPolicy db or it is empty</result>"
    exit 1
fi

for line in $database_data;do
    # Get service and program. 
    teamid="$(echo "$line" | awk -F'|' '{print $1}')"
    bundleid="$(echo "$line" | awk -F'|' '{print $2}')"
    allowed="$(echo "$line" | awk -F'|' '{print $3}')"

    if [[ $allowed == "1" ]];then
        allowed="GRANTED"
    else
        allowed="DENIED"
    fi

    if [[ -n "$(/usr/bin/kmutil showloaded --list-only --bundle-identifier "$bundleid")" ]];then
        loaded="RUNNING"
    else
        loaded="INACTIVE"
    fi
    # Build table data
    table="[$allowed and $loaded] $bundleid (TID: $teamid)\n$table"
done

# Remove prefix and sort data so it is more readable.
final_data="$(echo "$table" | sed s%kTCCService%% | sed s%SystemPolicy%% | sort | sed -E /^$/d)"
echo "<result>$final_data</result>"