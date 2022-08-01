Get-CustomCertificates

# get connected cds and remove
Get-VM | Get-CDDrive | Where {$_.extensiondata.connectable.connected -eq $true} | Select Parent,Name
Get-VM "VMNAME" | Get-CDDrive | Set-CDDrive -NoMedia

Get-VM | Get-FloppyDrive | Select Parent | Format-Table -AutoSize

ForEach ($device in (Get-VM | Get-FloppyDrive | Select Parent)) {Write-Host $device}


ForEach ($device in (Get-VM | Get-FloppyDrive | Select Parent)) {$device = Out-String -InputObject $device; $device = $device -replace 'Parent',''; $device = $device -replace '------',''; $device = $device -replace '\s+',''; Write-Host $device;}


ForEach ($device in (Get-VM | Get-FloppyDrive | Select Parent)) {$device = Out-String -InputObject $device; $device = $device -replace 'Parent',''; $device = $device -replace '------','';  $device = $device -replace '\s+',''; Get-VM $device | Get-FloppyDrive | Remove-FloppyDrive -Confirm:$false;}


$OrphanedVMs = Get-VM * | Where {$_.ExtensionData.Summary.Runtime.ConnectionState -eq "orphaned"}

# do not run this! example only
Get-VM * | Where {$_.ExtensionData.Summary.Runtime.ConnectionState -eq "orphaned"} | Remove-VM


Get-CIVApp | Stop-CIVApp -Confirm:$false
