
$CIServer = "fqdn"

$organization = "org"

Connect-CIServer -Server $CIServer -org $organization -Credential (Get-Secret vcloud)

Get-CIVApp | Select Name,Status
