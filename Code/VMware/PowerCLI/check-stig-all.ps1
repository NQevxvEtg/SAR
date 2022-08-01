#############################################################

#############################################################
clear
Write-Host "---------------------------------------------------"
Write-Host "Start Login ID:"
Write-Host "---------------------------------------------------"
########### vCenter Connectivity Details ###########
Write-Host "Please enter the vCenter Host IP Address or FQDN:" -ForegroundColor Yellow -NoNewline
$VMHost = Read-Host

Write-Host "----------------------------------------------------"
Write-Host "The password for vCenter and ESXi host must be same!"
Write-Host "----------------------------------------------------"

Write-Host "Please enter the vCenter Username:" -ForegroundColor Yellow -NoNewline
$User = Read-Host
$password = Read-Host -assecurestring "Please enter your Password"
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
Connect-VIServer -Server $VMHost -User $User -Password $password
########### Please Enter the Cluster to Enable SSH ###########
Write-Host "Clusters Associated with this vCenter:" -ForegroundColor Green
$VMcluster = '*' 
ForEach ($VMcluster in (Get-Cluster -name $VMcluster)| sort)
{

Write-Host $VMcluster

}

Write-Host "Please enter the Cluster name:" -ForegroundColor Yellow -NoNewline
$VMcluster = Read-Host

$root = "root" 
$plink = "echo n | \\plink.exe"
foreach($esx in (Get-Cluster -Name $VMcluster | Get-VMHost)){
    $esxcli = Get-EsxCli -VMHost $esx
	
### start first command
Write-Host "Enabling SSH on $esx" -ForegroundColor Green
Get-VMHost $esx | Get-VMHostService | Where { $_.Key -eq "TSM-SSH" } | Start-VMHostService
$cmd = " esxcli software vib list | grep -i stig "
$remoteCommand = '"' + $cmd + '"'
Write-Host -Object "Executing Command on $esx, Please wait..." -ForegroundColor Yellow
$output = $plink + " " + "-ssh" + " " + $root + "@" + $esx + " " + "-pw" + " " + $password + " " + $remoteCommand
$message = Invoke-Expression -command $output
$message
Write-Host "Disabling SSH on $esx" -ForegroundColor Green
Get-VMHost $esx | Get-VMHostService | Where { $_.Key -eq "TSM-SSH" } | Stop-VMHostService -Confirm:$FALSE
### end first command

} 

Disconnect-VIServer $VMHost -Confirm:$false
Write-Host "---------------------------------------------------"
Write-Host "Logout from vcenter... Done:"
Write-Host "---------------------------------------------------"
