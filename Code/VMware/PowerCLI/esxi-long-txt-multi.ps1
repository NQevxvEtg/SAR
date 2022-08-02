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
Write-Host "PSCredentials must be configured first!"
Write-Host "----------------------------------------------------"

$credential = (Get-Secret esxi)
# $username = $credential.GetNetworkCredential().username
$password = $credential.GetNetworkCredential().password

$VIServer = $VCFQDN

Connect-VIServer -Server $VIServer -Protocol https -Credential (Get-Secret vcenter)
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

$cmd = " tee /etc/issue << 'EOF'
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."


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
