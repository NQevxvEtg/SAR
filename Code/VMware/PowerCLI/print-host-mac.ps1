
$VIServer = "fqdn"

Connect-VIServer -Server $VIServer -Protocol https -Credential (Get-Secret vcenter)


$macs = Get-VMHostNetworkAdapter |   Select @{N="ESXi";E={$_.VMHost.Name}},Name,Mac |  Where-Object {$_.Name -eq "vmk#"} 

$macs | Sort-Object ESXi | Format-Table -AutoSize
