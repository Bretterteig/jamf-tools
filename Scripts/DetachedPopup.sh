#!/bin/zsh
windowtitle="$4"
notificationtitle="$5"
text="$6"
iconpath="$7"

user="$(/usr/sbin/scutil <<<"show State:/Users/ConsoleUser" | /usr/bin/awk -F': ' '/[[:space:]]+Name[[:space:]]:/ { print $2 }')"

function daemonize(){
    for argument in $@;do ProgramArguments+="<string>$argument</string>" done
    time="$(date +%s)" && program="$(basename ${1})"

    cat << EOF > "/tmp/com.trustedshops.${program}${time}.plist"
    <?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>Label</key><string>com.trustedshops.${program}${time}</string>
      <key>RunAtLoad</key><true/>
      <key>ProgramArguments</key>
      <array>
        ${ProgramArguments[@]}
      </array>
    </dict>
    </plist>
EOF
    launchctl bootstrap "gui/$(id -u ${user})" "/tmp/com.trustedshops.${program}${time}.plist"
    rm -f "/tmp/com.trustedshops.${program}${time}.plist"
}

daemonize /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType hud -title "$windowtitle" -heading "$notificationtitle" -description "$text" -button1 "Ok" -icon "$iconpath"