<#
.SYNOPSIS
    Converts a CSV file (with or without headers, flexible fqdn/ip presence)
    to an Ansible inventory YAML file.

.DESCRIPTION
    Reads a CSV file line by line. It can handle lines with:
    - Two comma-separated values (FQDN, IP)
    - One value (used for both FQDN and ansible_host)
    - Two values where one is empty (the non-empty value is used for both)

    It generates an Ansible inventory YAML, including default port, user,
    and SSH key path.

.PARAMETER CsvFilePath
    Path to the input CSV file. Default: '.\hosts_flexible.csv'

.PARAMETER YamlFilePath
    Path for the output YAML file. Default: '.\inventory.yml'

.EXAMPLE
    # Example CSV content for 'hosts_flexible.csv':
    # rhel8,192.168.1.10
    # ol9,192.168.1.11
    # myhost.local       # Only FQDN, will use 'myhost.local' as ansible_host
    # 10.0.0.5           # Only IP, will use '10.0.0.5' as host name and ansible_host
    # server,,           # FQDN present, IP empty, will use 'server' for ansible_host
    # ,192.168.1.20      # IP present, FQDN empty, will use '192.168.1.20' as host name

    .\Convert-CsvToAnsibleYaml.ps1 -CsvFilePath '.\hosts_flexible.csv'
#>
param(
    [string]$CsvFilePath = ".\hosts_flexible.csv", # Changed default to suggest flexible input file
    [string]$YamlFilePath = ".\inventory.yml"
)

# --- Configuration ---
# You can modify these default values
$ansibleDefaultPort = 22
$ansibleDefaultUser = "admin"
$ansibleDefaultSshPrivateKeyFile = "~/.ssh/id_rsa"
# ---------------------

Write-Host "Starting conversion..."
Write-Host "Reading from: $CsvFilePath (flexible input parsing)"
Write-Host "Writing to: $YamlFilePath"

# Check if the CSV file exists
if (-not (Test-Path -Path $CsvFilePath)) {
    Write-Error "Error: CSV file not found at '$CsvFilePath'. Please ensure the path is correct and the file exists."
    exit 1
}

try {
    # Read the CSV file content line by line
    $csvLines = Get-Content -Path $CsvFilePath

    # Initialize the YAML content string
    $yamlContent = "all:"
    $yamlContent += "`n  hosts:"

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
            Write-Warning "Skipping line as no valid FQDN or IP could be determined: '$line'"
            continue # Skip to next line
        }
        # ---------------------------------

        # Append host entry and variables to YAML content
        # Use ${fqdn} to correctly delimit the variable name before the colon
        $yamlContent += "`n    ${fqdn}:"
        $yamlContent += "`n      ansible_host: $ip"
        $yamlContent += "`n      ansible_port: $ansibleDefaultPort"
        $yamlContent += "`n      ansible_user: $ansibleDefaultUser"
        $yamlContent += "`n      ansible_ssh_private_key_file: $ansibleDefaultSshPrivateKeyFile"
    }

    # Save the YAML content to the output file
    $yamlContent | Set-Content -Path $YamlFilePath -Encoding UTF8

    Write-Host "Successfully created Ansible inventory file at: $YamlFilePath"
    Write-Host "First 10 lines of generated file:"
    Get-Content -Path $YamlFilePath | Select-Object -First 10

}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
}

Write-Host "Conversion complete."
