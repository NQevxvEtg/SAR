#############################################################

#############################################################
clear
Write-Host "---------------------------------------------------"
Write-Host "Start Login ID:"
Write-Host "---------------------------------------------------"
########### vCenter Connectivity Details ###########
Write-Host "Please enter the vCenter Host IP Address or FQDN:" -ForegroundColor Yellow -NoNewline
$VIServer = Read-Host

Write-Host "----------------------------------------------------"
Write-Host "PSCredentials must be configured first!"
Write-Host "----------------------------------------------------"


Write-Host "Please enter the vCenter Username:" -ForegroundColor Yellow -NoNewline
Connect-VIServer -Server $VIServer -Protocol https -Credential (Get-Secret vcenter)
########### Please Enter the Cluster to Enable SSH ###########
Write-Host "Clusters Associated with this vCenter:" -ForegroundColor Green
# get cluster names -------------------------------------------------------
$VMcluster = '*' 
ForEach ($VMcluster in (Get-Cluster -name $VMcluster)| sort)
{

Write-Host $VMcluster

}

Write-Host "Please enter the Cluster name:" -ForegroundColor Yellow -NoNewline
$VMcluster = Read-Host
# get esx names -------------------------------------------------------
$esx = '*'
foreach($esx in (Get-Cluster -Name $VMcluster | Get-VMHost) | sort){

Write-Host $esx

}
