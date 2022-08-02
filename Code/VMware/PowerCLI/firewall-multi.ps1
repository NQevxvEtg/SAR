# THIS SCRIPT NEEDS TO BE RUN TWICE
$VIServer = 'fqdn'
Connect-VIServer -Server $VIServer -Protocol https -Credential (Get-Secret vcenter)

$allowedIPs=@(
'0.0.0.0/24', 
'0.0.0.0/24'

)


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

$vmhosts = Get-VMHost | Where {$_.connectionstate -ne "Disconnected" } | Where {$_.connectionstate -ne "NotResponding" }|  Sort-Object -Property Name -ErrorAction Stop
$vmhostsv = $vmhosts | Get-View | Sort-Object -Property Name -ErrorAction Stop

ForEach($vmhost in $vmhostsv){
	$hostname = $vmhost.name
	$vmhost = Get-VMHost -Name $hostname
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
			foreach ($IP in $FirewallRuleAllowedIPList.AllowedIPAddresses) {
				$esxcliargs = $esxcli.network.firewall.ruleset.allowedip.remove.CreateArgs()
				$esxcliargs.rulesetid = $fwsvcname
				$esxcliargs.ipaddress = $IP
				try {
					$esxcli.network.firewall.ruleset.allowedip.remove.Invoke($esxcliargs)
				}
				catch [System.Exception]  {
					Write-Warning "Error during AllowedIP remove. See latest errors..."
				}
			}
			
		}

	#-----------------------------------------------------------------------------------------------
		try {
			## Disables All IPs allowed policy
			$fwargs = $esxcli.network.firewall.ruleset.set.CreateArgs()
			$fwargs.allowedall = $false
			$fwargs.rulesetid = $fwsvcname
			$esxcli.network.firewall.ruleset.set.Invoke($fwargs) | Out-Null
		}	
		catch [System.Exception]  {
			Write-Warning "Error during disabling AllowedALL remove. Probably already disabled. See latest errors..."
		}
		
		#Add IP ranges to each service
		ForEach($allowedip in $allowedIPs){
			$fwallowedargs = $esxcli.network.firewall.ruleset.allowedip.add.CreateArgs()
			$fwallowedargs.ipaddress = $allowedip
			$fwallowedargs.rulesetid = $fwsvcname
			$esxcli.network.firewall.ruleset.allowedip.add.Invoke($fwallowedargs) | Out-Null
		}
		#Add 169.254.0.0/16 range to hyperbus service if NSX-T is in use for internal communication
		If($fwsvcname -eq "hyperbus"){
			$fwallowedargs = $esxcli.network.firewall.ruleset.allowedip.add.CreateArgs()
			$fwallowedargs.ipaddress = "169.254.0.0/16"
			$fwallowedargs.rulesetid = $fwsvcname
			$esxcli.network.firewall.ruleset.allowedip.add.Invoke($fwallowedargs) | Out-Null
		}	
	}
}


