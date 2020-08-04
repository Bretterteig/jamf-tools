#!/bin/zsh

# Shows the sudo history with info about what user wanted which command executed by which user. Also shows if permission was denied.
# You can limit the timespan by editing the --last parameter

echo "<result>$(/usr/bin/log show --last 3d --predicate 'process == "sudo" AND "COMMAND=" in eventMessage' --style "syslog" | grep -v "root :" | cut -d':' -f4- | tail -n +2 | sed -E 's% TTY=[a-z0-9]* ;%%g' | sed -E 's% PWD=[/A-Za-z0-9_\-\ ]*;%%g')</result>"