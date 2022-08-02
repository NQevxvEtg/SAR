$credential = (Get-Secret esxi)
$username = $credential.GetNetworkCredential().username
$password = $credential.GetNetworkCredential().password

# Get the hostsystem object for every host currently disconnected.
$VMhosts = Get-View -ViewType ‘Hostsystem’ ` -Property ‘name’ ` -Filter @{“Runtime.ConnectionState”=”disconnected”}
Foreach ($VMhost in $VMhosts) {
# Create a reconnect spec
$HostConnectSpec = New-Object VMware.Vim.HostConnectSpec
$HostConnectSpec.hostName = $VMhost.name
$HostConnectSpec.userName = $username
$HostConnectSpec.password = $password
# Reconnect the host
$taskMoRef = $VMhost.ReconnectHost_Task($HostConnectSpec,$null)
# optional, but i like to return a task object, that way I can
# easily integrate this into a pipeline later if need be.
Get-VIObjectByVIView -MORef $taskMoRef
}
