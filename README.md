Powershell script for setting your wifi interface as full speed HotSpot.

This script connects your PC to any available 5Ghz network to force run WiFi interface on full speed.

What you need to do:

0. You need to have any saved and available 5GHz network.
1. [Setup Mobile Hotspot](https://support.microsoft.com/en-us/windows/use-your-windows-pc-as-a-mobile-hotspot-c89b0fad-72d5-41e8-f7ea-406ad9036b85) on 5GHz. Set any another interface(another wifi dongle/ethernet/etc) to share internet through it. Don't activate hotspot.
2. You need to have any saved and available 5GHz network
3. Download powershell script VRHotSpot.ps1
4. Edit it. Set $wifiInterfaceName, $wifiProfile variables
5. Run it to start hotspot: Righ click => Run with PowerShell.
6. Run it again to revert changes


Tested on Lenovo Legion 5 with integrated Realtec RTL8852AE, Windows 11, Pico 4 : Runs full speed, up to 1200MBit/s with latency 4-15ms
