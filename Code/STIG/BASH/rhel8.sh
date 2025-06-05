#!/bin/bash

# V-230224 (assess) Verify RHEL 8 persistent partitions are encrypted
v230224() {
    blkid | grep -v -e "/boot" -e "proc" -e "sys" | grep -q "crypto_LUKS" || echo "Not all persistent partitions are encrypted."
}

# V-230233 Ensure sufficient number of hashing rounds for password encryption
v230233() {
    FILE="/etc/login.defs"
    cp "$FILE" "$FILE.bak_$(date +%Y%m%d%H%M%S)"
    sed -i '/^SHA_CRYPT_MIN_ROUNDS/d' "$FILE"
    sed -i '/^SHA_CRYPT_MAX_ROUNDS/d' "$FILE"
    echo "SHA_CRYPT_MIN_ROUNDS 100000" >> "$FILE"
}

# V-230240 SELinux status and Enforcing mode
v230240() {
    # Immediately set SELinux to enforcing mode.
    sudo setenforce 1
    echo "SELinux set to enforcing mode immediately using setenforce."

    FILE="/etc/selinux/config"
    
    # Create a timestamped backup of the configuration file.
    cp "$FILE" "$FILE.bak_$(date +%Y%m%d%H%M%S)"
    echo "Backup of $FILE created."

    # Remove any existing SELINUX configuration lines.
    sed -i '/^SELINUX=/d' "$FILE"

    # Append the enforcing mode configuration line.
    echo "SELINUX=enforcing" >> "$FILE"
    echo "Updated $FILE to set SELINUX=enforcing for future boots."
}

# V-230243 Find and fix world-writable directories
v230243() {
    find / -type d \( -perm -0002 -a ! -perm -1000 \) -exec chmod 1777 {} + 2>/dev/null || true
}

# V-230244 Ensure 'ClientAliveCountMax 1' in /etc/ssh/sshd_config
v230244() {
    FILE="/etc/ssh/sshd_config"
    cp "$FILE" "$FILE.bak_$(date +%Y%m%d%H%M%S)"
    grep -q '^ClientAliveCountMax' "$FILE" && sed -i '/^ClientAliveCountMax/d' "$FILE"
    echo 'ClientAliveCountMax 1' >> "$FILE"
    sort -u "$FILE" -o "$FILE"
}

# V-230251/230252/255924 Ensure SSH server uses only FIPS 140-2-approved MACs and ciphers
v230251_230252() {
    FILE="/etc/crypto-policies/back-ends/opensshserver.config"
    cp "$FILE" "$FILE.bak_$(date +%Y%m%d%H%M%S)"
	tee "$FILE" << EOF
CRYPTO_POLICY='-oCiphers=aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes128-ctr \
-oMACs=hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256 \
-oGSSAPIKexAlgorithms=gss-curve25519-sha256-,gss-nistp256-sha256-,gss-group14-sha256-,gss-group16-sha512-,gss-gex-sha1-,gss-group14-sha1- \
-oKexAlgorithms=ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,diffie-hellman-group-exchange-sha256,diffie-hellman-group14-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512 \
-oHostKeyAlgorithms=ecdsa-sha2-nistp256,ecdsa-sha2-nistp256-cert-v01@openssh.com,ecdsa-sha2-nistp384,ecdsa-sha2-nistp384-cert-v01@openssh.com,ecdsa-sha2-nistp521,ecdsa-sha2-nistp521-cert-v01@openssh.com,ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-256,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-512-cert-v01@openssh.com,ssh-rsa,ssh-rsa-cert-v01@openssh.com \
-oPubkeyAcceptedKeyTypes=ecdsa-sha2-nistp256,ecdsa-sha2-nistp256-cert-v01@openssh.com,ecdsa-sha2-nistp384,ecdsa-sha2-nistp384-cert-v01@openssh.com,ecdsa-sha2-nistp521,ecdsa-sha2-nistp521-cert-v01@openssh.com,ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-256,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-512-cert-v01@openssh.com,ssh-rsa,ssh-rsa-cert-v01@openssh.com \
-oCASignatureAlgorithms=ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521,ssh-ed25519,rsa-sha2-256,rsa-sha2-512,ssh-rsa'
EOF
}

