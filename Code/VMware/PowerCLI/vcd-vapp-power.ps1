if ($args.count -ne 1) {
Write-Host "Usage: vcd-vapp-power.ps1 on/off"
exit
}

$status = $args[0] 

$CIServer = "fqdn"

$organization = "org"

Connect-CIServer -Server $CIServer -org $organization -Credential (Get-Secret vcloud)


if ( $status -eq 'on' ) {
	Write-Host 'Powering All vApps On'
	Get-CIVApp | Start-CIVApp -Confirm:$false
}
elseif (  $status -eq 'off' ) {
	Write-Host 'Powering All vApps Off'
	Get-CIVApp | Stop-CIVApp -Confirm:$false
}
else {
	Write-Host "Usage: vcd-vapp-power.ps1 on/off"
}
