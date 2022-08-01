Get-command -module 'Microsoft.PowerShell.SecretManagement'

$params = @{
    Name            = 'vault_name'
    ModuleName      = 'Microsoft.PowerShell.SecretStore'
    DefaultVault    = $true
    AllowClobber    = $true
}
Register-SecretVault @params

Register-SecretVault -Name vault_name -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault -AllowClobber

Set-Secret -name username -secret (get-credential username)

Set-Secret -name username -secret (get-credential domain\username)

Get-SecretInfo

Set-SecretStoreConfiguration -PasswordTimeout 60

Unlock-SecretStore

Reset-SecretStore

Connect-VIServer -Server fqdn -Protocol https -Credential (Get-Secret username_in_vault)

Get-SecretStoreConfiguration

cd $env:LOCALAPPDATA\Microsoft\PowerShell\secretmanagement\localstore\