# V-230253 Ensure SSH server uses strong entropy
v230253() {
    FILE="/etc/sysconfig/sshd"
    cp "$FILE" "$FILE.bak_$(date +%Y%m%d%H%M%S)"
    if grep -q '^SSH_USE_STRONG_RNG' "$FILE"; then
      sed -i 's/^SSH_USE_STRONG_RNG.*/SSH_USE_STRONG_RNG=32/' "$FILE"
    else
      echo 'SSH_USE_STRONG_RNG=32' >> "$FILE"
    fi
}

# V-230254 system must implement DoD-approved encryption in the OpenSSL package
v230254() {
    fips-mode-setup --enable
}

# V-230274 Ensure certificate status checking for multifactor authentication is enabled
v230274() {
    FILE="/etc/sssd/sssd.conf"
    cp "$FILE" "$FILE.bak_$(date +%Y%m%d%H%M%S)"
    if grep -q '^\[sssd\]' "$FILE"; then
      if grep -q '^certificate_verification' "$FILE"; then
        sed -i '/^certificate_verification/d' "$FILE"
      fi
      sed -i '/^\[sssd\]/a certificate_verification = ocsp_dgst=sha1' "$FILE"
    else
      echo -e '[sssd]\ncertificate_verification = ocsp_dgst=sha1' >> "$FILE"
    fi
}




setup_admin_account() {
    local username="admin"
    local password="PredefinedPassword"  # Change this to your predefined password.
    local wheel_group="wheel"

    # Check if the admin account exists.
    if id "$username" &>/dev/null; then
        echo "User '$username' exists. Checking group membership..."
        # Check if the admin account is a member of the wheel group.
        if id -nG "$username" | grep -qw "$wheel_group"; then
            echo "User '$username' is already in the '$wheel_group' group."
        else
            echo "User '$username' is not in the '$wheel_group' group. Adding..."
            usermod -aG "$wheel_group" "$username"
            if [ $? -eq 0 ]; then
                echo "User '$username' successfully added to the '$wheel_group' group."
            else
                echo "Failed to add '$username' to the '$wheel_group' group."
            fi
        fi
    else
        echo "User '$username' does not exist. Creating account..."
        # Create the admin account, add it to the wheel group, and set the predefined password.
        useradd -m -s /bin/bash -G "$wheel_group" "$username"
        if [ $? -eq 0 ]; then
            echo "$username:$password" | chpasswd
            echo "User '$username' created with the predefined password and added to the '$wheel_group' group."
        else
            echo "Failed to create user '$username'."
        fi
    fi
}


# V-230296 Disable remote root login via SSH
v230296() {
    FILE="/etc/ssh/sshd_config"
    cp "$FILE" "$FILE.bak_$(date +%Y%m%d%H%M%S)"
    grep -q '^PermitRootLogin' "$FILE" && sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' "$FILE" || echo 'PermitRootLogin no' >> "$FILE"
}

# V-230302 Check if user home directories are mounted with 'noexec' option
v230302() {
    FILE="/etc/fstab"
    # Backup /etc/fstab with a timestamp
    cp "$FILE" "$FILE.bak_$(date +%Y%m%d%H%M%S)"
    echo "Backup of $FILE created."

    # Retrieve current /home mount details using findmnt
    device=$(findmnt -n -o SOURCE /home)
    fstype=$(findmnt -n -o FSTYPE /home)
    options=$(findmnt -n -o OPTIONS /home)

    # Check if the options already include 'noexec'
    if echo "$options" | grep -qw "noexec"; then
        echo "/home is already configured with the noexec option."
    else
        # Append noexec to the existing options and remove any leading/trailing commas
        new_options=$(echo "${options},noexec" | sed 's/^,\+//; s/,\+$//')
        # Construct the new fstab entry for /home
        entry="${device} /home ${fstype} ${new_options} 0 2"

        # If an entry for /home exists in /etc/fstab, replace it; otherwise, append the new entry.
        if grep -q "[[:space:]]/home[[:space:]]" "$FILE"; then
            sed -i "\|[[:space:]]/home[[:space:]]|c\\$entry" "$FILE"
        else
            echo "$entry" >> "$FILE"
        fi
        echo "Updated /etc/fstab entry for /home to include noexec."
    fi
}


