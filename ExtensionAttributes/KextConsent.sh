#!/bin/zsh

# Get wether kext control is on or off

echo "<result>$(spctl kext-consent status | awk -F': ' '{print toupper(substr($2,1,1))tolower(substr($2,2))}')</result>"