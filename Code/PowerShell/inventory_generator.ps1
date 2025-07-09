<#
.SYNOPSIS
    Converts all CSV files in a specified directory to Ansible inventory YAML files.

.DESCRIPTION
    Reads all CSV files (*.csv) line by line from a given directory.
    For each CSV file, it can handle lines with:
    - Two comma-separated values (FQDN, IP)
    - One value (used for both FQDN and ansible_host)
    - Two values where one is empty (the non-empty value is used for both)

    It generates a corresponding Ansible inventory YAML file (.yml) for each
    CSV file, including default port, user, and SSH key path. The YAML file
    will be created in the same directory as the source CSV.

.PARAMETER CsvDirectoryPath
    Path to the directory containing the input CSV files.
    Default: '.\' (current directory)

.PARAMETER AnsibleDefaultPort
    The default SSH port to use for all hosts.
    Default: 2221

.PARAMETER AnsibleDefaultUser
    The default SSH user to use for all hosts.
    Default: 'admin'

.PARAMETER AnsibleDefaultSshPrivateKeyFile
    The default SSH private key file path to use for all hosts.
    Default: '~/.ssh/id_rsa_vbox'

.EXAMPLE
    # Process all CSVs in the current directory
    .\Convert-CsvToAnsibleYaml.ps1

.EXAMPLE
    # Process all CSVs in 'C:\MyHostData'
    .\Convert-CsvToAnsibleYaml.ps1 -CsvDirectoryPath 'C:\MyHostData'

.EXAMPLE
    # Process CSVs in a directory with custom default values
    .\Convert-CsvToAnsibleYaml.ps1 -CsvDirectoryPath 'C:\Servers' `
        -AnsibleDefaultPort 22 `
        -AnsibleDefaultUser 'ubuntu' `
        -AnsibleDefaultSshPrivateKeyFile '~/.ssh/my_custom_key'
#>
param(
    [string]$CsvDirectoryPath = ".\", # Now takes a directory path
    [int]$AnsibleDefaultPort = 2221,
    [string]$AnsibleDefaultUser = "admin",
    [string]$AnsibleDefaultSshPrivateKeyFile = "~/.ssh/id_rsa_vbox"
)

Write-Host "Starting conversion of CSV files in directory: $CsvDirectoryPath"
Write-Host "Using default Ansible settings: Port=$AnsibleDefaultPort, User=$AnsibleDefaultUser, Key=$AnsibleDefaultSshPrivateKeyFile"

# Check if the directory exists
if (-not (Test-Path -Path $CsvDirectoryPath -PathType Container)) {
    Write-Error "Error: Directory not found at '$CsvDirectoryPath'. Please ensure the path is correct."
    exit 1
}

try {
    # Get all CSV files in the specified directory
    $csvFiles = Get-ChildItem -Path $CsvDirectoryPath -Filter "*.csv" -File

    if ($csvFiles.Count -eq 0) {
        Write-Warning "No CSV files found in '$CsvDirectoryPath'. No inventory files will be created."
        exit 0
    }

    foreach ($csvFile in $csvFiles) {
        $csvFilePath = $csvFile.FullName
        $yamlFileName = ($csvFile.BaseName + ".yml")
        $yamlFilePath = Join-Path -Path $CsvDirectoryPath -ChildPath $yamlFileName

        Write-Host "`nProcessing CSV: $csvFilePath"
        Write-Host "Output YAML: $yamlFilePath"

        # Read the CSV file content line by line
        $csvLines = Get-Content -Path $csvFilePath

        # Initialize the YAML content string for the current file
        $yamlContent = "all:"
        $yamlContent += "`n  hosts:"

        $hostsProcessedInCurrentFile = 0

        # Process each line from the CSV
        foreach ($line in $csvLines) {
            # Skip empty lines
            if ([string]::IsNullOrWhiteSpace($line)) {
                continue
            }

            # Split the line by comma
            $columns = $line.Split(',')

            $fqdn = $null
            $ip = $null

            # Attempt to extract FQDN and IP based on column count
            if ($columns.Count -ge 1) {
                $fqdn = $columns[0].Trim()
            }
            if ($columns.Count -ge 2) {
                $ip = $columns[1].Trim()
            }

            # --- Flexible Assignment Logic ---
            # If FQDN is empty, but IP is present, use IP as FQDN (host name)
            if ([string]::IsNullOrWhiteSpace($fqdn) -and -not [string]::IsNullOrWhiteSpace($ip)) {
                $fqdn = $ip
            }
            # If IP is empty, but FQDN is present, use FQDN as IP (ansible_host)
            if ([string]::IsNullOrWhiteSpace($ip) -and -not [string]::IsNullOrWhiteSpace($fqdn)) {
                $ip = $fqdn
            }

            # If after all attempts, both FQDN and IP are still empty, skip the line
            if ([string]::IsNullOrWhiteSpace($fqdn) -or [string]::IsNullOrWhiteSpace($ip)) {
                Write-Warning "  Skipping line in '$csvFile.Name' as no valid FQDN or IP could be determined: '$line'"
                continue # Skip to next line
            }
            # ---------------------------------

            # Append host entry and variables to YAML content
            # Use ${fqdn} to correctly delimit the variable name before the colon
            $yamlContent += "`n    ${fqdn}:"
            $yamlContent += "`n      ansible_host: $ip"
            $yamlContent += "`n      ansible_port: $AnsibleDefaultPort" # Use parameter value
            $yamlContent += "`n      ansible_user: $AnsibleDefaultUser" # Use parameter value
            $yamlContent += "`n      ansible_ssh_private_key_file: $AnsibleDefaultSshPrivateKeyFile" # Use parameter value
            $hostsProcessedInCurrentFile++
        }

        # Save the YAML content to the output file
        if ($hostsProcessedInCurrentFile -gt 0) {
            $yamlContent | Set-Content -Path $yamlFilePath -Encoding UTF8
            Write-Host "  Successfully created Ansible inventory file: $yamlFilePath (Processed $hostsProcessedInCurrentFile hosts)"
        } else {
            Write-Warning "  No valid hosts found in '$csvFile.Name'. Skipping YAML file creation for this CSV."
        }
    }

    Write-Host "`nAll CSV files processed."

}
catch {
    Write-Error "An error occurred during processing: $($_.Exception.Message)"
    Write-Error "Error details: $($_.Exception.ToString())"
}

Write-Host "Script finished."
