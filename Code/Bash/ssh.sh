#!/bin/bash

# Automated SSH Copy ID Script for Multiple Servers
# This script uses sshpass to provide the password to ssh-copy-id,
# allowing you to copy your SSH public key to multiple servers
# by entering the password only once.

# --- Configuration ---
SERVER_LIST_FILE="$1" # First argument: path to the server list file
SSH_USERNAME="$2"     # Second argument: SSH username for remote servers

# --- Functions ---

# Function to display an error message and exit
function error_exit {
    echo "Error: $1" >&2
    exit 1
}

# Function to check if a command exists
function command_exists {
    command -v "$1" >/dev/null 2>&1
}

# --- Main Script ---

# 1. Validate arguments
if [ -z "$SERVER_LIST_FILE" ] || [ -z "$SSH_USERNAME" ]; then
    echo "Usage: $0 <server_list_file> <username>"
    echo "Example: $0 servers.txt myuser"
    error_exit "Missing required arguments."
fi

# 2. Check if server list file exists
if [ ! -f "$SERVER_LIST_FILE" ]; then
    error_exit "Server list file '$SERVER_LIST_FILE' not found."
fi

# 3. Check if sshpass is installed
if ! command_exists sshpass; then
    echo "Error: 'sshpass' is not installed." >&2
    echo "Please install it using your system's package manager (e.g., 'sudo apt-get install sshpass' on Debian/Ubuntu, 'sudo yum install sshpass' on CentOS/RHEL, or 'brew install https://raw.githubusercontent.com/kadwanev/brew-sshpass/master/sshpass.rb' on macOS)." >&2
    error_exit "sshpass not found."
fi

# 4. Prompt for SSH password once
echo "Please enter your SSH password. It will be used for all servers."
read -s -p "SSH Password: " SSH_PASSWORD
echo # Add a newline after the password prompt

if [ -z "$SSH_PASSWORD" ]; then
    error_exit "Password cannot be empty. Exiting."
fi

echo -e "\nStarting ssh-copy-id process..."

SUCCESSFUL_SERVERS=()
FAILED_SERVERS=()

# 5. Read server list and iterate
# Using 'while read' loop to handle lines with spaces correctly (though not common for hostnames)
# and to avoid issues with large files that 'cat' might have with command substitution.
while IFS= read -r SERVER_HOST; do
    # Remove leading/trailing whitespace
    SERVER_HOST=$(echo "$SERVER_HOST" | xargs)

    # Skip empty lines
    if [ -z "$SERVER_HOST" ]; then
        continue
    fi

    TARGET="${SSH_USERNAME}@${SERVER_HOST}"
    echo -e "\nAttempting to copy ID to ${TARGET}..."

    # Use sshpass to provide the password to ssh-copy-id
    # -o StrictHostKeyChecking=no and -o UserKnownHostsFile=/dev/null are for automation.
    # For production, consider removing them and managing known_hosts properly.
    if sshpass -p "$SSH_PASSWORD" ssh-copy-id \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        "$TARGET"; then
        echo "Successfully copied ID to ${TARGET}"
        SUCCESSFUL_SERVERS+=("$SERVER_HOST")
    else
        echo "Failed to copy ID to ${TARGET}. Check the error messages above." >&2
        FAILED_SERVERS+=("$SERVER_HOST")
    fi

done < "$SERVER_LIST_FILE"

# 6. Summary
echo -e "\n--- Summary ---"
if [ ${#SUCCESSFUL_SERVERS[@]} -gt 0 ]; then
    echo -e "\nSuccessfully copied ID to:"
    for s in "${SUCCESSFUL_SERVERS[@]}"; do
        echo "  - $s"
    done
else
    echo -e "\nNo servers were successfully updated."
fi

if [ ${#FAILED_SERVERS[@]} -gt 0 ]; then
    echo -e "\nFailed to copy ID to:"
    for s in "${FAILED_SERVERS[@]}"; do
        echo "  - $s"
    done
else
    echo -e "\nAll specified servers were successfully updated."
fi

# Clear password from memory (best effort, not foolproof in Bash)
unset SSH_PASSWORD
