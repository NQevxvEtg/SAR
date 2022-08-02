# $CIServer = "fqdn"

# $organization = "org"

# $org = Get-Org

# Connect-CIServer -Server $CIServer -org $organization -Credential (Get-Secret vcloud)



# Get-CIVApp -name "vappname" | Export-CIVApp -Destination "\\vApp\" -Format Ova

# Get-vApp -name "vappname" 


.\ovftool.exe --X:progressSmoothing=10 --X:vCloudTimeout=31536000 --X:vCloudKeepAliveTimeout=31536000 --X:logFile=\\log.txt --X:logLevel=verbose "vcloud://username:password@fqdn/cloud?org=org&vdc=org&vapp=vappname"  \\vApp\

.\ovftool.exe --X:progressSmoothing=10 --X:vCloudTimeout=31536000 --X:vCloudKeepAliveTimeout=31536000 --X:logFile=\\log.txt --X:logLevel=verbose "vcloud://username:password@fqdn/cloud?org=org&vdc=org&vapp=vappname"  \\vApp\vappname.ova

.\ovftool.exe --X:logFile=\\log.txt --X:logLevel=verbose "vcloud://username:password@fqdn/cloud?org=org&vdc=org&vapp=test-ova"  \\vApp\test.ova
