$wifiInterfaceName="WiFi" # run "netsh wlan show interfaces" to get list of your interfaces
$wifiProfile="McAronNet_5G" # usually the same as your network SSID. To get list of profiles run "netsh wlan show profiles"



$virtualDesktopProcessName="VirtualDesktop.Streamer"
$ErrorActionPreference = "Stop"

$connectionProfile = [Windows.Networking.Connectivity.NetworkInformation,Windows.Networking.Connectivity,ContentType=WindowsRuntime]::GetInternetConnectionProfile()
$tetheringManager = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager,Windows.Networking.NetworkOperators,ContentType=WindowsRuntime]::CreateFromConnectionProfile($connectionProfile)

if ((netsh wlan show autoconfig | Select-String -CaseSensitive "disabled on interface `"$wifiInterfaceName`"")){
	echo "Starting configuration revert..."
	echo "enabling autoconfig on wifi interface"
    netsh wlan set autoconfig enabled=yes interface="$wifiInterfaceName"
	
	if ($tetheringManager.TetheringOperationalState -ne 'Off'){
		echo "Turning off HotSpot"
		($tetheringManager.StopTetheringAsync()) > $null 
	}
	read-host "Configuration revert complete! Press ENTER to exit..."
	exit
}


echo "Starting wifi configuration..."
  
echo "enabling autoconfig on wifi interface"
netsh wlan set autoconfig enabled=yes interface="$wifiInterfaceName"

netsh wlan connect name="$wifiProfile" interface="$wifiInterfaceName"
echo "Connecting to wifi"

while(-not (netsh interface show interface | Select-String -CaseSensitive "Connected.+$wifiInterfaceName"))
{
    Start-Sleep -Seconds 1
	echo "Waiting for connection..."
}

echo "Starting Hotspot with half speed (client and hotspot simultaneously)"
($tetheringManager.StartTetheringAsync()) > $null  

while($tetheringManager.TetheringOperationalState -ne 'On')
{
	echo "Waiting for HotSpot start..."
    Start-Sleep -Seconds 1	
}


($tetheringManager.StopTetheringAsync()) > $null 
echo "Disconnecting wifi"
netsh wlan disconnect interface="$wifiInterfaceName"
echo "Starting Hotspot with full speed"
($tetheringManager.StartTetheringAsync()) > $null

while($tetheringManager.TetheringOperationalState -ne 'On' )
{
	echo "Waiting for HotSpot start..."
    Start-Sleep -Seconds 1	
}

try {
	$virtualDesktopPath=Get-Process -Name "$virtualDesktopProcessName" | Select -ExpandProperty Path 
	echo "stopping VirtualDesktop"
	Stop-Process -Name "$virtualDesktopProcessName" -Force
	echo "starting VirtualDesktop"
	Start-Process -FilePath "$virtualDesktopPath"
} 
catch {
	echo "VirtualDesktop is not running"
}

echo "disabling autoconfig on wifi interface"
netsh wlan set autoconfig enabled=no interface="$wifiInterfaceName"

echo "Complete! Run this script again to revert configuration."
read-host "Press ENTER to exit..."
