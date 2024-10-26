Integrating CAC (Common Access Card) or smart card authentication with Active Directory (AD) on a Red Hat Enterprise Linux (RHEL) system allows users to authenticate using their smart cards alongside their AD credentials. This setup enhances security by leveraging multi-factor authentication and complies with various organizational security policies, such as those required by government agencies.

Below is a comprehensive guide to configure CAC/smart card authentication with AD credentials on RHEL.

---

### **Prerequisites**

1. **Root Access:** You need administrative privileges on the RHEL system.
2. **Active Directory Integration:** The RHEL system must already be joined to the AD domain (as per your previous setup).
3. **Smart Card Hardware:**
   - A compatible smart card reader connected to the RHEL system.
   - User smart cards (e.g., CAC) with valid certificates.
4. **Middleware and Drivers:**
   - **pcsc-lite:** Middleware to communicate with smart card readers.
   - **OpenSC:** Tools and libraries for smart card support.
   - **CCID Drivers:** For USB smart card readers.
5. **Certificates:**
   - Trusted CA certificates used to sign the smart card certificates.
   - The smart card certificates should map to user accounts in AD.
6. **Time Synchronization:** Ensure time is synchronized to prevent Kerberos issues.
7. **Firewall Configuration:** Allow necessary ports for smart card authentication.

---

### **Step 1: Install Necessary Packages**

Install the required packages for smart card support:

```bash
sudo yum install pcsc-lite pcsc-lite-libs pcsc-lite-ccid opensc pam_pkcs11
```

- **pcsc-lite:** Middleware to communicate with smart card readers.
- **pcsc-lite-ccid:** Driver for USB CCID smart card readers.
- **opensc:** Tools and libraries for smart card support.
- **pam_pkcs11:** PAM module for smart card authentication.

---

### **Step 2: Start and Enable pcscd Service**

The `pcscd` daemon handles communication with the smart card reader:

```bash
sudo systemctl start pcscd
sudo systemctl enable pcscd
```

Verify that the service is running:

```bash
sudo systemctl status pcscd
```

---

### **Step 3: Verify Smart Card Reader and Card Detection**

1. **List Connected Readers:**

   ```bash
   opensc-tool --list-readers
   ```

   You should see output indicating that your smart card reader is detected.

2. **Test Smart Card Communication:**

   Insert a smart card and run:

   ```bash
   pkcs11-tool --list-slots
   ```

   This should display information about the smart card in the reader.

---

### **Step 4: Install Trusted CA Certificates**

Install the CA certificates that are used to sign the smart card certificates.

1. **Obtain CA Certificates:**

   - Acquire the root and intermediate CA certificates in PEM format.

2. **Install Certificates in System Trust Store:**

   Copy the certificates to `/etc/pki/ca-trust/source/anchors/`:

   ```bash
   sudo cp /path/to/ca_cert.pem /etc/pki/ca-trust/source/anchors/
   ```

3. **Update the Trust Store:**

   ```bash
   sudo update-ca-trust extract
   ```

---

### **Step 5: Configure PAM for Smart Card Authentication**

1. **Backup Existing PAM Configuration Files:**

   ```bash
   sudo cp /etc/pam.d/system-auth /etc/pam.d/system-auth.bak
   sudo cp /etc/pam.d/password-auth /etc/pam.d/password-auth.bak
   ```

2. **Edit `/etc/pam.d/system-auth` and `/etc/pam.d/password-auth`:**

   Add the following lines to integrate `pam_pkcs11`:

   **Insert After the First `auth` Line:**

   ```plaintext
   auth        sufficient    pam_pkcs11.so
   ```

   **Example Modified `system-auth` File:**

   ```plaintext
   auth        required      pam_env.so
   auth        sufficient    pam_pkcs11.so
   auth        sufficient    pam_unix.so nullok try_first_pass
   auth        requisite     pam_succeed_if.so uid >= 1000 quiet_success
   auth        required      pam_deny.so

   account     required      pam_unix.so
   account     sufficient    pam_localuser.so
   account     sufficient    pam_succeed_if.so uid < 1000 quiet
   account     required      pam_permit.so

   password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type=
   password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok
   password    required      pam_deny.so

   session     optional      pam_keyinit.so revoke
   session     required      pam_limits.so
   session     [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid
   session     required      pam_unix.so
   ```

