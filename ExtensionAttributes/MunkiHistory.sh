#!/bin/zsh

# Munki install history. Limited by lines and/or date

max_lines=20
max_days=14

setopt sh_word_split

if ! [[ -r "/Library/Managed Installs/Logs/Install.log" ]];then
	echo "<result>None</result>"
	exit 0
fi

data=$(tail -n $max_lines "/Library/Managed Installs/Logs/Install.log")
max_days_in_seconds="$(($max_days*24*60*60))"
current_unix_timestamp="$(date +%s)"
last_allowed_timestamp="$(($current_unix_timestamp-$max_days_in_seconds))"

IFS=$'\n'
for line in $data;do
    date="$(echo $line | cut -f-5 -d ' ')"
    line_timestamp="$(date -j -f '%h %d %Y %T %z' "$date" '+%s')"
    if (($line_timestamp>$last_allowed_timestamp));then
        output+=("$(date -jf '%s' "$line_timestamp" '+%d.%m.%y %H:%M') $(echo $line | cut -f6- -d ' ')")
    fi
done

echo -n "<result>"
if [[ -n $output ]];then
	printf '%s\n' "${output[@]}"
else
	echo "None"
fi
echo -n "</result>"