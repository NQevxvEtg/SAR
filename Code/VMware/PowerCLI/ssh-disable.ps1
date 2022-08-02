
$VIServer = "fqdn"

Connect-VIServer -Server $VIServer -Protocol https -Credential (Get-Secret vcenter)


$vmhosts = Get-VMHost | Where {$_.connectionstate -ne "Disconnected" } | Where {$_.connectionstate -ne "NotResponding" }|  Sort-Object -Property Name -ErrorAction Stop
$vmhostsv = $vmhosts | Get-View | Sort-Object -Property Name -ErrorAction Stop

ForEach($vmhost in $vmhostsv){
	$hostname = $vmhost.name
	$vmhost = Get-VMHost -Name $hostname

	$esx = $hostname
	
	Get-VMHost $esx | Get-VMHostService | Where { $_.Key -eq "TSM-SSH" } | Stop-VMHostService -Confirm:$FALSE
	
	(Get-VMHost $vmhost | Get-View).EnterLockdownMode()


}

