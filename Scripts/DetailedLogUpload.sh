#!/bin/zsh

# This script generates a very detailed collection of logs. It then zips it and uploads it as a file attachment

APIUSER=${4}
APIPASS=${5}



logDir="/tmp/log_collection"
rm -rf "$logDir"
mkdir -p $logDir/system/system_profiler
mkdir -p $logDir/user

# System Profiler
/usr/sbin/system_profiler -detaillevel full SPFontsDataType > $logDir/system/system_profiler/fonts.log 2>/dev/null
/usr/sbin/system_profiler -detaillevel full SPiBridgeDataType SPDiagnosticsDataType SPDisplaysDataType SPHardwareDataType SPMemoryDataType SPStorageDataType SPNVMeDataType SPSerialATADataType SPPCIDataType SPPowerDataType SPSerialATADataType > $logDir/system/system_profiler/hardware.log 2>/dev/null
/usr/sbin/system_profiler -detaillevel full SPAudioDataType SPBluetoothDataType SPCameraDataType SPCardReaderDataType SPDisplaysDataType SPThunderboltDataType SPUSBDataType > $logDir/system/system_profiler/connected_devices.log 2>/dev/null
/usr/sbin/system_profiler -detaillevel full SPSoftwareDataType SPInternationalDataType SPUniversalAccessDataType SPDeveloperToolsDataType SPDisabledSoftwareDataType SPStartupItemDataType > $logDir/system/system_profiler/system.log 2>/dev/null
/usr/sbin/system_profiler -detaillevel full SPEthernetDataType SPFirewallDataType SPNetworkLocationDataType SPNetworkDataType SPWWANDataType SPNetworkVolumeDataType > $logDir/system/system_profiler/network.log 2>/dev/null
/usr/sbin/system_profiler -detaillevel full SPApplicationsDataType SPInstallHistoryDataType SPLegacySoftwareDataType > $logDir/system/system_profiler/software.log 2>/dev/null
/usr/sbin/system_profiler -detaillevel full SPPrintersDataType SPPrintersSoftwareDataType > $logDir/system/system_profiler/printers.log 2>/dev/null

# System info
launchctl list | grep -v com.apple > $logDir/system/daemons.log
memory_pressure > $logDir/system/memory_pressure.log
ps -ef > $logDir/system/processes.txt
sysctl -a > $logDir/system/sysctl.txt
iostat > $logDir/system/iostat.txt
ulimit -a > $logDir/system/ulimit.txt
uptime > $logDir/system/uptime.txt
kextstat | grep -v com.apple > $logDir/system/kextstat.txt
lsof -iTCP -sTCP:LISTEN -n -P > $logDir/system/tcp_listen.txt
cp /etc/group $logDir/system/groups.txt
cp /etc/hosts $logDir/system/hosts.txt
cp /etc/resolv.conf $logDir/system/resolv.conf
cp -R /etc/periodic/ $logDir/system/periodic
cp /etc/sudoers $logDir/system/sudoers.txt


# Collect all logs files
cp -R /var/log $logDir/system/var_logs
cp -R /Library/Logs $logDir/system/lib_logs


for user in $(ls /Users/ | grep -v "Shared" | grep -v ".localized");do
	mkdir -p $logDir/user/$user
    cp -R "/Users/$user/Library/Logs" $logDir/user/$user/lib_logs

    #mkdir -p $logDir/user/$user/SonicWall
    #cp /Users/$user/Library/Group\ Containers/3KRRBEHHYE.com.sonicwall.mobileconnect/NxPlugin.log* $logDir/user/$user/SonicWall/
    #cp /Users/$user/Library/Containers/com.sonicwall.SonicWALL-Mobile-Connect/Data/Documents/console.log $logDir/user/$user/SonicWall/
done


chmod -R a+rwx $logDir

zipName=/tmp/$(date "+[%d-%m-%y %H:%M:%S]")log_collection.zip

cd $logDir
zip -r $zipName . 1>/dev/null

curl -u "$APIUSER:$APIPASS" -X POST "$(defaults read /Library/Preferences/com.jamfsoftware.jamf jss_url)JSSResource/fileuploads/computers/name/$(jamf getComputerName | xpath "//text()" 2>/dev/null)" -H "accept: application/xml" -F name=@$zipName