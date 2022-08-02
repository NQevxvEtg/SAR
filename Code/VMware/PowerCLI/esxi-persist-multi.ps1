$credential = (Get-Secret esxi)
# $username = $credential.GetNetworkCredential().username
$password = $credential.GetNetworkCredential().password

$VIServer = "fqdn"

Connect-VIServer -Server $VIServer -Protocol https -Credential (Get-Secret vcenter)



Function Write-ToConsole ($Details){
	$LogDate = Get-Date -Format T
	Write-Host "$($LogDate) $Details"
}

Function Write-ToConsoleRed ($Details){
	$LogDate = Get-Date -Format T
	Write-Host "$($LogDate) $Details" -ForegroundColor Red
}

Function Write-ToConsoleGreen ($Details){
	$LogDate = Get-Date -Format T
	Write-Host "$($LogDate) $Details" -ForegroundColor Green
}

$vmhosts = Get-VMHost | Where {$_.connectionstate -ne "Disconnected" } | Where {$_.connectionstate -ne "NotResponding" }|  Sort-Object -Property Name -ErrorAction Stop
$vmhostsv = $vmhosts | Get-View | Sort-Object -Property Name -ErrorAction Stop

ForEach($vmhost in $vmhostsv){
	$hostname = $vmhost.name
	$vmhost = Get-VMHost -Name $hostname

	(Get-VMHost $vmhost | Get-View).ExitLockdownMode()

	$root = "root" 
	$plink = "echo n | \\plink.exe"


	$esx = $hostname
	$esxcli = Get-EsxCli -VMHost $esx -v2

	# start first command
	Write-Host "Enabling SSH on $esx" -ForegroundColor Green
	Get-VMHost $esx | Get-VMHostService | Where { $_.Key -eq "TSM-SSH" } | Start-VMHostService

	$cmd = "/sbin/auto-backup.sh"

	$remoteCommand = '"' + $cmd + '"'
	Write-Host -Object "Executing Command on $esx, Please wait..." -ForegroundColor Yellow
	$output = $plink + " " + "-ssh" + " " + $root + "@" + $esx + " " + "-pw" + " " + $password + " " + $remoteCommand
	$message = Invoke-Expression -command $output
	$message



}


