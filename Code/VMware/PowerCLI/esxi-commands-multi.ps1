
$VIServer = "fqdn"
$credential = (Get-Secret esxi)
# $username = $credential.GetNetworkCredential().username
$password = $credential.GetNetworkCredential().password

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


$root = "root" 
$plink = "echo n | \\plink.exe"

ForEach($vmhost in $vmhostsv){
	$esx = $vmhost.name
    $esxcli = Get-EsxCli -VMHost $esx -v2
	
### start first command
Write-Host "Enabling SSH on $esx" -ForegroundColor Green
Get-VMHost $esx | Get-VMHostService | Where { $_.Key -eq "TSM-SSH" } | Start-VMHostService

$cmd = 'grep -i "^Ciphers" /etc/ssh/sshd_config'



$remoteCommand = '"' + $cmd + '"'
Write-Host -Object "Executing Command on $esx, Please wait..." -ForegroundColor Yellow
$output = $plink + " " + "-ssh" + " " + $root + "@" + $esx + " " + "-pw" + " " + $password + " " + $remoteCommand
$message = Invoke-Expression -command $output
$message

### end first command

} 
