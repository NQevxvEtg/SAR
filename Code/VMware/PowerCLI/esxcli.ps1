$credential = (Get-Secret esxi)
# $username = $credential.GetNetworkCredential().username
$password = $credential.GetNetworkCredential().password



Connect-VIServer -Server $VIServer -Protocol https -Credential (Get-Secret vcenter)

$hostname = "fqdn"
$vmhost = Get-VMHost -Name $hostname

# $vmhost | Get-VMHostFirewallDefaultPolicy

$esxcli = Get-EsxCli -v2 -VMHost $hostname 
$esxcli.system.snmp.get.Invoke()
$esxcli.system.coredump.partition.get.Invoke()
$esxcli.system.coredump.network.get.Invoke()
