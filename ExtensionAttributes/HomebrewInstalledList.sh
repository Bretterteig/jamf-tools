#!/bin/zsh
echo "<result>$(ls /usr/local/Cellar | grep -vE '^\.keepme')</result>"