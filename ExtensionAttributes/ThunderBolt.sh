#!/bin/zsh

# This will list all connected ThunderBolt devices in a visual manner to see how devices are connected to each other.
# If you just want a plain list of devices you may want to change the prefix settings.

start_prefix=""
end_prefix="|- "
spacer="#"
spacer_multiplier="3"

spacer(){
    [[ $1 > 0 ]] && echo "$start_prefix$(printf %$(($1*${spacer_multiplier}))s | tr " " "$spacer")$end_prefix"
}

getChildItems(){
    local name="$(/usr/libexec/PlistBuddy -c "Print :device_name_key" /dev/stdin <<<$1 2>/dev/null)"
    local manu="$(/usr/libexec/PlistBuddy -c "Print :vendor_name_key" /dev/stdin <<<$1 2>/dev/null)"
    local serial="$(/usr/libexec/PlistBuddy -c "Print :serial_num" /dev/stdin <<<$1 2>/dev/null)"

    local items="$(/usr/libexec/PlistBuddy -x -c "Print :_items" /dev/stdin <<<$1 2>/dev/null)"

	if [[ -z $items ]] && [[ $2 == "0" ]];then return;fi

    [[ -n $name ]] && echo "$(spacer "$2")$([[ -n $manu ]] && echo "$manu: ")$name$([[ -n $serial ]] && echo " (SN $serial)")"

    if [[ -n $items ]];then
        local i=0
        while /usr/libexec/PlistBuddy -c "Print :${i}:" /dev/stdin <<<$items &>/dev/null;do
            getChildItems "$(/usr/libexec/PlistBuddy -x -c "Print :${i}:" /dev/stdin <<<$items 2>/dev/null)" "$(($2+1))"
            i=$((i+1))
        done
    fi
}

output="$(getChildItems "$(/usr/libexec/PlistBuddy -x -c 'Print :0' /dev/stdin <<< "$(system_profiler -detailLevel mini SPThunderboltDataType -xml)")" "-1")"
if [[ -n $output ]];then
	echo "<result>$output</result>"
else
	echo "<result>Nothing</result>"
fi