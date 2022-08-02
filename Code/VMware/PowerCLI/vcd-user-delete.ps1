# Check to make sure both arguments exist
if ($args.count -ne 1) {
Write-Host "Usage: vcd-user-delete.ps1 <UserList.txt>"
exit
}

# Set users from Arg
$usernames = $args[0] 
$usernames = Get-Content $usernames


$CIServer = "fqdn"

$organization = "org"

Connect-CIServer -Server $CIServer -org $organization -Credential (Get-Secret vcloud)

$org = Get-Org



foreach ($username in $usernames) {
write-host "Remove "$username "in " $org
 
$user = get-ciuser -Org $org $username
$user.ExtensionData.Delete()
}
