configuration reg-update
{
    param
    (
        [parameter()]
        [string]
        $NodeName = 'localhost'
    )
	
	Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
	
    Node $NodeName
    {
		Registry RegistryExample
		{
			Ensure      = "Present"  # You can also set Ensure to "Absent"
			Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\GoogleChromeElevationService"
			ValueName   = "Start"
            ValueType   = "Dword"
			ValueData   = "3"
		}
    }
}

# Create the Computer.Meta.Mof in folder
reg-update -OutputPath \\0.0.0.0\d$\path\dsc\mofs\reg-update
