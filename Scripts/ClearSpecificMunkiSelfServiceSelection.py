#!/usr/local/munki/munki-python

# Use the arguments to specify software titles that should be deleted from optional install selection

import plistlib, sys

# Import manifest
with open("/Library/Managed Installs/manifests/SelfServeManifest", 'rb') as plist:
    data = plistlib.load(plist)

# Get removals from arguments (jamf)
remove = sys.argv[4:]
# Remove them from list
data['managed_installs'] = [ item for item in data['managed_installs'] if item not in remove]

# Save changes
with open("/Library/Managed Installs/manifests/SelfServeManifest", 'wb') as plist:
    plistlib.dump(data, plist)