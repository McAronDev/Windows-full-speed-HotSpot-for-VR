$wifiInterfaceName="Wi-Fi" # run "netsh wlan show interfaces" to get list of your interfaces
$wifiProfile="McAronNet_5G" # usually the same as your network SSID. To get list of profiles run "netsh wlan show profiles"

##self restart with admin privileges if needed
if (!
    #current role
    (New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    #is admin?
    )).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
) {
    #elevate script and exit current non-elevated runtime
    Start-Process `
        -FilePath 'powershell' `
        -ArgumentList (
            #flatten to single array
            '-File', $MyInvocation.MyCommand.Source, $args `
            | %{ $_ }
        ) `
        -Verb RunAs
    exit
}




$virtualDesktopProcessName="VirtualDesktop.Streamer"
$ErrorActionPreference = "Stop"

$connectionProfile = [Windows.Networking.Connectivity.NetworkInformation,Windows.Networking.Connectivity,ContentType=WindowsRuntime]::GetInternetConnectionProfile()
$tetheringManager = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager,Windows.Networking.NetworkOperators,ContentType=WindowsRuntime]::CreateFromConnectionProfile($connectionProfile)


function Get-AutoconfigStatusMessage {
    return netsh wlan show autoconfig | Select-String -CaseSensitive "`"$wifiInterfaceName`""
}

echo "Switching autoconfig off to get the correct 'disabled' state message to support different system languages."

$autoconfigOnStartMessage = Get-AutoconfigStatusMessage
netsh wlan set autoconfig enabled=no interface="$wifiInterfaceName"
$autoconfigDisabledMessage = Get-AutoconfigStatusMessage


if ("$autoconfigOnStartMessage" -eq "$autoconfigDisabledMessage") {
    echo "Starting configuration revert..."
	echo "Enabling autoconfig on wifi interface"
    netsh wlan set autoconfig enabled=yes interface="$wifiInterfaceName"
	
	if ($tetheringManager.TetheringOperationalState -ne 'Off'){
		echo "Turning off HotSpot"
		($tetheringManager.StopTetheringAsync()) > $null 
	}
	read-host "Configuration revert complete! Press ENTER to exit..."
	exit
}

echo "Starting wifi configuration..."
  
echo "Enabling autoconfig on wifi interface"
netsh wlan set autoconfig enabled=yes interface="$wifiInterfaceName"

netsh wlan connect name="$wifiProfile" interface="$wifiInterfaceName"
echo "Connecting to wifi..."

while(-not (Get-NetAdapter -Name "$wifiInterfaceName" | Where-Object { $_.Status -eq "Up" }))
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
read-host "Press ENTER to exit"
