$computername = '0.0.0.0' 

$session=New-PSSession -ComputerName $computername -Credential cred

# Invoke-Command  -ScriptBlock { 
# echo 'test'
# } 
# Disable-WSManCredSSP -Role Client
# Get-PSSession | Remove-PSSession 