# V-230311 Disable storing core dumps by configuring kernel.core_pattern
v230311() {
    DESIGNATED="/etc/sysctl.d/99-disable-core-dumps.conf"
    SYSCTL_CONF="/etc/sysctl.conf"

    # Backup /etc/sysctl.conf if it exists
    if [ -f "$SYSCTL_CONF" ]; then
        cp "$SYSCTL_CONF" "$SYSCTL_CONF.bak_$(date +%Y%m%d%H%M%S)"
        echo "Backup of $SYSCTL_CONF created."
        # Remove any uncommented kernel.core_pattern entries from /etc/sysctl.conf
        sed -i '/^[^#]*kernel\.core_pattern/d' "$SYSCTL_CONF"
        echo "Removed conflicting kernel.core_pattern entries from $SYSCTL_CONF."
    fi

    # List of directories to remove conflicting kernel.core_pattern entries from
    dirs=(/etc/sysctl.d /run/sysctl.d /usr/local/lib/sysctl.d /usr/lib/sysctl.d /lib/sysctl.d)

    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            for file in "$dir"/*.conf; do
                [ -e "$file" ] || continue
                # Skip the designated file if encountered
                if [ "$file" = "$DESIGNATED" ]; then
                    continue
                fi
                # Backup the file before modifying
                cp "$file" "$file.bak_$(date +%Y%m%d%H%M%S)"
                sed -i '/^[^#]*kernel\.core_pattern/d' "$file"
                echo "Removed conflicting kernel.core_pattern entries from $file."
            done
        fi
    done

    # Create or update the designated sysctl configuration file
    echo "kernel.core_pattern = |/bin/false" > "$DESIGNATED"
    echo "Created/Updated $DESIGNATED with: kernel.core_pattern = |/bin/false"

}


# V-230318 Fix ownership of all world-writable directories
v230318() {
    # Retrieve a list of local mount points
    partitions=$(df --local --output=target | tail -n +2)
    for part in $partitions; do
        echo "Processing partition: $part"
        # Find world-writable directories not owned by a system account (UID >= 1000)
        find "$part" -xdev -type d -perm -0002 -uid +999 2>/dev/null | while IFS= read -r dir; do
            echo "Changing owner of $dir to root"
            chown root "$dir"
        done
    done
    echo "Completed processing world-writable directories."
}


# V-230326/V-230327 Ensure all files and directories have valid user and group ownership
v230326_230327() {
  find / -xdev \( -nouser -o -nogroup \) -print0 2>/dev/null | while IFS= read -r -d '' file; do
    file_dir=$(dirname "$file")
    # Determine most common ownership among siblings
    dir_ownership=$(find "$file_dir" -maxdepth 1 -mindepth 1 -print0 2>/dev/null | \
      xargs -0 stat -c '%U:%G' 2>/dev/null | sort | uniq -c | sort -rn | head -n 1 | awk '{print $2}')

    if [ -n "$dir_ownership" ]; then
      echo "Assigning $dir_ownership to $file"
      chown "$dir_ownership" "$file"
    else
      parent_user=$(stat -c '%U' "$file_dir" 2>/dev/null)
      parent_group=$(stat -c '%G' "$file_dir" 2>/dev/null)
      if [ -n "$parent_user" ] && [ -n "$parent_group" ]; then
        echo "Assigning $parent_user:$parent_group to $file"
        chown "$parent_user:$parent_group" "$file"
      else
        echo "Defaulting $file to root:root"
        chown root:root "$file"
      fi
    fi
  done
}


# V-230337 Lock accounts after three unsuccessful logon attempts until released by an administrator
v230337() {
    FILE="/etc/security/faillock.conf"
    cp "$FILE" "$FILE.bak_$(date +%Y%m%d%H%M%S)"
    if grep -q '^unlock_time' "$FILE"; then
      sed -i 's/^unlock_time.*/unlock_time = 0/' "$FILE"
    else
      echo 'unlock_time = 0' >> "$FILE"
    fi
}

