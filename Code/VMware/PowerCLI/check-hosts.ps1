
$VIServer = "fqdn"


Connect-VIServer -Server $VIServer -Protocol https -Credential (Get-Secret username_in_vault)

$value="5"

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
	$vmhost = Get-VMHost $hostname | Where-Object {$_.extensiondata.AlarmActionsEnabled -eq $false} 
	if($vmhost){
		write-host($vmhost)
	}
}