3. **Configure `pam_pkcs11`:**

   Edit `/etc/pam_pkcs11/pam_pkcs11.conf`:

   - Define the mapping between certificate fields and user accounts.
   - Example mapping:

     ```plaintext
     use_mappers = subject_dn;

     mapper subject_dn {
         debug = true;
         module = internal;
         ignorecase = true;
         domain = yourdomain.com;
     }

     cert_policy {
         verify_sig = yes;
         verify_cert = yes;
         crl_check = none;
         ocsp_enabled = false;
     }
     ```

4. **Specify the PKCS#11 Module:**

   Ensure the correct module is specified in `/etc/pam_pkcs11/pam_pkcs11.conf`:

   ```plaintext
   pkcs11_module opensc {
       module = /usr/lib64/opensc-pkcs11.so;
       description = "OpenSC PKCS#11 Module";
   }
   ```

5. **Set Permissions:**

   ```bash
   sudo chmod 600 /etc/pam_pkcs11/pam_pkcs11.conf
   ```

---

### **Step 6: Configure SSSD for Smart Card Authentication**

Edit `/etc/sssd/sssd.conf` and adjust the configuration to support smart card authentication.

1. **Enable Smart Card Authentication:**

   In the `[domain/yourdomain.com]` section, add:

   ```ini
   [domain/yourdomain.com]
   auth_provider = krb5
   krb5_server = your.ad.domain.controller
   krb5_realm = YOURDOMAIN.COM
   krb5_store_password_if_offline = True
   krb5_auth_timeout = 15

   pam_cert_auth = True
   certificate_verification = no_ocsp
   ```

2. **Set Certificate Matching Rules:**

   Define how the certificate maps to the user account. For example:

   ```ini
   ldap_user_principal = userPrincipalName
   ldap_user_certificate = userCertificate;binary
   ldap_id_use_start_tls = True
   ldap_tls_reqcert = demand
   ```

3. **Adjust Other SSSD Settings:**

   - Ensure `ldap_id_mapping` is set correctly.
   - If using LDAP for identity, ensure `id_provider = ldap`.

4. **Ensure `sssd.conf` Permissions:**

   ```bash
   sudo chmod 600 /etc/sssd/sssd.conf
   ```

5. **Restart SSSD Service:**

   ```bash
   sudo systemctl restart sssd
   ```

---

### **Step 7: Configure NSS and OpenSSL**

Ensure that the system trusts the certificates and can verify them during authentication.

1. **Update NSS Database:**

   Import the CA certificates into the NSS database used by `p11-kit`:

   ```bash
   sudo certutil -A -d /etc/pki/nssdb -n "Your CA Name" -t "CT,C,C" -a -i /path/to/ca_cert.pem
   ```

2. **Verify Certificates:**

   Ensure that the certificates are recognized and can be used for authentication.

---

### **Step 8: Configure OpenSSH for Smart Card Authentication (Optional)**

If you need smart card authentication over SSH:

1. **Ensure OpenSSH Supports Smart Cards:**

   RHEL's OpenSSH version supports PKCS#11 directly.

2. **Edit `/etc/ssh/sshd_config`:**

   Enable smart card authentication:

   ```plaintext
   PubkeyAuthentication yes
   AuthenticationMethods publickey,keyboard-interactive
   UsePAM yes
   SmartcardDevice /usr/lib64/opensc-pkcs11.so
   ```

3. **Restart SSH Service:**

   ```bash
   sudo systemctl restart sshd
   ```

---

### **Step 9: Configure Certificate Mapping in Active Directory**

In Active Directory, ensure that user accounts are mapped to their smart card certificates.

1. **Publish User Certificates:**

   - Use AD Users and Computers to publish the user's smart card certificate to their account.
   - Alternatively, ensure that the `userPrincipalName` or other identifiers match between the certificate and the AD account.

