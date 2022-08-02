
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

# write-host $username 
# write-host $password

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
	Write-Host "LOL!!"
	Start-Sleep -Seconds 2
	Exit
	 }
 }



Write-Host "Please enter the ESXi name:" -ForegroundColor Yellow -NoNewline
$ESXHost = Read-Host

Write-Host "Please enter the Datastore name (case sensitive):" -ForegroundColor Yellow -NoNewline
$Datastore = Read-Host

Write-Host "Please enter the VM name (case sensitive):" -ForegroundColor Yellow -NoNewline
$VM = Read-Host


$ESXFQDN = "$ESXHost.fqdn"


$VM = $VM -replace " ", "\ " 
Write-Host "You entered $VCFQDN, $ESXFQDN, $Datastore, $VM" -ForegroundColor Yellow

Write-Host 'Press any key to continue...' -ForegroundColor Green -NoNewline;
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');



$VIServer = $VCFQDN

Connect-VIServer -Server $VIServer -Protocol https -Credential (Get-Secret vcenter)

$hostname = $ESXFQDN
$vmhost = Get-VMHost -Name $hostname

(Get-VMHost $vmhost | Get-View).ExitLockdownMode()

$root = "root" 
$plink = "echo n | \\plink.exe"


$esx = $hostname
$esxcli = Get-EsxCli -VMHost $esx -v2

# start first command
Write-Host "Enabling SSH on $esx" -ForegroundColor Green
Get-VMHost $esx | Get-VMHostService | Where { $_.Key -eq "TSM-SSH" } | Start-VMHostService

$cmd = "vim-cmd solo/registervm /vmfs/volumes/" + $Datastore + "/" + $VM + "/" + $VM + ".vmx"

$remoteCommand = '"' + $cmd + '"'
Write-Host -Object "Executing Command on $esx, Please wait..." -ForegroundColor Yellow
$output = $plink + " " + "-ssh" + " " + $root + "@" + $esx + " " + "-pw" + " " + $password + " " + $remoteCommand
$message = Invoke-Expression -command $output
$message
Write-Host "Done" -ForegroundColor Green
