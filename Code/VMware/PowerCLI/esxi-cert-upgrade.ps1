
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
    
    Write-Host "1: Press '1' for fqdn"
    Write-Host "2: Press '2' for fqdn"
    Write-Host "q: Press 'q' to quit."
}

Show-Menu –Title 'vCenter Menu'
$selection = Read-Host "Please select a vCenter"

switch ($selection)
 {
     '1' {
         $VCFQDN = 'fqdn'
     } 
	 '2' {
         $VCFQDN = 'fqdn'
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


$ESXI_PATH='\\ssl\'
Write-Host $ESXI_PATH

$ESXI_cer=$ESXI_PATH+'cer\'


$ESXI_key=$ESXI_PATH+'key\'


$cer = $ESXI_cer+$ESXFQDN+'.cer'
$key = $ESXI_key+$ESXHost+'.key'

Write-Host $cer
Write-Host $key

$cer_content = (Get-Content $cer -Raw)  | Foreach-Object {$_ -replace "-.*", "" } 
$key_content = (Get-Content $key -Raw)  | Foreach-Object {$_ -replace "-.*", "" } 



Write-Host $cer_content
Write-Host $key_content


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

start first command
Write-Host "Enabling SSH on $esx" -ForegroundColor Green
Get-VMHost $esx | Get-VMHostService | Where { $_.Key -eq "TSM-SSH" } | Start-VMHostService

$cert_path = '/etc/vmware/ssl/rui.crt'
$key_path = '/etc/vmware/ssl/rui.key'


$cmd1 = " tee " + $cert_path + " << 'EOF' " + $cer_content 
$cmd2 = " tee " + $key_path + " << 'EOF' " + $key_content 

$cmd3 = " sed -i '/^[[:space:]]*$/d' " + $cert_path + " && sed -i '1s/^/-----BEGIN CERTIFICATE-----\n/' " + $cert_path + " && echo '-----END CERTIFICATE-----' >> " + $cert_path + " && sed -i '/^[[:space:]]*$/d' " + $key_path + " && sed -i '1s/^/-----BEGIN PRIVATE KEY-----\n/' " + $key_path + " && echo '-----END PRIVATE KEY-----' >>  " + $key_path + " && /etc/init.d/hostd restart && /etc/init.d/vpxa restart "


Write-Host -Object "Executing Command on $esx, Please wait..." -ForegroundColor Yellow

$remoteCommand1 = '"' + $cmd1 + '"'
$output1 = $plink + " " + "-ssh" + " " + $root + "@" + $esx + " " + "-pw" + " " + $password + " " + $remoteCommand1
$message1 = Invoke-Expression -command $output1
$message1

$remoteCommand2 = '"' + $cmd2 + '"'
$output2 = $plink + " " + "-ssh" + " " + $root + "@" + $esx + " " + "-pw" + " " + $password + " " + $remoteCommand2
$message2 = Invoke-Expression -command $output2
$message2

$remoteCommand3 = '"' + $cmd3 + '"'
$output3 = $plink + " " + "-ssh" + " " + $root + "@" + $esx + " " + "-pw" + " " + $password + " " + $remoteCommand3
$message3 = Invoke-Expression -command $output3
$message3



Write-Host "Done" -ForegroundColor Green
