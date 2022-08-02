
$VIServer = "fqdn"

Connect-VIServer -Server $VIServer -Protocol https -Credential (Get-Secret vcenter)


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
	
	Get-VMHost $esx | Get-VMHostService | Where { $_.Key -eq "TSM-SSH" } | Start-VMHostService



}

