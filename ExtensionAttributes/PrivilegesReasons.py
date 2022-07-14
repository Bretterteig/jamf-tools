#!/usr/bin/env python3
import json, subprocess

# Configure
timespan = "14d"

# Gather data from log command
log_gathering = subprocess.Popen(['/usr/bin/log', 'show', '--last', timespan, '--style', 'json', '--predicate', 'process == "corp.sap.privileges.helper" AND "reason:" in eventMessage'], stderr=None, stdout=subprocess.PIPE)
log_output = log_gathering.communicate()[0].decode()
data = json.loads(log_output)

# Output
print('<result>', end='')
for event in data:
    print("- " + event['eventMessage'].split(': ')[2])
print('</result>', end='')