
$ErrorActionPreference= 'silentlycontinue'
#############################################################
clear
Write-Host "Warning: This script will not work using Powershell ISE" -ForegroundColor Yellow 
Write-Host ""
Write-Host "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
Write-Host "Start Login ID:" -ForegroundColor Yellow 
Write-Host ""
Write-Host "PSCredentials must be configured first!" -ForegroundColor Yellow 
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
	Write-Host "Try Again!!"
	Start-Sleep -Seconds 2
	Exit
	 }
 }



Write-Host "Please enter the ESXi name:" -ForegroundColor Yellow -NoNewline
$ESXHost = Read-Host


$ESXFQDN = "$ESXHost.fqdn"
Write-Host "you entered $VCFQDN and $ESXFQDN" 

Write-Host 'Press any key to continue...' -ForegroundColor Green -NoNewline;
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

############################################################################################
$VIServer = $VCFQDN

Connect-VIServer -Server $VIServer -Protocol https -Credential (Get-Secret vcenter)

$hostname = $ESXFQDN
$vmhost = Get-VMHost -Name $hostname

(Get-VMHost $vmhost | Get-View).ExitLockdownMode()

Set-VMhost $hostname -State maintenance -Evacuate | Out-Null

Restart-VMHost $hostname -confirm:$false | Out-Null

Disconnect-VIServer $VIServer -Confirm:$false
Write-Host "---------------------------------------------------"
Write-Host "$hostname restarted"
Write-Host "---------------------------------------------------"
