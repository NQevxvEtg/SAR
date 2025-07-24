#!/bin/bash

# Automated SSH Copy ID Script for Multiple Servers
# This script uses sshpass to provide the password to ssh-copy-id,
# but intelligently detects if the key already exists on the remote server
# to prevent false "failures".

# --- Configuration ---
SERVER_LIST_FILE="$1" # First argument: path to the server list file
SSH_USERNAME="$2"     # Second argument: SSH username for remote servers

# --- Functions ---

function error_exit {
    echo "Error: $1" >&2
    exit 1
}

function command_exists {
    command -v "$1" >/dev/null 2>&1
}

function log_info {
    echo "[$(date '+%H:%M:%S')] $*"
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

# 3. Check dependencies
for cmd in sshpass ssh cat; do
    if ! command_exists "$cmd"; then
        error_exit "'$cmd' is not installed. Please install it first."
    fi
done

# 4. Prompt for SSH password once
echo "Please enter your SSH password. It will be used for all servers."
read -s -p "SSH Password: " SSH_PASSWORD
echo

if [ -z "$SSH_PASSWORD" ]; then
    error_exit "Password cannot be empty. Exiting."
fi

echo -e "\nStarting ssh-copy-id process...\n"

# Initialize arrays
SUCCESSFUL_SERVERS=()
FAILED_SERVERS=()
SKIPPED_SERVERS=()
ALREADY_DONE_SERVERS=()

# Path to local public key (default)
PUBKEY_FILE="${HOME}/.ssh/id_rsa.pub"
if [ ! -f "$PUBKEY_FILE" ]; then
    # Try common Ed25519 key
    PUBKEY_FILE="${HOME}/.ssh/id_ed25519.pub"
    if [ ! -f "$PUBKEY_FILE" ]; then
        error_exit "No public key found at ~/.ssh/id_rsa.pub or ~/.ssh/id_ed25519.pub"
    fi
fi

# Read public key content
if ! LOCAL_PUBKEY=$(cat "$PUBKEY_FILE"); then
    error_exit "Failed to read local public key: $PUBKEY_FILE"
fi

# 5. Process each server
while IFS= read -r SERVER_HOST_RAW; do
    # Clean input: remove carriage returns, whitespace
    SERVER_HOST=$(echo "$SERVER_HOST_RAW" | tr -d '\r' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | xargs)

    # Skip empty lines
    if [ -z "$SERVER_HOST" ]; then
        continue
    fi

    # Basic hostname/IP validation (support IPs, domains, localhost)
    if ! [[ "$SERVER_HOST" =~ ^[a-zA-Z0-9]([-a-zA-Z0-9.])*$ ]] || [[ "$SERVER_HOST" =~ [.-]$ ]] || [[ "$SERVER_HOST" =~ ^[.-] ]]; then
        log_info "❌ Invalid hostname/IP format: '$SERVER_HOST_RAW' → cleaned to '$SERVER_HOST'"
        SKIPPED_SERVERS+=("$SERVER_HOST_RAW")
        continue
    fi

    TARGET="${SSH_USERNAME}@${SERVER_HOST}"
    log_info "📡 Connecting to ${TARGET}"

    # Test SSH connectivity
    if ! timeout 10 sshpass -p "$SSH_PASSWORD" ssh \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=10 \
        -o BatchMode=no \
        -o LogLevel=ERROR \
        "$TARGET" exit; then
        log_info "❌ Failed to connect to $TARGET (network/unreachable/auth)"
        FAILED_SERVERS+=("$SERVER_HOST")
        continue
    fi

    # Extract public key (strip comment, leave key only)
    LOCAL_KEY_PART=$(echo "$LOCAL_PUBKEY" | awk '{print $1" "$2}')

    # Check if the key is already in authorized_keys
    REMOTE_HAS_KEY=$(timeout 10 sshpass -p "$SSH_PASSWORD" ssh \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=10 \
        -o LogLevel=ERROR \
        "$TARGET" "
            grep -F '${LOCAL_KEY_PART}' ~/.ssh/authorized_keys 2>/dev/null || \
            grep -F '${LOCAL_KEY_PART}' /home/${SSH_USERNAME}/.ssh/authorized_keys 2>/dev/null
    ")

    if [ -n "$REMOTE_HAS_KEY" ]; then
        log_info "✅ Key already exists on $TARGET"
        ALREADY_DONE_SERVERS+=("$SERVER_HOST")
        continue
    fi

    # Key not present, attempt to copy
    log_info "🔐 Copying SSH key to $TARGET..."
    if sshpass -p "$SSH_PASSWORD" ssh-copy-id \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=10 \
        -q \
        "$TARGET"; then

        SUCCESSFUL_SERVERS+=("$SERVER_HOST")
        log_info "✅ Successfully copied ID to $TARGET"
    else
        FAILED_SERVERS+=("$SERVER_HOST")
        log_info "❌ Failed to copy ID to $TARGET"
    fi

done < "$SERVER_LIST_FILE"

# 6. Summary
echo -e "\n$(log_info '--- Summary ---')\n"

# Count total operations
TOTAL_PROCESSED=$(( ${#SUCCESSFUL_SERVERS[@]} + ${#FAILED_SERVERS[@]} + ${#ALREADY_DONE_SERVERS[@]} ))

if [ $TOTAL_PROCESSED -eq 0 ]; then
    echo "📭 No valid server entries were processed from the list."
else
    echo "📋 Total servers processed: $TOTAL_PROCESSED"

    if [ ${#SUCCESSFUL_SERVERS[@]} -gt 0 ]; then
        echo -e "\n✅ Successfully added key to (${#SUCCESSFUL_SERVERS[@]}):"
        printf '%s\n' "${SUCCESSFUL_SERVERS[@]/#/  - }"
    fi

    if [ ${#ALREADY_DONE_SERVERS[@]} -gt 0 ]; then
        echo -e "\n🟢 Key already present (${#ALREADY_DONE_SERVERS[@]}):"
        printf '%s\n' "${ALREADY_DONE_SERVERS[@]/#/  - }"
    fi

    if [ ${#FAILED_SERVERS[@]} -gt 0 ]; then
        echo -e "\n❌ Failed to copy key (${#FAILED_SERVERS[@]}):"
        printf '%s\n' "${FAILED_SERVERS[@]/#/  - }"
    fi

    if [ ${#SKIPPED_SERVERS[@]} -gt 0 ]; then
        echo -e "\n⏭️  Skipped invalid hosts (${#SKIPPED_SERVERS[@]}):"
        printf '%s\n' "${SKIPPED_SERVERS[@]/#/  - }"
    fi
fi

# Clear sensitive data
unset SSH_PASSWORD LOCAL_PUBKEY LOCAL_KEY_PART REMOTE_HAS_KEY TARGET SERVER_HOST SERVER_HOST_RAW

exit 0