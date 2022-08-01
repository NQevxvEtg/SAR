computernames = 'fqdn'

Enable-WSManCredSSP -Role Client -DelegateComputer $computernames -Force
$session1,$session2=New-PSSession -ComputerName $computernames
Invoke-Command -Session $session1,$session2  -ScriptBlock { 
Enable-WSManCredSSP -Role Server -Force 
}
Get-PSSession | Remove-PSSession 

$session=New-PSSession -ComputerName $computernames -Authentication Credssp -Credential "domain\username"
Invoke-Command -Session $session  -ScriptBlock { 
Import-Module  "share path of the PSWindowsUpdate.psd1"
Get-WUInstall -AcceptAll
Disable-WSManCredSSP -Role Server
} 
Disable-WSManCredSSP -Role Client
Get-PSSession | Remove-PSSession 
