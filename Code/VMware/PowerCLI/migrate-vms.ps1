
$ErrorActionPreference= 'silentlycontinue'
#############################################################
clear
Write-Host "Warning: This script will not work using Powershell ISE" -ForegroundColor Yellow -NoNewline
Write-Host ""
Write-Host "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
Write-Host "Start Login ID:"
Write-Host ""
Write-Host "PSCredentials must be configured first!"
Write-Host "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"


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
	Write-Host "Failed!!"
	Start-Sleep -Seconds 2
	Exit
	 }
 }



Write-Host "Please enter the source ESXi name:" -ForegroundColor Yellow -NoNewline
$ESXiHostSrc = Read-Host
$ESXiHostSrcFQDN = "$ESXiHostSrc.fqdn"


Write-Host "Please enter the destination ESXi name:" -ForegroundColor Yellow -NoNewline
$ESXiHostDst = Read-Host
$ESXiHostDstFQDN = "$ESXiHostDst.fqdn"


Write-Host "you entered $VCFQDN and you want to migrate VMs from $ESXiHostSrcFQDN to $ESXiHostDstFQDN " 

Write-Host 'Press any key to continue...' -ForegroundColor Green -NoNewline;
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

############################################################################################
$VIServer = $VCFQDN

Connect-VIServer -Server $VIServer -Protocol https -Credential (Get-Secret vcenter)


$vmList = Get-VMHost $ESXiHostSrcFQDN | Get-VM

write-host $vmList

Get-VM $vmList | move-vm -destination (get-vmhost $ESXiHostDstFQDN)





