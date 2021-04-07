#!/bin/zsh
check_in_task="com.jamfsoftware.task.Every 15 Minutes" # Edit this line to fit your checkin task name
daemons=("com.jamfsoftware.jamf.daemon" "com.jamf.management.daemon" "$check_in_task")
problems=()

# Check if daemons have been loaded
for daemon in "${daemons[@]}";do
    if launchctl print-disabled system | grep -qi "$daemon" | grep -q "true";then
        problems+=("$daemon has been disabled.")
    fi

    if ! launchctl list "$daemon" &>/dev/null;then
        problems+=("$daemon has been unloaded.")
    fi
done

# Check if JSS is not blocked or not reachable
connection_check=$(/usr/local/bin/jamf checkJSSConnection)
if ! grep -qi "The JSS is available" <<< $connection_check;then
	problems+="$connection_check"
fi

# Check if last checkin returned an error
exit_code_checkin=$(launchctl print "system/$check_in_task" | awk -F'= ' '/last exit code/ {print $2}')
if [[ $exit_code_checkin != 0 ]];then
    problems+="Last checkin returned exit code $exit_code_checkin"
fi

# Output
if [[ -n $problems ]];then
    echo "<result>$(printf '%s\n' "${problems[@]}")</result>"
else
    echo "<result>Good</result>"
fi