2. **Set `altSecurityIdentities`:**

   - The `altSecurityIdentities` attribute in AD can be used to map certificates to user accounts.
   - Example value:

     ```
     X509:<I>CN=YourCA,O=YourOrg,C=US<S>CN=User Name,OU=Department,O=YourOrg,C=US
     ```

   - Adjust according to your certificate's Issuer (I) and Subject (S) fields.

---

### **Step 10: Test Smart Card Authentication**

1. **Local Login Test:**

   - Log out of your current session.
   - Insert your smart card.
   - Attempt to log in using the smart card.

2. **Verify Authentication Logs:**

   Check `/var/log/secure` and `/var/log/messages` for any errors during authentication.

3. **SSH Login Test (If Configured):**

   - Attempt to SSH into the system using your smart card.
   - Use an SSH client that supports smart card authentication.

---

### **Troubleshooting**

- **Check pcscd Status:**

  Ensure `pcscd` is running and recognizing the smart card:

  ```bash
  sudo systemctl status pcscd
  opensc-tool --list-readers
  ```

- **Verify Certificates:**

  Use `certutil` to list certificates and ensure the CA certificates are trusted.

- **PAM Configuration Issues:**

  Ensure that the PAM configuration files (`/etc/pam.d/system-auth`, `/etc/pam.d/password-auth`) are correctly configured.

- **SSSD Logs:**

  Enable verbose logging in `/etc/sssd/sssd.conf`:

  ```ini
  [sssd]
  debug_level = 9
  ```

  Restart SSSD and check logs in `/var/log/sssd/`.

- **SELinux Policies:**

  If SELinux is enforcing, check for any denials:

  ```bash
  sudo ausearch -m avc -ts recent
  ```

  Create appropriate policies or set SELinux to permissive mode for testing:

  ```bash
  sudo setenforce 0
  ```

- **Certificate Validation Issues:**

  Ensure that the certificate chain is complete and trusted on the RHEL system.

- **Firewall Ports:**

  Ensure that the necessary ports for Kerberos, LDAP, and smart card authentication are open.

---

### **Additional Configuration**

- **Enforce Smart Card Authentication:**

  To require smart card authentication for all users:

  1. **Modify PAM Configuration:**

     Adjust the PAM stack to only allow smart card authentication and disable password-based login.

     - In `/etc/pam.d/system-auth` and `/etc/pam.d/password-auth`, set `pam_unix.so` to `required` but ensure `pam_pkcs11.so` is `sufficient`.

  2. **Disable Password Authentication in SSH:**

     In `/etc/ssh/sshd_config`, set:

     ```plaintext
     PasswordAuthentication no
     ChallengeResponseAuthentication no
     ```

     Restart SSH service:

     ```bash
     sudo systemctl restart sshd
     ```

- **Configure OCSP/CRL for Certificate Revocation:**

  If you need to check certificate revocation status:

  1. **Enable OCSP in SSSD:**

     ```ini
     certificate_verification = ocsp_during_auth
     ```

  2. **Install and Configure `certmonger`:**

     ```bash
     sudo yum install certmonger
     sudo systemctl start certmonger
     sudo systemctl enable certmonger
     ```

---

### **Security Considerations**

- **Protect Private Keys:**

  Ensure that private keys are securely stored on smart cards and cannot be extracted.

- **Regularly Update CA Certificates:**

  Keep the trusted CA certificates up to date to prevent unauthorized access.

- **Monitor Authentication Logs:**

  Regularly review logs for unauthorized access attempts or errors.

- **Implement Multi-Factor Authentication Policies:**

  Use smart cards in conjunction with other security measures as per your organization's policies.

---

### **References**

- **Red Hat Documentation:**
  - [Using Smart Cards for System Authentication](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_authentication_and_authorization_in_rhel/using-smart-cards-for-system-authentication_configuring-authentication-and-authorization-in-rhel)
- **SSSD Documentation:**
  - [SSSD and Smart Cards](https://sssd.io/docs/users/smartcards.html)
- **PAM Configuration:**
  - [Linux PAM Smart Card Authentication](https://www.linux-pam.org/Linux-PAM-html/Linux-PAM_SAG.html)
- **OpenSC Project:**
  - [OpenSC Documentation](https://github.com/OpenSC/OpenSC/wiki)
