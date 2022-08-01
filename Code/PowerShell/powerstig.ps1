Install-Module PowerSTIG -Scope CurrentUser

(Get-Module PowerStig -ListAvailable).RequiredModules | % {
   $PSItem | Install-Module -Force
}

Get-Stig -ListAvailable

$audit = Test-DscConfiguration -ComputerName 'localhost' -ReferenceConfiguration "$env:\\Example\localhost.mof"
