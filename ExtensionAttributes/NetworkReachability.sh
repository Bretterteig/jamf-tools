#!/bin/zsh

# Check if the given address are reachable. 

addresses=("your.ldap.server.here:636" "Some.website:443" "8.8.8.8")

for address in ${addresses[@]};do
    port=$(echo $address | awk -F':' '{print $2}')
    server=$(echo $address | awk -F':' '{print $1}')
    if [[ -n $port ]];then
        if nc -z "$server" "$port" &>/dev/null;then
            output+=("SUCC | $address")
        else
            output+=("FAIL | $address")
        fi
    else
        if ping -W 300 -c 1 -o "$server" &>/dev/null;then
            output+=("OK | $address")
        else
            output+=("FAIL | $address")
        fi
    fi
done

echo "<result>$(printf '%b\n' "${output[@]}")</result>"