#!/usr/bin/env python3
from ssl import SSLContext
from sys import argv
import json, subprocess, urllib.parse, urllib.request

# API user credentials!
api_client_id = argv[4]
api_client_secret = argv[5]

# Functions
def invert_characters_at_interval(input: str, interval: int) -> str:
    chunks = [input[i:i+interval] for i in range(0, len(input), interval)]
    return "".join([e[::-1] for e in chunks])

def decrypt_sophos_id(encrypted_id: str) -> str:
    inverted_sections=[]
    for section in encrypted_id.split("-"):
        inverted_sections.append(invert_characters_at_interval(section,2))
    return "-".join(inverted_sections)

def send_request(req: urllib.request) -> dict:
    try:
        with urllib.request.urlopen(req, context=ssl_context) as response:
            return json.loads(response.read().decode())
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(body)
        exit()


# Variables (do not edit)
ssl_context = SSLContext()
encrypted_client_id = subprocess.run(['/usr/bin/defaults', 'read', '/Library/Preferences/com.sophos.mcs.plist', 'SMEMcsEndpointUUID'], stdout=subprocess.PIPE).stdout.decode().rstrip()
client_id = decrypt_sophos_id(encrypted_client_id)



# Get an OAuth2 token
request_data = urllib.parse.urlencode({
    'grant_type': 'client_credentials',
    'client_id': api_client_id,
    'client_secret': api_client_secret,
    'scope': 'token'
}).encode('ascii')
req = urllib.request.Request(
    'https://id.sophos.com/api/v2/oauth2/token', 
    headers = {'Content-Type': 'application/x-www-form-urlencoded'}, 
    data = request_data
)
oauth = send_request(req)

# Stop if OAuth was not successful
if not 'errorCode' in oauth or not oauth['errorCode'] == 'success' :
    print("Authentication error")
    exit(1)
else:
    print("OAuth authentication successful")



# Request tenant info
req = urllib.request.Request(
    'https://api.central.sophos.com/whoami/v1',
    headers={
        'Authorization': 'Bearer ' + oauth['access_token'],
        'Accept': 'application/json'
    }
)
tenant = send_request(req)
if not 'id' in tenant:
    print("Could not get tenant information from whoami API")
    exit(1)
print("Determined tenant id " + tenant['id'])



# Get endpoint
req = urllib.request.Request(
    tenant['apiHosts']['dataRegion'] + '/endpoint/v1/endpoints/' + client_id,
    headers={
        'Authorization': 'Bearer ' + oauth['access_token'],
        'X-Tenant-ID': tenant['id'],
        'Accept': 'application/json'
    }
)
matched_computer = send_request(req)

if 'id' not in matched_computer or matched_computer['id'] is None:
    print("Device not found.")
    exit(0)
else:
    print("Device with id " + matched_computer['id'] + " in Sophos Central")



# Delete endpoint
req = urllib.request.Request(
    tenant['apiHosts']['dataRegion'] + '/endpoint/v1/endpoints/' + matched_computer['id'],
    headers={
        'Authorization': 'Bearer ' + oauth['access_token'],
        'X-Tenant-ID': tenant['id'],
        'Accept': 'application/json'        
    },
    method='DELETE'
)

response = send_request(req)
print(response)