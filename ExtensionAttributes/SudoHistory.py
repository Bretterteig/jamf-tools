#!/usr/bin/env python3
import json, subprocess, re

# Configure
timespan = "3d"


# Gather data from log command
log_gathering = subprocess.Popen(['/usr/bin/log', 'show', '--last', timespan, '--style', 'json', '--predicate', 'process == "sudo" AND "COMMAND=" in eventMessage'], stderr=None, stdout=subprocess.PIPE)
log_output = log_gathering.communicate()[0].decode()
data = json.loads(log_output)

# Parse the event message to a list of event objects
events = []
for event in data:
    try:
        error = re.search(': +(?![A-Z]+=).+?;', event['eventMessage'])[0].lstrip(': ').rstrip(' ;')
    except:
        error = None

    events.append({
        'user': event['eventMessage'].split(':')[0].strip(),
        'as_user': re.search('USER=[a-zA-Z0-9\_\-]+', event['eventMessage'])[0].lstrip('USER='),
        'command': re.search('COMMAND=.+', event['eventMessage'])[0].lstrip('COMMAND='),
        'error': error
    })

# Make the list unique
unique_events = [dict(s) for s in set(frozenset(d.items()) for d in events)]

# Output
for event in unique_events:
    message = event['user'] + ' (' + event['as_user'] + '): ' + event['command']
    if event['error']:
        message = '[ERR] ' + message + ' (' + event['error'] + ')'
    else:
         message = '[OK] ' + message
    print(message)