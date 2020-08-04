#!/bin/zsh

# Recursively through all connected displays and returns their serial, resolution, name and date of build.
# If needed you can exclude certain displays by adding their name in the array below (e.g "Color LCD" for MacBook internal screen)
ignore_displays=("")

getChildItems(){
    local name="$(/usr/libexec/PlistBuddy -c "Print :_name" /dev/stdin <<<$1 2>/dev/null)"

    local year=$(/usr/libexec/PlistBuddy -c "Print :_spdisplays_display-year" /dev/stdin <<<$1 2>/dev/null)
    local week=$(/usr/libexec/PlistBuddy -c "Print :_spdisplays_display-week" /dev/stdin <<<$1 2>/dev/null)
    local serial=$(/usr/libexec/PlistBuddy -c "Print :spdisplays_display-serial-number" /dev/stdin <<<$1 2>/dev/null)
    local res=$(/usr/libexec/PlistBuddy -c "Print :_spdisplays_pixels" /dev/stdin <<<$1 2>/dev/null)
            
    local items="$(/usr/libexec/PlistBuddy -x -c "Print :spdisplays_ndrvs" /dev/stdin <<<$1 2>/dev/null)"
    [[ -z $items ]] && local items="$(/usr/libexec/PlistBuddy -x -c "Print :_items" /dev/stdin <<<$1 2>/dev/null)"

    if [[ $2 == "0" ]] && [[ -z $items ]];then
        return
    elif [[ $2 == "0" ]] && [[ -n $items ]];then
        echo "Attached to $(/usr/libexec/PlistBuddy -c "Print :sppci_model" /dev/stdin <<<$1 2>/dev/null):"
    fi

    if [[ -n $name ]] && [[ -n $res ]] && ! [[ ${ignore_displays[@]} =~ ${name} ]];then
        local date=$(date -jf "%Y-%V" "$year-$week" +"%d-%m-%Y")
        echo "${name} (${res}) BUILD: ${date}$([[ -n $serial ]] && echo " SN: ${serial}")"
    fi

    if [[ -n $items ]];then
        local i=0
        while /usr/libexec/PlistBuddy -c "Print :${i}:" /dev/stdin <<<$items &>/dev/null;do
            getChildItems "$(/usr/libexec/PlistBuddy -x -c "Print :${i}:" /dev/stdin <<<$items 2>/dev/null)" "$(($2+1))"
            i=$((i+1))
        done
    fi
}

echo -n "<result>"
getChildItems "$(/usr/libexec/PlistBuddy -x -c 'Print :0' /dev/stdin <<< "$(system_profiler SPDisplaysDataType -xml -detailLevel full)")" "-1"
echo -n "</result>"