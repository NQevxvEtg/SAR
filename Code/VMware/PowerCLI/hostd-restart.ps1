
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
	Write-Host "wow!!"
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


$root = "root" 
$plink = "echo n | \\plink.exe"


$esx = $hostname
$esxcli = Get-EsxCli -VMHost $esx -v2

# start first command
Write-Host "Enabling SSH on $esx" -ForegroundColor Green
Get-VMHost $esx | Get-VMHostService | Where { $_.Key -eq "TSM-SSH" } | Start-VMHostService

$cmd = "/etc/init.d/hostd restart && /etc/init.d/vpxa restart"

$remoteCommand = '"' + $cmd + '"'
Write-Host -Object "Executing Command on $esx, Please wait..." -ForegroundColor Yellow
$output = $plink + " " + "-ssh" + " " + $root + "@" + $esx + " " + "-pw" + " " + $password + " " + $remoteCommand
$message = Invoke-Expression -command $output
$message
Write-Host "Disabling SSH on $esx" -ForegroundColor Green

Write-Host "Wating 15 seconds before stopping SSH service..." -ForegroundColor Green
# end first command
Start-Sleep -s 15
Get-VMHost $esx | Get-VMHostService | Where { $_.Key -eq "TSM-SSH" } | Stop-VMHostService -Confirm:$FALSE


Set-VMhost $hostname -State connected | Out-Null
(Get-VMHost $vmhost | Get-View).EnterLockdownMode()

Disconnect-VIServer $VIServer -Confirm:$false
Write-Host "---------------------------------------------------"
Write-Host "Hostd restarted successfully!"
Write-Host "---------------------------------------------------"
