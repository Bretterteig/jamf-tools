#!/bin/zsh
# Shows all user options for TCC policys. It shows the service, client and if it is allowed or not. (Only listed if shown to the user)
# Profile overrides are not shown here. Override data could be read from /Library/Application\ Support/com.apple.TCC/MDMOverrides.plis (TODO?)

setopt sh_word_split
IFS=$'\n'

# Get data from database
database_data="$(sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db 'SELECT service,client,allowed from "access"')"
if [[ -z $database_data ]];then
    echo "<result>Could not read TCC.db or db is empty</result>"
    exit 1
fi

# Interate over each line in data
for line in $database_data;do
    # Get service and program. 
    service="$(echo "$line" | awk -F'|' '{print $1}')"
    client="$(echo "$line" | awk -F'|' '{print $2}')"
    user_allowed="$(echo "$line" | awk -F'|' '{print $3}')"

    if [[ $user_allowed == "1" ]];then
        user_allowed="GRANTED"
    else
        user_allowed="DENIED"
    fi

    # Build table data
    table="$service: \"$client\" $user_allowed\n$table"
done

# Remove prefix and sort data so it is more readable.
final_data="$(echo "$table" | sed s%kTCCService%% | sed s%SystemPolicy%% | sort | sed -E /^$/d)"
echo "<result>$final_data</result>"