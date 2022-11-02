#dbatools

Get-Item WSMan:\localhost\Client\TrustedHosts
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force
Disable-DbaForceNetworkEncryption -SqlInstance <server>\<database>
Set-Item WSMan:\localhost\Client\TrustedHosts -Value '' -Force
Get-Item WSMan:\localhost\Client\TrustedHosts
