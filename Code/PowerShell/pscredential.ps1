Register-SecretVault -Name vault_name -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault -AllowClobber

Set-Secret -name username -secret (get-credential username)

Set-Secret -name username -secret (get-credential domain\username)

Set-SecretStoreConfiguration -PasswordTimeout 60

Unlock-SecretStore

Reset-SecretStore
