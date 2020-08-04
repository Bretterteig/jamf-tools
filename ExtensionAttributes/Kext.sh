#!/bin/zsh

# This extension attribute lists all KernalExtension policys. Beware that this only shows user options. 
# Profile overrides are not displayed here. If profile is applied the shown data can be ignored.
setopt sh_word_split
IFS=$'\n'

database_data="$(sqlite3 /var/db/SystemPolicyConfiguration/KextPolicy 'SELECT team_id,bundle_id,allowed FROM "kext_policy"')"
if [[ -z $database_data ]];then
    echo "<result>Could not read KextPolicyDB or it is empty</result>"
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

    if [[ -n "$(kextstat -lb "$bundleid")" ]];then
        loaded="ACTIVE"
    else
        loaded="INACTIVE"
    fi
    # Build table data
    table="[$allowed and $loaded] $bundleid (TID: $teamid)\n$table"
done

# Remove prefix and sort data so it is more readable.
final_data="$(echo "$table" | sed s%kTCCService%% | sed s%SystemPolicy%% | sort | sed -E /^$/d)"
echo "<result>$final_data</result>"