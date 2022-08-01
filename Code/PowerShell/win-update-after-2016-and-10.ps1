computernames = 'fqdn'

$session=New-PSSession -ComputerName $computernames -Credential "domain\username"
Invoke-Command -Session $session  -ScriptBlock {
[net.servicepointmanager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
Install-module pswindowsupdate -force -AllowClobber
Get-WUInstall -AcceptAll
} 
Get-PSSession | Remove-PSSession 
