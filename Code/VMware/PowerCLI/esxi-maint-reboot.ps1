# Check to make sure both arguments exist
if ($args.count -ne 2) {
Write-Host "Usage: reboot-vmcluster.ps1 <vCenter> <HostList.txt>"
exit
}
# Set vCenter and Cluster name from Arg
$vCenterServer = $args[0] 
$VIHosts = $args[1]

# Connect to vCenter
Connect-VIServer -Server $vCenterServer | Out-Null

# Get VMware Server Object based on name passed as arg
$ESXiServers = Get-Content $VIHosts | %{Get-VMHost $_}

# Reboot ESXi Server Function
Function RebootESXiServer ($CurrentServer) {
# Get VI-Server name
$ServerName = $CurrentServer.Name

# Put server in maintenance mode
Write-Host "** Rebooting $ServerName **"
Write-Host "Entering Maintenance Mode"
Set-VMhost $CurrentServer -State maintenance -Evacuate | Out-Null

# Reboot host
Write-Host "Rebooting"
Restart-VMHost $CurrentServer -confirm:$false | Out-Null


}

## MAIN
foreach ($ESXiServer in $ESXiServers) {
RebootESXiServer ($ESXiServer)
}

# Disconnect from vCenter
Disconnect-VIServer -Server $vCenterServer -Confirm:$False
