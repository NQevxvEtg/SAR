https://www.youtube.com/watch?v=lMCPIfnxDo4&list=PLDveEyEaCGzxFRigX_uak9VEx6XVooUP-&index=1

Find-Module mva*|install-module -AllowClobber

gmo -ListAvailable mva*

# from ise only
Show-MVA_DSC_Examples -Day 1 -Module 2

Get-DSCResource

# here the r is a variable
Get-DSCResource -ov r | measure

# grid view variable r
$r | ogv


registery-update.ps1

$r = Test-DscConfiguration -ComputerName 'localhost' -ReferenceConfiguration "\\dsc\mofs\reg-update\localhost.mof"

Test-DscConfiguration -ComputerName 'localhost' -ReferenceConfiguration "\\dsc\mofs\reg-update\localhost.mof"

Start-DSCConfiguration -Path "\\dsc\mofs\reg-update\" -Verbose -Wait