# V-230345 Include root in account lockout policy after unsuccessful logon attempts
# (Using the same file as above; no additional backup required)
v230345() {
    if grep -q '^even_deny_root' "/etc/security/faillock.conf"; then
      sed -i 's/^even_deny_root.*/even_deny_root/' "/etc/security/faillock.conf"
    else
      echo 'even_deny_root' >> "/etc/security/faillock.conf"
    fi
}

# V-230346 Ensure the number of concurrent sessions is limited to 10 for all accounts
v230346() {
    FILE="/etc/security/limits.conf"
    # Create a backup of the original file with a timestamp
    cp "$FILE" "$FILE.bak_$(date +%Y%m%d%H%M%S)"
    echo "Backup of $FILE created."

    # Remove any uncommented "* hard maxlogins" entries from limits.conf
    sed -i '/^[^#]*\*.*hard.*maxlogins/d' "$FILE"
    echo "Removed existing maxlogins entries from $FILE."

    # Create/update the dedicated file in limits.d with the desired setting
    LIMITS_D="/etc/security/limits.d/90-maxlogins.conf"
    echo "* hard maxlogins 10" > "$LIMITS_D"
    echo "Created/Updated $LIMITS_D with: * hard maxlogins 10"
}


# V-230479 The RHEL 8 audit records must be off-loaded onto a different system or storage media from the system being audited, no external logger yet
v230479() {
  REMOTE_LOG_SERVER="10.250.98.204"
  REMOTE_LOG_PORT="514"
  TIMESTAMP="$(date +%Y%m%d%H%M%S)"
  RSYSLOG_DIR="/etc/rsyslog.d"
  TARGET_CONF="${RSYSLOG_DIR}/99-remote-audit.conf"

  # Backup and comment out forwarding lines in /etc/rsyslog.conf
  if [ -f /etc/rsyslog.conf ]; then
    cp /etc/rsyslog.conf "/etc/rsyslog.conf.bak_${TIMESTAMP}"
    sed -i 's/^\(\s*\*\.\*\s\+\(@@\|@\|:omrelp:\)\)/#\1/' /etc/rsyslog.conf
  fi

  # Backup and sanitize *.conf files in /etc/rsyslog.d/
  for file in "$RSYSLOG_DIR"/*.conf; do
    [ -e "$file" ] || continue
    cp "$file" "${file}.bak_${TIMESTAMP}"
    sed -i 's/^\(\s*\*\.\*\s\+\(@@\|@\|:omrelp:\)\)/#\1/' "$file"
  done

  # Ensure rsyslog is installed
  rpm -q rsyslog >/dev/null || dnf install -y rsyslog

  # Write new remote logging rule
  cat <<EOF > "$TARGET_CONF"
*.* @@${REMOTE_LOG_SERVER}:${REMOTE_LOG_PORT}
EOF
  chmod 644 "$TARGET_CONF"

  systemctl restart rsyslog
  systemctl enable rsyslog

  logger "rsyslog remote logging configured to ${REMOTE_LOG_SERVER}:${REMOTE_LOG_PORT}"
}


# V-230481/230482 Ensure audit records are encrypted when off-loaded with rsyslog and remote logging server is authenticated
v230481_230482() {
	FILE="/etc/rsyslog.conf"
	BACKUP="${FILE}.bak_$(date +%Y%m%d%H%M%S)"

	# Create a backup safely
	cp "$FILE" "$BACKUP"

	# Safely gather files for grep
	CONF_FILES=("$FILE")
	shopt -s nullglob
	for f in /etc/rsyslog.d/*.conf; do
		CONF_FILES+=("$f")
	done
	shopt -u nullglob

	# Check and append each setting if not found
	if ! grep -q '^\$DefaultNetstreamDriver gtls' "${CONF_FILES[@]}" 2>/dev/null; then
		echo '$DefaultNetstreamDriver gtls' >> "$FILE"
	fi

	if ! grep -q '^\$ActionSendStreamDriverMode 1' "${CONF_FILES[@]}" 2>/dev/null; then
		echo '$ActionSendStreamDriverMode 1' >> "$FILE"
	fi

	if ! grep -q '^\$ActionSendStreamDriverAuthMode x509/name' "${CONF_FILES[@]}" 2>/dev/null; then
		echo '$ActionSendStreamDriverAuthMode x509/name' >> "$FILE"
	fi
	
}

# V-230494 disable the asynchronous transfer mode (ATM) protocol
v230494() {
    FILE="/etc/modprobe.d/blacklist.conf"
    cp "$FILE" "$FILE.bak_$(date +%Y%m%d%H%M%S)"
    sed -i '/^install atm/d' "$FILE"
    echo "install atm /bin/false" >> "$FILE"
    sed -i '/^blacklist atm/d' "$FILE"
    echo "blacklist atm" >> "$FILE"
}

# V-230495 disable the controller area network (CAN) protocol
v230495() {
    FILE="/etc/modprobe.d/blacklist.conf"
    cp "$FILE" "$FILE.bak_$(date +%Y%m%d%H%M%S)"
    sed -i '/^install can/d' "$FILE"
    echo "install can /bin/false" >> "$FILE"
    sed -i '/^blacklist can/d' "$FILE"
    echo "blacklist can" >> "$FILE"
}

# V-230496 disable the stream control transmission protocol (SCTP)
v230496() {
    FILE="/etc/modprobe.d/blacklist.conf"
    cp "$FILE" "$FILE.bak_$(date +%Y%m%d%H%M%S)"
    sed -i '/^install sctp/d' "$FILE"
    echo "install sctp /bin/false" >> "$FILE"
    sed -i '/^blacklist sctp/d' "$FILE"
    echo "blacklist sctp" >> "$FILE"
}

# V-230497 disable the transparent inter-process communication (TIPC) protocol
v230497() {
    FILE="/etc/modprobe.d/blacklist.conf"
    cp "$FILE" "$FILE.bak_$(date +%Y%m%d%H%M%S)"
    sed -i '/^install tipc/d' "$FILE"
    echo "install tipc /bin/false" >> "$FILE"
    sed -i '/^blacklist tipc/d' "$FILE"
    echo "blacklist tipc" >> "$FILE"
}

# V-230498 disable mounting of cramfs
v230498() {
    FILE="/etc/modprobe.d/blacklist.conf"
    cp "$FILE" "$FILE.bak_$(date +%Y%m%d%H%M%S)"
    sed -i '/^install cramfs/d' "$FILE"
    echo "install cramfs /bin/false" >> "$FILE"
    sed -i '/^blacklist cramfs/d' "$FILE"
    echo "blacklist cramfs" >> "$FILE"
}

# V-230499 disable IEEE 1394 (FireWire) Support
v230499() {
    FILE="/etc/modprobe.d/blacklist.conf"
    cp "$FILE" "$FILE.bak_$(date +%Y%m%d%H%M%S)"
    sed -i '/^install firewire-core/d' "$FILE"
    echo "install firewire-core /bin/false" >> "$FILE"
    sed -i '/^blacklist firewire-core/d' "$FILE"
    echo "blacklist firewire-core" >> "$FILE"
}

# V-230502 RHEL 8 file system automounter must be disabled unless required
v230502() {
	systemctl stop autofs
	systemctl disable autofs
}

# V-230503 disable USB mass storage
v230503() {
    FILE="/etc/modprobe.d/blacklist.conf"
    cp "$FILE" "$FILE.bak_$(date +%Y%m%d%H%M%S)"
    sed -i '/^install usb-storage/d' "$FILE"
    echo "install usb-storage /bin/false" >> "$FILE"
    sed -i '/^blacklist usb-storage/d' "$FILE"
    echo "blacklist usb-storage" >> "$FILE"
}

# V-230504 firewall must employ a deny-all, allow-by-exception policy for allowing connections to other systems
v230504() {
    # Ensure firewalld is installed and running
    if ! systemctl is-active firewalld >/dev/null 2>&1; then
        echo "firewalld is not running. Please install and start firewalld before running this fix."
        return 1
    fi

    # Detect currently listening TCP and UDP ports before making any changes
    echo "Detecting listening ports..."
    allowed_ports=$(ss -tuln | awk 'NR>1 {
        proto = tolower($1);
        if (match($5, /([^:]+):([0-9]+)$/, a)) {
            print a[2] "/" proto;
        }
    }' | sort -u)
    echo "Detected ports:"
    echo "$allowed_ports"

    # Define the custom zone name and file paths
    ZONE="custom"
    ZONEFILE="/etc/firewalld/zones/${ZONE}.xml"
    DROPFILE="/usr/lib/firewalld/zones/drop.xml"

    # Always start with a fresh custom zone file.
    if [ -f "$ZONEFILE" ]; then
        backup_file="${ZONEFILE}.bak_$(date +%Y%m%d%H%M%S)"
        echo "Existing $ZONEFILE found. Backing it up to $backup_file..."
        cp "$ZONEFILE" "$backup_file"
    fi

    # Verify drop.xml exists and copy it to create a new custom zone file.
    if [ ! -f "$DROPFILE" ]; then
        echo "drop.xml not found at $DROPFILE. Cannot proceed."
        return 1
    fi

    echo "Creating new custom zone file based on drop.xml..."
    cp "$DROPFILE" "$ZONEFILE"
    # Change the short name to our custom zone name
    sed -i "s/<short>Drop<\/short>/<short>${ZONE}<\/short>/" "$ZONEFILE"
    echo "Custom zone file updated at $ZONEFILE."

    # Reset the firewall to clear any existing runtime rules and start fresh.
    echo "Resetting firewall configuration..."
    firewall-cmd --complete-reload
    echo "Firewall configuration reset."

    # Define predefined networks (only these sources will be allowed access to detected ports).
    PREDEFINED_NETWORKS=("127.0.0.0/8" "::1/128" "10.250.0.0/16" "10.251.0.0/16" "10.255.0.0/16")

    # Add allowed ports as rich rules to the custom zone but only for connections from the predefined networks.
    if [ -n "$allowed_ports" ]; then
        echo "Adding rich rules for detected ports in zone $ZONE, restricted to predefined networks..."
        while IFS= read -r port_proto; do
            port=$(echo "$port_proto" | cut -d'/' -f1)
            proto=$(echo "$port_proto" | cut -d'/' -f2)
            for network in "${PREDEFINED_NETWORKS[@]}"; do
                if [[ "$network" == *:* ]]; then
                    family="ipv6"
                else
                    family="ipv4"
                fi
                echo "  Adding rich rule for port: $port, protocol: $proto for network: $network (family: $family)"
                firewall-cmd --permanent --zone="$ZONE" --add-rich-rule="rule family='$family' source address='$network' port protocol='$proto' port='$port' accept"
            done
        done <<< "$allowed_ports"
    else
        echo "No listening ports detected; skipping port rich rules."
    fi

    # Reassign non-loopback interfaces to the custom zone if not already set.
    interfaces=$(ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$')
    for iface in $interfaces; do
        current_zone=$(firewall-cmd --get-zone-of-interface="$iface" 2>/dev/null)
        if [ "$current_zone" != "$ZONE" ]; then
            echo "Assigning interface $iface to zone $ZONE..."
            firewall-cmd --permanent --zone="$ZONE" --change-interface="$iface"
        else
            echo "Interface $iface is already in zone $ZONE."
        fi
    done

    # Set the custom zone as the default zone (drop by default unless matched by rich rules)
    firewall-cmd --set-default-zone="$ZONE"
    echo "Default zone set to $ZONE (drop by default unless matched by rich rules)."

    # Reload firewall configuration to apply all changes
    firewall-cmd --reload
    echo "Firewall configuration reloaded."
    echo "Custom drop-by-default, allow-by-exception firewall setup completed."
}






# V-230511 mount /tmp with the nodev option
# V-230512 mount /tmp with the nosuid option
# V-230513 mount /tmp with the noexec option
v230511_230512_230513() {
    FILE="/etc/fstab"
    # Backup fstab
    cp "$FILE" "$FILE.bak_$(date +%Y%m%d%H%M%S)"
    
    # Get current device and filesystem type for /tmp
    device=$(findmnt -n -o SOURCE /tmp)
    fstype=$(findmnt -n -o FSTYPE /tmp)
    
    # Define the desired fstab entry for /tmp
    entry="${device} /tmp ${fstype} defaults,nodev,nosuid,noexec 0 0"
    
    # If an entry for /tmp exists in /etc/fstab, replace it; otherwise, append the new entry.
    if grep -q "[[:space:]]/tmp[[:space:]]" "$FILE"; then
        # Replace the existing /tmp entry with our new entry.
        sed -i "\|[[:space:]]/tmp[[:space:]]|c\\$entry" "$FILE"
    else
        echo "$entry" >> "$FILE"
    fi
}

# V-230524 block unauthorized peripherals before establishing a connection 
v230524() {
	echo "pass"
    # FILE="/etc/usbguard/rules.conf"
    # cp "$FILE" "$FILE.bak_$(date +%Y%m%d%H%M%S)"
    # usbguard generate-policy > "$FILE"
    # systemctl enable usbguard
    # systemctl restart usbguard
}

# V-230546 Restrict usage of ptrace to descendant processes
v230546() {
    FILE="/etc/sysctl.d/99-ptrace-restriction.conf"
    cp "$FILE" "$FILE.bak_$(date +%Y%m%d%H%M%S)"
    echo 'kernel.yama.ptrace_scope = 1' > "$FILE"
    for file in /run/sysctl.d/*.conf \
                /usr/local/lib/sysctl.d/*.conf \
                /usr/lib/sysctl.d/*.conf \
                /lib/sysctl.d/*.conf \
                /etc/sysctl.conf \
                /etc/sysctl.d/*.conf; do
      if [ "$file" != "$FILE" ]; then
        if grep -q '^kernel\.yama\.ptrace_scope' "$file"; then
          cp "$file" "$file.bak_$(date +%Y%m%d%H%M%S)"
          sed -i '/^kernel\.yama\.ptrace_scope/d' "$file"
        fi
      fi
    done
}

# V-230555 Disable X11 forwarding in SSH configuration
v230555() {
    FILE="/etc/ssh/sshd_config"
    cp "$FILE" "$FILE.bak_$(date +%Y%m%d%H%M%S)"
    if grep -q '^X11Forwarding' "$FILE"; then
      sed -i 's/^X11Forwarding.*/X11Forwarding no/' "$FILE"
    else
      echo 'X11Forwarding no' >> "$FILE"
    fi
}

