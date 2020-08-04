#!/bin/zsh

# Shows whem the device was last booted

echo -n "<result>$(date -jf '%s' "$(sysctl kern.boottime | awk -F'= |,' '{print $2}')" '+%Y-%m-%d %T')</result>"