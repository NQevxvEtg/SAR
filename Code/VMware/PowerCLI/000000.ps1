Get-CustomCertificates

# get connected cds and remove
Get-VM | Get-CDDrive | Where {$_.extensiondata.connectable.connected -eq $true} | Select Parent,Name
Get-VM "VMNAME" | Get-CDDrive | Set-CDDrive -NoMedia
