#!/bin/bash

# Exit on error, treat unset variables as errors, and handle pipeline failures
set -euo pipefail

# --- User Configurable Settings ---

# 1. Key Algorithm Configuration
#    Choose "RSA" or "EC"
KEY_ALGORITHM="RSA" # Options: "RSA", "EC"

# RSA Specifics (used if KEY_ALGORITHM is "RSA")
RSA_BITS="2048"

# Elliptic Curve Specifics (used if KEY_ALGORITHM is "EC")
EC_CURVE="P-384" # Common options: "P-256", "P-384", "P-521", "secp256k1"

# 2. Distinguished Name (DN) Components
#    Customize these values for your certificates.
DN_C="US"
DN_ST="California"
DN_L="Los Angeles"
DN_O="Example Company"
DN_OU="IT Department"

# 3. Hosts Information
#    Define your hosts here. Each entry is a comma-separated string:
#    "primary_dns_or_cn,alt_dns1,alt_dns2,ip1,ip2,..."
#    The first valid DNS name (preferably FQDN) will be used as the Common Name (CN).
#    If no DNS names are provided, the first IP address will be used as the CN.
HOSTS=(
  "host1.example.com,host1,alias1,192.168.1.1,10.0.0.1"
  "host2.example.com,host2,192.168.1.2"
  "app3.example.net,app3,app3-lb,10.0.0.5,192.168.1.7,192.168.1.8"
  # Add more hosts as needed:
  # "another.host.net,10.10.10.10"
  # "service.internal,service-alias"
  # "192.168.5.100" # Example with only an IP (will be used as CN)
)

# --- End of User Configurable Settings ---

# Output directories
CSR_DIR="csr/csr"
KEY_DIR="csr/key"

# Temporary files array for cleanup
TEMP_FILES=()

# --- Functions ---
cleanup() {
  echo "" # Newline before cleanup messages
  if [ ${#TEMP_FILES[@]} -gt 0 ]; then
    log_info "Cleaning up temporary configuration files..."
    for tmp_file in "${TEMP_FILES[@]}"; do
      if [ -f "$tmp_file" ]; then
        rm "$tmp_file"
        log_info "Removed temporary file: $tmp_file"
      fi
    done
  fi
}
# Register cleanup function to run on script exit or interruption
trap cleanup EXIT SIGINT SIGTERM

log_info() {
  echo "INFO: $1"
}

log_success() {
  echo "✅ SUCCESS: $1"
}

log_error() {
  echo "❌ ERROR: $1" >&2
}

# --- Script Start ---
log_info "Starting CSR and Key Generation Script"
log_info "--- Configuration ---"
log_info "Key Algorithm: $KEY_ALGORITHM"
if [[ "$KEY_ALGORITHM" == "RSA" ]]; then
  log_info "RSA Key Bits: $RSA_BITS"
elif [[ "$KEY_ALGORITHM" == "EC" ]]; then
  log_info "EC Curve: $EC_CURVE"
else
  log_error "Invalid KEY_ALGORITHM specified in script: '$KEY_ALGORITHM'. Choose 'RSA' or 'EC'."
  exit 1
fi
log_info "DN Country: $DN_C, State: $DN_ST, Locality: $DN_L, Org: $DN_O, OrgUnit: $DN_OU"
log_info "---------------------"


mkdir -p "$CSR_DIR" "$KEY_DIR"

log_info "Processing ${#HOSTS[@]} host entries..."

for entry in "${HOSTS[@]}"; do
  log_info "---"
  log_info "Processing entry: $entry"
  IFS=',' read -r -a fields <<< "$entry"

  dns_list=()
  ip_list=()
  for f_raw in "${fields[@]}"; do
    # Trim whitespace from field
    f=$(echo "$f_raw" | xargs)
    if [[ -z "$f" ]]; then # Skip empty fields
        continue
    fi

    if [[ $f =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then # Basic IPv4 check
      ip_list+=("$f")
    else
      dns_list+=("$f")
    fi
  done

  if [[ ${#dns_list[@]} -eq 0 && ${#ip_list[@]} -eq 0 ]]; then
    log_error "Skipping empty or invalid entry (no DNS/IP found): $entry"
    continue
  fi

  # Determine Common Name (CN)
  CN=""
  if [[ ${#dns_list[@]} -gt 0 ]]; then
    CN="${dns_list[0]}" # Default to first DNS
    for d in "${dns_list[@]}"; do
      if [[ $d == *.* ]]; then # Prefer FQDN
        CN="$d"
        break
      fi
    done
  elif [[ ${#ip_list[@]} -gt 0 ]]; then
    CN="${ip_list[0]}" # Fallback to first IP if no DNS names
  else
    log_error "Cannot determine CN for entry: $entry. No DNS or IP found after processing."
    continue
  fi

  SANITIZED_CN=$(echo "$CN" | sed 's/[^a-zA-Z0-9.-]/_/g')
  log_info "Using Common Name (CN): $CN (Sanitized for filename: $SANITIZED_CN)"

  CNF_FILE=$(mktemp) || { log_error "Failed to create temporary config file."; exit 1; }
  TEMP_FILES+=("$CNF_FILE")

  cat > "$CNF_FILE" <<EOF
[ req ]
default_bits        = $RSA_BITS
prompt              = no
default_md          = sha256
distinguished_name  = dn
req_extensions      = san_ext

[ dn ]
C                   = $DN_C
ST                  = $DN_ST
L                   = $DN_L
O                   = $DN_O
OU                  = $DN_OU
CN                  = $CN

[ san_ext ]
subjectAltName      = @alt_names

[ alt_names ]
EOF

  dns_idx=1
  for d_name in "${dns_list[@]}"; do
    echo "DNS.$dns_idx = $d_name" >> "$CNF_FILE"
    ((dns_idx++))
  done

  ip_idx=1
  for ip_addr in "${ip_list[@]}"; do
    echo "IP.$ip_idx = $ip_addr" >> "$CNF_FILE"
    ((ip_idx++))
  done

  KEY_FILE_PATH="$KEY_DIR/${SANITIZED_CN}.key"
  CSR_FILE_PATH="$CSR_DIR/${SANITIZED_CN}.csr"

  log_info "Generating CSR and key with $KEY_ALGORITHM algorithm..."
  OPENSSL_CMD_ARGS=(req -nodes -config "$CNF_FILE" -keyout "$KEY_FILE_PATH" -out "$CSR_FILE_PATH")

  if [[ "$KEY_ALGORITHM" == "RSA" ]]; then
    OPENSSL_CMD_ARGS+=(-newkey "rsa:$RSA_BITS")
  elif [[ "$KEY_ALGORITHM" == "EC" ]]; then
    OPENSSL_CMD_ARGS+=(-newkey ec -pkeyopt "ec_paramgen_curve:$EC_CURVE")
  # No 'else' needed here as KEY_ALGORITHM validity is checked at the script start
  fi

  if openssl "${OPENSSL_CMD_ARGS[@]}"; then
    chmod 600 "$KEY_FILE_PATH"
    log_success "Generated: $KEY_FILE_PATH & $CSR_FILE_PATH"
    log_info "Details: ${#dns_list[@]} DNS SANs, ${#ip_list[@]} IP SANs"
  else
    log_error "OpenSSL command failed for CN: $CN. Check OpenSSL errors above."
    # 'set -e' will cause script to exit here. Trap will clean up CNF_FILE.
    exit 1 # Explicitly exit to ensure failure is noted
  fi
done

log_info "---"
log_info "All processing complete."
log_info "Private keys are in: $KEY_DIR"
log_info "CSRs are in: $CSR_DIR"