# V-230561 The tuned package must not be installed unless mission essential
v230561() {
    dnf remove -y tuned
}

# V-244530 prevent files with the setuid and setgid bit set from being executed on the /boot/efi directory
v244530() {
    FILE="/etc/fstab"
    # Backup fstab
    cp "$FILE" "$FILE.bak_$(date +%Y%m%d%H%M%S)"
    
    # Retrieve current /boot/efi mount details using findmnt
    device=$(findmnt -n -o SOURCE /boot/efi)
    fstype=$(findmnt -n -o FSTYPE /boot/efi)
    options=$(findmnt -n -o OPTIONS /boot/efi)
    
    # If the options already include 'nosuid', then nothing needs to be changed.
    if echo "$options" | grep -qw "nosuid"; then
        echo "/boot/efi is already configured with the nosuid option."
    else
        # Append nosuid to the existing options (remove any leading/trailing commas)
        new_options=$(echo "${options},nosuid" | sed 's/^,\+//; s/,\+$//')
        # Construct the new fstab entry for /boot/efi
        entry="${device} /boot/efi ${fstype} ${new_options} 0 0"
        
        # If an entry for /boot/efi already exists, replace it; otherwise, append the new entry.
        if grep -q "[[:space:]]/boot/efi[[:space:]]" "$FILE"; then
            sed -i "\|[[:space:]]/boot/efi[[:space:]]|c\\$entry" "$FILE"
        else
            echo "$entry" >> "$FILE"
        fi
        echo "Updated /etc/fstab entry for /boot/efi to include nosuid."
    fi
}

