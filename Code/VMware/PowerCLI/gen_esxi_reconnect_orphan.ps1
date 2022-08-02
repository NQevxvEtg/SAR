
$ErrorActionPreference= 'silentlycontinue'
#############################################################
clear
Write-Host "Warning: This script will not work using Powershell ISE" -ForegroundColor Yellow -NoNewline
Write-Host ""
Write-Host "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
Write-Host "Start Login ID:"
Write-Host ""
Write-Host "--------------------------------------------------------"
Write-Host "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"


# Write-Host "Please enter the vCenter Username:" -ForegroundColor Yellow -NoNewline
# $username = Read-Host
# $password = Read-Host -assecurestring "Please enter your Password"
# $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))



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
	Write-Host "Ohoh!!"
	Start-Sleep -Seconds 2
	Exit
	 }
 }

$VIServer = $VCFQDN

Connect-VIServer -Server $VIServer -Protocol https -Credential (Get-Secret vcenter)

$Datastores=@(
'DEV1',
'DEV2',
'DEV3'
)

Write-Host 'Finding orphaned VMs...' -ForegroundColor Yellow
$VMs = Get-VM * | Where {$_.ExtensionData.Summary.Runtime.ConnectionState -eq "orphaned"} |  Select-Object -ExpandProperty name
Write-Host '\nDone' -ForegroundColor Yellow

 


$cmdlist=@() 

ForEach ($Datastore in $Datastores) {
	ForEach ($VM in $VMs) {
		$VM = $VM -replace " ", "\ "

		$cmd = "vim-cmd solo/registervm /vmfs/volumes/" + $Datastore + "/" + $VM + "/" + $VM + ".vmx"

		$cmdlist += $cmd
	}
}

$body = $cmdlist -join "`r`n" | Out-String

write-host $body
