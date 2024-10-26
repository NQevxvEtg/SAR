Connecting a Red Hat Enterprise Linux (RHEL) system to a Windows Active Directory (AD) domain allows you to authenticate Linux users using AD credentials. This integration simplifies user management and enhances security by centralizing authentication. Below is a step-by-step guide to achieve this integration.

---

### **Prerequisites**

1. **Administrator Access:** You need root access on the RHEL system.
2. **Active Directory Credentials:** A domain account with permission to join computers to the domain.
3. **Network Configuration:** Ensure the Linux system can resolve the AD domain and communicate over the necessary ports (e.g., DNS, Kerberos).
4. **Time Synchronization:** The Linux system's time must be synchronized with the AD domain controllers (preferably via NTP) to prevent Kerberos authentication issues.

---

### **Step 1: Install Required Packages**

Install the necessary packages for realmd and SSSD (System Security Services Daemon):

```bash
sudo yum install realmd sssd oddjob oddjob-mkhomedir adcli samba-common-tools krb5-workstation
```

- **realmd:** Discovers and joins domains.
- **sssd:** Provides access to remote identity and authentication providers.
- **oddjob and oddjob-mkhomedir:** Automatically create home directories for AD users.
- **adcli:** Used by realmd to join the domain.
- **samba-common-tools and krb5-workstation:** Provide necessary utilities for Kerberos and Samba.

---

### **Step 2: Configure DNS and Hostname**

Ensure that your Linux system's hostname is fully qualified and resolvable:

1. **Set the Hostname:**

   ```bash
   sudo hostnamectl set-hostname yourhostname.yourdomain.com
   ```

2. **Update `/etc/hosts`** (if necessary):

   Open `/etc/hosts` and add an entry for your fully qualified domain name (FQDN):

   ```
   192.168.1.100 yourhostname.yourdomain.com yourhostname
   ```

3. **Configure DNS:**

   Update `/etc/resolv.conf` to use your AD domain's DNS servers:

   ```
   nameserver 192.168.1.1  # Replace with your DNS server IP
   search yourdomain.com
   ```

---

### **Step 3: Synchronize Time with NTP**

Kerberos requires time synchronization between the client and the server:

1. **Install NTP:**

   ```bash
   sudo yum install ntp
   ```

2. **Configure NTP to Use AD Domain Controllers:**

   Edit `/etc/ntp.conf` and add your domain controllers:

   ```
   server dc1.yourdomain.com prefer
   server dc2.yourdomain.com
   ```

3. **Start and Enable NTP Service:**

   ```bash
   sudo systemctl start ntpd
   sudo systemctl enable ntpd
   ```

---

### **Step 4: Discover the Active Directory Domain**

Use `realm` to discover the domain:

```bash
realm discover yourdomain.com
```

This command should return information about the domain, confirming that it is reachable.

---

### **Step 5: Join the Linux System to the AD Domain**

Join the domain using an account with the necessary permissions:

```bash
sudo realm join --user=administrator yourdomain.com
```

- You will be prompted for the password of the `administrator` account.
- Replace `administrator` with a user account that has permission to join computers to the domain.

**Note:** If you encounter any issues, add the `--verbose` flag for more detailed output.

---

### **Step 6: Verify Domain Membership**

Check the domain configuration:

```bash
realm list
```

You should see your domain listed with associated configuration details.

---

### **Step 7: Configure SSSD**

SSSD handles authentication and identity information:

1. **Edit `/etc/sssd/sssd.conf`:**

   Ensure the configuration includes the following:

   ```ini
   [sssd]
   services = nss, pam
   config_file_version = 2
   domains = yourdomain.com

   [domain/yourdomain.com]
   id_provider = ad
   auth_provider = ad
   access_provider = ad
   cache_credentials = True
   default_shell = /bin/bash
   fallback_homedir = /home/%u@%d
   use_fully_qualified_names = False  # Set to True if you want user@domain format
   ```
   
2. **Set Permissions:**

   ```bash
   sudo chmod 600 /etc/sssd/sssd.conf
   ```

3. **Restart SSSD Service:**

   ```bash
   sudo systemctl restart sssd
   ```

---

### **Step 8: Configure PAM for Home Directory Creation**

Ensure that home directories are created automatically upon first login:

1. **Edit `/etc/pam.d/common-session` or `/etc/pam.d/system-auth`:**

   Add the following line if it's not already present:

   ```
   session required pam_mkhomedir.so skel=/etc/skel/ umask=0077
   ```

---

### **Step 9: Update SSH Configuration (Optional)**

If users will log in via SSH, you may need to update the SSH daemon configuration:

1. **Edit `/etc/ssh/sshd_config`:**

   Ensure the following options are set:

   ```
   UseDNS no
   GSSAPIAuthentication yes
   GSSAPICleanupCredentials yes
   ```

2. **Restart SSH Service:**

   ```bash
   sudo systemctl restart sshd
   ```

---

### **Step 10: Test Authentication**

1. **Identify a Domain User:**

   Use the `id` command to check if the domain user is recognized:

   ```bash
   id username@yourdomain.com
   ```

   If you set `use_fully_qualified_names = False`, you can use:

   ```bash
   id username
   ```

2. **Attempt to Switch User:**

   ```bash
   su - username
   ```

3. **Log In via SSH:**

   Try logging in remotely using the domain credentials.

---

### **Troubleshooting**

- **Check Logs:**

  Review `/var/log/secure`, `/var/log/sssd/sssd.log`, and `/var/log/messages` for any errors.

- **SSSD Cache:**

  If you make changes, you may need to clear the SSSD cache:

  ```bash
  sudo sss_cache -E
  ```

- **Firewall Settings:**

  Ensure that the firewall allows necessary ports (e.g., Kerberos uses port 88).

- **SELinux Policies:**

  If SELinux is enforcing, ensure it is not blocking authentication. You can check logs in `/var/log/audit/audit.log`.

---

### **Additional Configuration (Optional)**

- **Restrict Login Access:**

  By default, all domain users can log in. To restrict access:

  1. **Edit `/etc/sssd/sssd.conf`:**

     ```ini
     access_provider = simple
     ```

  2. **Define Allowed Users:**

     Create or edit `/etc/sssd/conf.d/access.conf`:

     ```ini
     [domain/yourdomain.com]
     simple_allow_users = user1, user2
     simple_allow_groups = group1, group2
     ```

  3. **Restart SSSD:**

     ```bash
     sudo systemctl restart sssd
     ```

- **Enable Password Change:**

  To allow users to change their AD passwords from the Linux system:

  Ensure that `krb5-workstation` is installed, and PAM is configured correctly.

---

### **Security Considerations**

- **Encryption:**

  Ensure that communications between the Linux system and AD are encrypted. By default, Kerberos and LDAP use encryption, but you may enforce LDAPS if required.

- **Sudo Access:**

  Configure `/etc/sudoers` or use `sudoers.d` to grant specific domain users or groups sudo privileges.

---

### **References**

- **Red Hat Documentation:** [Integrating with Active Directory](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_authentication_and_authorization_in_rhel/connecting-rhel-systems-directly-to-an-active-directory-domain_configuring-authentication-and-authorization-in-rhel)
- **SSSD Configuration:** [SSSD Man Pages](https://sssd.io/docs/users/configure.html)

---