v244531() {
  # Process only interactive users whose home directories are under /home.
  # This awk command extracts the home directory field from /etc/passwd for users with an interactive shell.
  awk -F: '($6 ~ /^\/home\// && $7 !~ /(nologin|false)/) {print $6}' /etc/passwd | while read home_dir; do
    if [ -d "$home_dir" ]; then
      echo "Processing home directory: $home_dir"
      # The find command does the following:
      # -mindepth 1           : skips the home directory itself
      # -not -name ".*"        : excludes any file or directory whose basename starts with a dot
      # -perm /0027           : finds files with ANY disallowed bits (group write (0020) or any permission for others (0007))
      # -exec chmod 0750 {} \; : fixes the permission by setting it to 0750
      find "$home_dir" -mindepth 1 -not -name ".*" -perm /0027 -exec chmod 0750 {} \;
    fi
  done
}


# V-244532 Ensure files and directories in user home directories are group-owned by the user's group
v244532() {
    for user_home in $(awk -F: '$3 >= 1000 && $1 != "nobody" {print $6}' /etc/passwd); do
      user=$(basename "$user_home")
      user_groups=$(id -nG "$user")
      find "$user_home" -exec stat -c '%n %G' {} \; | while read -r file group; do
        if ! echo "$user_groups" | grep -qw "$group"; then
          chgrp "$user" "$file"
        fi
      done
    done
}



