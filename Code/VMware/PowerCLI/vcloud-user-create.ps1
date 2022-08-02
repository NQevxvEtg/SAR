# Check to make sure both arguments exist
if ($args.count -ne 1) {
Write-Host "Usage: vcd-user-create.ps1 <UserList.txt>"
exit
}

# Set users from Arg
$usernames = $args[0] 
$usernames = Get-Content $usernames
$userpassword = "password"

$CIServer = "fqdn"

$organization = "org"

Connect-CIServer -Server $CIServer -org $organization -Credential (Get-Secret vcloud)

$org = Get-Org



foreach ($username in $usernames) {

$user = New-Object -TypeName VMware.VimAutomation.Cloud.Views.User

$user.Name = $username

$user.Password = $userpassword

$role = $org.ExtensionData.RoleReferences.RoleReference | Where-Object -FilterScript { $_.Name -eq "userrole" }
 
$user.Role = $role

$user.DeployedVMQuota = 10

$user.StoredVmQuota = 10

$user.IsEnabled = $true

$org.ExtensionData.createUser($user)

write-host "Created "$username "in " $org
}
