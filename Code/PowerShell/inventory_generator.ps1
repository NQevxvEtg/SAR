<#
.SYNOPSIS
    Converts a CSV file (fqdn, ip) to an Ansible inventory YAML file.

.DESCRIPTION
    Reads a CSV with 'fqdn' and 'ip' columns and generates an Ansible inventory
    YAML, including default port, user, and SSH key path.

.PARAMETER CsvFilePath
    Path to the input CSV file. Default: '.\hosts.csv'

.PARAMETER YamlFilePath
    Path for the output YAML file. Default: '.\inventory.yml'
#>
param(
    [string]$CsvFilePath = ".\hosts.csv",
    [string]$YamlFilePath = ".\inventory.yml"
)

# --- Configuration ---
# You can modify these default values
$ansibleDefaultPort = 22
$ansibleDefaultUser = "admin"
$ansibleDefaultSshPrivateKeyFile = "~/.ssh/id_rsa"
# ---------------------

Write-Host "Starting conversion..."
Write-Host "Reading from: $CsvFilePath"
Write-Host "Writing to: $YamlFilePath"

# Check if the CSV file exists
if (-not (Test-Path -Path $CsvFilePath)) {
    Write-Error "Error: CSV file not found at '$CsvFilePath'. Please ensure the path is correct and the file exists."
    exit 1
}

try {
    # Read the CSV file
    $csvData = Import-Csv -Path $CsvFilePath

    # Initialize the YAML content string
    $yamlContent = "all:"
    $yamlContent += "`n  hosts:"

    # Process each row from the CSV
    foreach ($row in $csvData) {
        $fqdn = $row.fqdn
        $ip = $row.ip

        # Append host entry and variables to YAML content
        $yamlContent += "`n    $fqdn:"
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
