#!/usr/local/munki/munki-python
import os, getpass, subprocess, uuid, sys
import Foundation

user = sys.argv[3]
user_home = subprocess.check_output(['/usr/bin/dscl', '.', 'read', '/Users/{user}'.format(user=user), 'NFSHomeDirectory']).decode().split(':')[1].strip()
favorites_path = "{user_home}/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.FavoriteServers.sfl2".format(user_home=user_home)
mode = sys.argv[4][0:3].lower()
servers = [s for s in sys.argv[5:] if s is not None and s != ""]

def write_to_sfl2(servers):
    # generate necessary structures
    if len(servers) == 0:
        print('Server list is empty.')
        exit(0)
    
    items = []
    for name, path in servers:
        item = {}
        # use unicode to translate to NSString
        item["Name"] = name
        url = Foundation.NSURL.URLWithString_(path)
        bookmark, _ = url.bookmarkDataWithOptions_includingResourceValuesForKeys_relativeToURL_error_(0, None, None, None)
        item["Bookmark"] = bookmark
        # generate a new UUID for each server
        item["uuid"] = str(uuid.uuid1()).upper()
        item["visibility"] = 0
        item["CustomItemProperties"] = Foundation.NSDictionary.new()

        items.append(Foundation.NSDictionary.dictionaryWithDictionary_(item))

    data = Foundation.NSDictionary.dictionaryWithDictionary_({
        "items": Foundation.NSArray.arrayWithArray_(items),
        "properties": Foundation.NSDictionary.dictionaryWithDictionary_({"com.apple.LSSharedFileList.ForceTemplateIcons": False})
    })

    # write sfl2 file
    try:
        Foundation.NSKeyedArchiver.archiveRootObject_toFile_(data, favorites_path)
    except Exception as e:
        print("Error while saving configuration:\n{}".format(e)) 

def get_existing_servers():
    "Get the Server Favorites for the given user"

    # read existing favorites file
    data = Foundation.NSKeyedUnarchiver.unarchiveObjectWithFile_(favorites_path)

    existing_servers = []

    # read existing items safely
    if data is not None:
        data_items = data.get("items", [])

        # read existing servers
        for item in data_items:
            name = item["Name"]
            url, _, _ = Foundation.NSURL.initByResolvingBookmarkData_options_relativeToURL_bookmarkDataIsStale_error_(Foundation.NSURL.alloc(), item["Bookmark"], Foundation.NSURLBookmarkResolutionWithoutUI, None, None, None)
            url = str(url)
            existing_servers.append((name, url))
    
    return existing_servers

def add_favorites(servers):
    # get unique ordered list of all servers
    all_servers = []
    existing_servers = get_existing_servers()

    # add existing_servers to list, updating name if necessary
    for s in existing_servers:
        try:
            idx = [a[1] for a in servers].index(s[1])
            all_servers.append((servers[idx][0], s[1]))
        except ValueError:
            all_servers.append(s)

    # add add_servers if not present already
    for s in servers:
        if s not in [e[1] for e in existing_servers]:
            all_servers.append((s,s))

    write_to_sfl2(all_servers)

def remove_favorites(servers):
    all_servers = get_existing_servers()

    # remove old servers: exact match
    all_servers = [s for s in all_servers if s[1] not in servers]

    # remove old servers: shares
    # matches "smb://old.domain/*"
    all_servers = [s for s in all_servers if len(
        [True for r in servers if r.endswith("*") and s[1].startswith(r[:-1])]
    ) < 1]

    write_to_sfl2(all_servers)

if __name__ == "__main__":
    try:
        if mode == "add":
            add_favorites(servers)
            print("Added servers for " + user)
        elif mode == "rem":
            remove_favorites(servers)
            print("Removed servers for " + user)
        else:
            print("No valid mode was selected. Please use ADD/REMOVE")
            exit(1)
        
        if os.path.exists(favorites_path):
        	os.system(("chown {user}:staff '".format(user=user) + favorites_path + "'"))
        	os.system(("chmod 644 '" + favorites_path + "'"))
        else:
            print("Favorites file was not found.")
            exit(1)

    except Exception as e:
        # if there's an error, log it an continue on
        print("Failed setting Server Favorites.")
            
    os.system("killall sharedfilelistd &>/dev/null")
