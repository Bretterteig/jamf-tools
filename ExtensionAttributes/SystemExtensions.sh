#!/bin/zsh
echo "<result>$(/usr/bin/systemextensionsctl list | grep -vE '^enabled' | grep -v 'extension(s)' | cut -f-4)</result>"