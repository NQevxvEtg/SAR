$ErrorActionPreference= 'silentlycontinue'

# Check to make sure both arguments exist
if ($args.count -ne 1) {
Write-Host "Usage: reboot-vmcluster.ps1 <Host-FQDN-List.txt>"
exit
}

# get hosts
$VIHosts = $args[0]

#############################################################

Write-Host "Warning: This script will not work using Powershell ISE" -ForegroundColor Yellow 
Write-Host ""
Write-Host "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
Write-Host "Start Login ID:" -ForegroundColor Yellow 
Write-Host ""
Write-Host "The password for vCenter and ESXi host must be the same!" -ForegroundColor Yellow 
Write-Host "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
Write-Host ""

# Write-Host "Please enter the vCenter Username:" -ForegroundColor Yellow -NoNewline
# $username = Read-Host
# $password = Read-Host -assecurestring "Please enter your Password"
# $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))


$credential = (Get-Secret esxi)
# $username = $credential.GetNetworkCredential().username
$password = $credential.GetNetworkCredential().password

########### vCenter Connectivity Details ###########

function Show-Menu
{
    param (
        [string]$Title = 'vCenter Menu'
    )
    Clear-Host
    Write-Host "================ $Title ================"
    
    Write-Host "1: Press '1' for fqdn1"
    Write-Host "2: Press '2' for fqdn2"
    Write-Host "q: Press 'q' to quit."
}

Show-Menu –Title 'vCenter Menu'
$selection = Read-Host "Please select a vCenter"

switch ($selection)
 {
     '1' {
         $VCFQDN = 'fqdn1'
     } 
	 '2' {
         $VCFQDN = 'fqdn2'
     }  
	 'q' {
         return
     }
	 default { 
	Write-Host "Try again!!"
	Start-Sleep -Seconds 2
	Exit
	 }
 }



Write-Host 'Press any key to continue...' -ForegroundColor Green -NoNewline;
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

############################################################################################
$VIServer = $VCFQDN

Connect-VIServer -Server $VIServer -Protocol https -Credential (Get-Secret vcenter)

############################################################################################



# Get VMware Server Object based on name passed as arg
$ESXiServers = Get-Content $VIHosts | %{Get-VMHost $_}

# Reboot ESXi Server Function
Function RebootESXiServer ($CurrentServer) {
# Get VI-Server name
$ServerName = $CurrentServer.Name

Write-Host $ServerName

Write-Host "Exit lockdown mode"
$vmhost = Get-VMHost -Name $ServerName
(Get-VMHost $vmhost | Get-View).ExitLockdownMode()

Write-Host "Entering maintenance mode"
Set-VMHost $CurrentServer -State maintenance -Evacuate | Out-Null

Write-Host "Rebooting"
Restart-VMHost $CurrentServer -confirm:$false | Out-Null

}

## MAIN
foreach ($ESXiServer in $ESXiServers) {
RebootESXiServer ($ESXiServer)
}

# Disconnect from vCenter
Disconnect-VIServer -Server $VIServer -Confirm:$False