# V-244548 enable the USBGuard
v244548() {
    systemctl enable --now usbguard.service
}

# V-250317 Disable IPv4 packet forwarding unless the system is a router
v250317() {
    CFG_FILE="/etc/sysctl.d/99-disable-ipv4-forwarding.conf"
    
    [ -f "$CFG_FILE" ] && cp "$CFG_FILE" "$CFG_FILE.bak_$(date +%Y%m%d%H%M%S)"
    echo "net.ipv4.conf.all.forwarding=0" > "$CFG_FILE"
    echo "Configured $CFG_FILE with:  net.ipv4.conf.all.forwarding = 0"
    
    conflict_files=(/run/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /etc/sysctl.conf /etc/sysctl.d/*.conf)
    
    for file in "${conflict_files[@]}"; do
        [ -e "$file" ] || continue
        if [ "$file" == "$CFG_FILE" ]; then
            continue
        fi
        if [ -f "$file" ]; then
            cp "$file" "$file.bak_$(date +%Y%m%d%H%M%S)"
            sed -i '/^net\.ipv4\.conf\.all\.forwarding/d' "$file"
            echo "Removed conflicting entries from: $file"
        fi
    done
}

# V-251710 Ensure AIDE is installed, initialized, and verifying file integrity
v251710() {
  # Check if AIDE is already running
  if pgrep -x "aide" > /dev/null; then
    echo "AIDE is already running. Skipping AIDE check."
    return 0
  fi

  # Install AIDE if it is not installed
  if ! rpm -q aide > /dev/null 2>&1; then
    dnf install -y aide
  fi

  # Initialize the AIDE database if it doesn't exist
  if [ ! -f /var/lib/aide/aide.db.gz ]; then
    /usr/sbin/aide --init
    mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
  fi

  # Run AIDE check
  /usr/sbin/aide --check || true
}


# V-257258 RHEL 8.7 and higher must terminate idle user sessions
v257258() {
    FILE="/etc/systemd/logind.conf"
    cp "$FILE" "$FILE.bak_$(date +%Y%m%d%H%M%S)"
    if grep -q "^StopIdleSessionSec" "$FILE"; then
        sed -i 's/^StopIdleSessionSec.*/StopIdleSessionSec=600/' "$FILE"
    else
        echo "StopIdleSessionSec=600" >> "$FILE"
    fi
    systemctl restart systemd-logind
}
