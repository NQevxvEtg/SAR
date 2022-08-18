# this script checks automate manual stig checks
# this script does not remediate

clear
$hostname = hostname
Write-Host "~~~~~~~~~ $hostname ~~~~~~~~~"
Write-Host ""
Write-Host "~~~~~~~~~ CAT I ~~~~~~~~~"
Write-Host ""

#----------------------------------------------------------------------------------
Write-Host 'V-205646'
Get-ChildItem Cert:\LocalMachine\My | Select Subject,Issuer,NotAfter | ft -AutoSize
#----------------------------------------------------------------------------------
Write-Host 'V-205647'
Get-ADUser -Filter * | FT Name, UserPrincipalName, Enabled -AutoSize
# Get-ADUser -Filter 'Enabled -eq $true' | FT Name, UserPrincipalName
#----------------------------------------------------------------------------------
Write-Host 'V-205738'
$adgroups = Get-ADGroup -Filter "name -like '*admin*'" | sort name
$data = foreach ($adgroup in $adgroups) {
    $members = $adgroup | get-adgroupmember | sort name
    foreach ($member in $members) {
        [PSCustomObject]@{
            Group   = $adgroup.name
            Members = $member
        }
    }
}
$data
#----------------------------------------------------------------------------------
Write-Host 'V-205740'
net share -Select 'Share name'
icacls c:\Windows\SYSVOL
#----------------------------------------------------------------------------------
Write-Host 'V-205741'
$gpos = Get-GPO -All
$info = foreach ($gpo in $gpos){
    Get-GPPermissions -Guid $gpo.Id -All | Select-Object `
    @{n='GPOName';e={$gpo.DisplayName}},
    @{n='AccountName';e={$_.Trustee.Name}},
    @{n='AccountType';e={$_.Trustee.SidType.ToString()}},
    @{n='Permissions';e={$_.Permission}},
    @{n='ACLs';e={(get-acl "AD:$($gpo.path)").access.IdentityReference -join ";"}}
}
$info | select GPOName,AccountName,ACLs| Where-Object {$_.AccountName -like "*user*" }
#----------------------------------------------------------------------------------
Write-Host 'V-205742'
$group = Get-ADGroup 'Domain Controllers'
(Get-Acl "AD:$($group.distinguishedName)").Access  | select IdentityReference,ActiveDirectoryRights 
#----------------------------------------------------------------------------------
Write-Host 'V-205743'
$adgroups = Get-ADGroup -Filter "name -like '*'" | sort name
$data = foreach ($adgroup in $adgroups) {
$addata = (Get-Acl "AD:$($adgroup.distinguishedName)").Access  | select IdentityReference,ActiveDirectoryRights  | Where-Object {
	$_.IdentityReference -notlike "*CREATOR OWNER*" -and 
	$_.IdentityReference -notlike "*self*" -and 
	$_.IdentityReference -notlike "*SYSTEM*" -and 
	$_.IdentityReference -notlike "*Domain Admins*" -and
	$_.IdentityReference -notlike "*Enterprise Admins*" -and
	$_.IdentityReference -notlike "*Key Admins*" -and
	$_.IdentityReference -notlike "*Enterprise Key Admins*" -and
	$_.IdentityReference -notlike "*Administrators*" -and
	$_.IdentityReference -notlike "*Pre-Windows 2000 Compatible Access*" -and
	$_.IdentityReference -notlike "*ENTERPRISE DOMAIN CONTROLLERS*"
	} | Where-Object {
	$_.ActiveDirectoryRights -like "*write*" -or 
	$_.ActiveDirectoryRights -like "*create*" 
	} | ft -AutoSize
	
if (-not ([string]::IsNullOrEmpty($addata)))
{
Write-Output '---------------------------------------------------------------------------------'
Write-Output $adgroup | select DistinguishedName | ft -AutoSize
$addata
}

}
$data
#----------------------------------------------------------------------------------


