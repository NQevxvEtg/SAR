
$ErrorActionPreference= 'silentlycontinue'
#############################################################
clear
Write-Host "Warning: This script will not work using Powershell ISE" -ForegroundColor Yellow 
Write-Host ""
Write-Host "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
Write-Host "Start Login ID:" -ForegroundColor Yellow 
Write-Host ""
Write-Host "PSCredentials must be configured first!" -ForegroundColor Yellow 
Write-Host "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
Write-Host ""

# Write-Host "Please enter the vCenter Username:" -ForegroundColor Yellow -NoNewline
# $username = Read-Host
# $password = Read-Host -assecurestring "Please enter your Password"
# $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))


$credential = (Get-Secret esxi)
# $username = $credential.GetNetworkCredential().username
$password = $credential.GetNetworkCredential().password

########### vCenter Connectivity Details ###########

function Show-Menu
{
    param (
        [string]$Title = 'vCenter Menu'
    )
    Clear-Host
    Write-Host "================ $Title ================"
    
    Write-Host "1: Press '1' for fqdn"
    Write-Host "2: Press '2' for fqdn"
    Write-Host "q: Press 'q' to quit."
}

Show-Menu –Title 'vCenter Menu'
$selection = Read-Host "Please select a vCenter"

switch ($selection)
 {
     '1' {
         $VCFQDN = 'fqdn'
     } 
	 '2' {
         $VCFQDN = 'fqdn'
     }  
	 'q' {
         return
     }
	 default { 
	Write-Host "wow!!"
	Start-Sleep -Seconds 2
	Exit
	 }
 }



Write-Host "Please enter the ESXi name:" -ForegroundColor Yellow -NoNewline
$ESXHost = Read-Host


$ESXFQDN = "$ESXHost.fqdn"
Write-Host "you entered $VCFQDN and $ESXFQDN" 

Write-Host 'Press any key to continue...' -ForegroundColor Green -NoNewline;
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

############################################################################################
$VIServer = $VCFQDN

Connect-VIServer -Server $VIServer -Protocol https -Credential (Get-Secret vcenter)

Function Write-ToConsole ($Details){
	$LogDate = Get-Date -Format T
	Write-Host "$($LogDate) $Details"
}

Function Write-ToConsoleRed ($Details){
	$LogDate = Get-Date -Format T
	Write-Host "$($LogDate) $Details" -ForegroundColor Red
}

Function Write-ToConsoleGreen ($Details){
	$LogDate = Get-Date -Format T
	Write-Host "$($LogDate) $Details" -ForegroundColor Green
}


$vmhost = Get-VMHost -Name $ESXFQDN

# make sure to keep VMware vCenter Agent and vSphere Web Client alive
$fwservices = $vmhost | Get-VMHostFirewallException | Where-Object {$_.Enabled -eq $True `
-and $_.Name -ne "VMware vCenter Agent" `
-and $_.Name -ne "vSphere Web Client" `
}

$esxcli = Get-EsxCli -VMHost $vmhost -V2


#Write-Host $fwservices


ForEach($fwservice in $fwservices){
	$fwsvcname = $fwservice.extensiondata.key
	Write-ToConsole "...Configuring ESXi Firewall Policy on service $fwsvcname to $($stigsettings.allowedips) on $vmhost"
	## Clear all IPs
	$esxcliargs = $esxcli.network.firewall.ruleset.allowedip.list.CreateArgs()
	$esxcliargs.rulesetid = $fwsvcname
	try {
		$FirewallRuleAllowedIPList = $esxcli.network.firewall.ruleset.allowedip.list.Invoke($esxcliargs)
	}
	catch [System.Exception]  {
		Write-Warning "Error during Rule List. See latest errors..."
	}
	"`tAllowed IP Addresses: $($FirewallRuleAllowedIPList.AllowedIPAddresses -join ", ")"
	if ($FirewallRuleAllowedIPList.AllowedIPAddresses -ne "All") {
		
		$arguments = @{

		rulesetid = $fwsvcname

		enabled = $true

		allowedall = $true

	}


		try {
			$esxcli.network.firewall.ruleset.set.Invoke($arguments)	
		}
		catch [System.Exception]  {
			Write-Warning "Error during AllowedIP remove. See latest errors..."
		}
	
		
	}

#-----------------------------------------------------------------------------------------------

	If($fwsvcname -eq "hyperbus"){
		$fwallowedargs = $esxcli.network.firewall.ruleset.allowedip.add.CreateArgs()
		$fwallowedargs.ipaddress = "169.254.0.0/16"
		$fwallowedargs.rulesetid = $fwsvcname
		$esxcli.network.firewall.ruleset.allowedip.add.Invoke($fwallowedargs) | Out-Null
	}	
}



