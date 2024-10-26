## **Prerequisites**

1. **Administrative Access:**
   - Access to the Keycloak administration console.
   - Administrative credentials for the Windows AD domain.

2. **Keycloak Installation:**
   - Keycloak server installed and running (version 9.0 or later recommended).

3. **Active Directory:**
   - Windows AD domain controller accessible from the Keycloak server.
   - LDAP over SSL (LDAPS) configured on AD (port 636).

4. **Smart Card/CAC Infrastructure:**
   - Smart card readers installed on client machines.
   - Middleware (e.g., ActivClient for Windows, OpenSC for Linux) installed on client machines.
   - User certificates properly mapped in AD and present on smart cards.

5. **Certificates:**
   - AD domain controller certificates and CA certificates available.
   - Client machines have necessary CA certificates to validate server certificates.

6. **Networking:**
   - Network connectivity between Keycloak server and AD domain controller.
   - Clients can reach the Keycloak server over HTTPS.

---

## **Step 1: Install and Configure Keycloak**

### **1.1 Install Keycloak**

If you haven't installed Keycloak yet, follow these steps:

1. **Download Keycloak:**

   ```bash
   wget https://github.com/keycloak/keycloak/releases/download/17.0.1/keycloak-17.0.1.tar.gz
   ```

2. **Extract Keycloak:**

   ```bash
   tar -xzf keycloak-17.0.1.tar.gz
   ```

3. **Move to Installation Directory:**

   ```bash
   sudo mv keycloak-17.0.1 /opt/keycloak
   ```

### **1.2 Create a System User for Keycloak**

```bash
sudo useradd keycloak
sudo chown -R keycloak:keycloak /opt/keycloak
```

### **1.3 Configure Keycloak Admin User**

```bash
/opt/keycloak/bin/kc.sh create-admin --user admin --password admin_password
```

### **1.4 Start Keycloak**

```bash
/opt/keycloak/bin/kc.sh start-dev
```

> **Note:** For production environments, configure Keycloak to run as a service and not in development mode.

---

## **Step 2: Configure Active Directory for LDAP over SSL (LDAPS)**

### **2.1 Install AD CS (If Not Already Installed)**

On the AD server, install Active Directory Certificate Services (AD CS) to enable LDAPS.

### **2.2 Generate a Certificate for the Domain Controller**

1. **Open Server Manager** and add the **Certification Authority** role.

2. **Request a Domain Controller Certificate:**

   - Open **Certification Authority** MMC.
   - Right-click **Certificate Templates** > **Manage**.
   - Duplicate the **Kerberos Authentication** template.
   - Name it **Domain Controller Authentication**.
   - Enable **Publish certificate in Active Directory**.

3. **Enroll the Certificate:**

   - Open **MMC** and add the **Certificates** snap-in for **Computer account**.
   - Right-click **Personal** > **Certificates** > **All Tasks** > **Request New Certificate**.
   - Enroll for the **Domain Controller Authentication** certificate.

### **2.3 Verify LDAPS Functionality**

On the Keycloak server, test the LDAPS connection:

```bash
openssl s_client -connect ad.yourdomain.com:636 -showcerts
```

- Replace `ad.yourdomain.com` with your AD domain controller's hostname.
- Verify that the connection is successful and certificates are displayed.

---

## **Step 3: Configure Keycloak to Connect to Active Directory**

### **3.1 Import AD CA Certificate into Keycloak Truststore**

1. **Export the AD CA Certificate:**

   On the AD server:

   - Open **Certification Authority** MMC.
   - Right-click on **CA Name** > **Properties** > **View Certificate**.
   - Go to **Details** > **Copy to File** > Export as **Base-64 encoded X.509 (.CER)**.

2. **Copy the CA Certificate to Keycloak Server**

   ```bash
   scp user@ad.yourdomain.com:/path/to/ca_cert.cer /opt/keycloak/
   ```

3. **Import the CA Certificate into Java Truststore**

   ```bash
   sudo keytool -import -alias ad_ca -file /opt/keycloak/ca_cert.cer -keystore /usr/lib/jvm/java-11-openjdk/lib/security/cacerts -storepass changeit -noprompt
   ```

   - Replace `/usr/lib/jvm/java-11-openjdk` with your Java installation path.
   - The default password for the Java truststore is `changeit`.

### **3.2 Restart Keycloak**

```bash
sudo systemctl restart keycloak
```

> **Note:** If running Keycloak manually, stop and start the server.

### **3.3 Configure LDAP User Federation in Keycloak**

1. **Log into Keycloak Admin Console:**

   - URL: `http://<keycloak-server>:8080/`
   - Use admin credentials.

2. **Create a Realm (Optional):**

   - Click **Add Realm**.
   - Enter a name (e.g., `myrealm`).

3. **Add LDAP Provider:**

   - Go to **User Federation**.
   - Click **Add provider** > Select **ldap**.

4. **Configure LDAP Settings:**

   - **Edit Mode:** `READ_ONLY`.
   - **Vendor:** `Active Directory`.
   - **Username LDAP attribute:** `sAMAccountName`.
   - **Connection URL:** `ldaps://ad.yourdomain.com:636`.
   - **Users DN:** `DC=yourdomain,DC=com`.
   - **Bind DN:** `CN=Administrator,CN=Users,DC=yourdomain,DC=com`.
   - **Bind Credential:** Password for the bind DN.
   - **Use Truststore SPI:** `ldaps_only`.

5. **Test Connection and Authentication:**

   - Click **Test connection**.
   - Click **Test authentication**.

6. **Save Configuration.**

### **3.4 Configure LDAP Mappers**

1. **Create or Verify Mappers:**

   - **sAMAccountName Mapper:**
     - Name: `username`.
     - LDAP Attribute: `sAMAccountName`.
     - User Model Attribute: `username`.
   - **Email Mapper:**
     - Name: `email`.
     - LDAP Attribute: `mail`.
     - User Model Attribute: `email`.

2. **Add Additional Mappers as Needed.**

---

## **Step 4: Configure Keycloak for X.509 Client Certificate Authentication**

### **4.1 Enable the X.509 Authentication Flow**

1. **Go to Authentication Flows:**

   - Click on **Authentication** in the left menu.

2. **Copy the Browser Flow:**

   - Find the **Browser** flow.
   - Click on **Actions** > **Copy**.
   - Name it `browser-x509`.

3. **Edit the `browser-x509` Flow:**

   - Click on the **browser-x509** flow.
   - For the **Authentication Type**, ensure the flow is set to **Generic**.

4. **Add X509/Validate Username Form Execution:**

   - Click **Add execution**.
   - Select **X509/Validate Username Form**.
   - Click **Add**.

5. **Set Execution Requirements:**

   - For **X509/Validate Username Form**, click on **Actions** > **Config**.
   - Set **Requirement** to `Alternative`.

6. **Adjust Other Executions:**

   - If you wish to disable username/password login, set **Username Password Form** to `Disabled`.
   - If you want to allow both methods, leave it as `Alternative`.

7. **Set the Browser Flow Binding:**

   - Go to **Authentication** > **Bindings**.
   - Set **Browser Flow** to `browser-x509`.

### **4.2 Configure the X.509 Authenticator**

1. **Configure X509/Validate Username Form:**

   - Go back to **Authentication** > **Flows** > **browser-x509**.
   - Click on **Actions** next to **X509/Validate Username Form** > **Config**.

2. **Set Authenticator Configuration:**

   - **Mapping Source Selection:**
     - **User Identity Source**: `Subject's Common Name`.
     - **Alternative User Identity Source**: `Subject's Email`.
   - **Certificate Policies:**
     - **CRL Checking**: Configure as per your requirements.
     - **OCSP Checking**: Enable if required.

3. **Save Configuration.**

---

## **Step 5: Configure HTTPS and Client Certificate Request**

### **5.1 Generate Server SSL Certificate**

1. **Create a Keystore:**

   ```bash
   keytool -genkeypair -alias keycloak -keyalg RSA -keystore /opt/keycloak/keystore.jks -keysize 2048 -validity 3650 -storepass password -keypass password -dname "CN=keycloak.yourdomain.com, OU=IT, O=Your Company, L=City, ST=State, C=US"
   ```

2. **Export Certificate Signing Request (CSR):**

   ```bash
   keytool -certreq -alias keycloak -file keycloak.csr -keystore /opt/keycloak/keystore.jks -storepass password
   ```

3. **Sign the CSR with Your CA:**

   On your CA server, sign the CSR and obtain the signed certificate (`keycloak.crt`).

4. **Import CA and Signed Certificate into Keystore:**

   ```bash
   keytool -import -trustcacerts -alias root -file ca_cert.cer -keystore /opt/keycloak/keystore.jks -storepass password
   keytool -import -alias keycloak -file keycloak.crt -keystore /opt/keycloak/keystore.jks -storepass password
   ```

### **5.2 Configure Keycloak HTTPS Listener**

1. **Edit `standalone.xml` or `standalone-ha.xml`:**

   ```bash
   nano /opt/keycloak/standalone/configuration/standalone.xml
   ```

2. **Add HTTPS Listener:**

   Find the `<subsystem xmlns="urn:jboss:domain:undertow:..."` section.

   ```xml
   <https-listener name="https" socket-binding="https" security-realm="UndertowRealm">
       <ssl verify-client="REQUESTED"/>
   </https-listener>
   ```

   - **verify-client:** Set to `REQUESTED` to request client certificates.

3. **Configure Security Realm:**

   Add or modify the `<security-realms>` section:

   ```xml
   <security-realms>
       <security-realm name="UndertowRealm">
           <server-identities>
               <ssl>
                   <keystore path="keystore.jks" relative-to="jboss.server.config.dir" keystore-password="password" alias="keycloak"/>
               </ssl>
           </server-identities>
           <authentication>
               <truststore path="truststore.jks" relative-to="jboss.server.config.dir" keystore-password="password"/>
           </authentication>
       </security-realms>
   </security-realms>
   ```

### **5.3 Create Truststore with Client CA Certificates**

1. **Create Truststore:**

   ```bash
   keytool -import -alias client_ca -file ca_cert.cer -keystore /opt/keycloak/truststore.jks -storepass password -noprompt
   ```

### **5.4 Update Socket Binding**

Ensure that the `https` socket binding is configured:

```xml
<socket-binding name="https" port="8443"/>
```

### **5.5 Open Ports in Firewall**

```bash
sudo firewall-cmd --permanent --add-port=8443/tcp
sudo firewall-cmd --reload
```

### **5.6 Restart Keycloak**

```bash
sudo systemctl restart keycloak
```

---

## **Step 6: Configure Browsers and Clients for Smart Card Authentication**

### **6.1 Install Smart Card Middleware on Clients**

- **Windows Clients:**
  - Install **ActivClient** or ensure Windows native smart card services are running.
- **Linux Clients:**
  - Install **OpenSC** and **pcsc-lite**.

  ```bash
  sudo apt-get install opensc pcscd
  sudo systemctl start pcscd
  sudo systemctl enable pcscd
  ```

### **6.2 Configure Browsers**

#### **6.2.1 Mozilla Firefox**

1. **Load PKCS#11 Module:**

   - Go to **Options** > **Privacy & Security** > **Certificates** > **Security Devices**.
   - Click **Load**.
   - Enter Module Name: `Smart Card`.
   - Module filename:
     - **Windows:** `C:\Windows\System32\acpkcs211.dll` (for ActivClient) or `C:\Windows\System32\aetpkss11.dll`.
     - **Linux:** `/usr/lib/x86_64-linux-gnu/opensc-pkcs11.so`.

2. **Verify Certificates:**

   - Go to **View Certificates** > **Your Certificates**.
   - You should see certificates from your smart card.

#### **6.2.2 Google Chrome and Microsoft Edge (Windows)**

- These browsers use the Windows Certificate Store.
- Ensure smart card certificates are available in **Certmgr.msc** under **Personal** > **Certificates**.

#### **6.2.3 Safari (Mac)**

- Smart card support is built-in.
- Ensure smart card certificates appear in **Keychain Access**.

---

## **Step 7: Map Smart Card Certificates to AD Users**

### **7.1 Publish User Certificates in AD**

1. **Obtain User's Smart Card Certificate:**

   - On a client machine with the smart card inserted, export the user's certificate without the private key.

2. **Import Certificate into AD User Account:**

   - Open **Active Directory Users and Computers**.
   - Enable **Advanced Features** under **View**.
   - Find the user account.
   - Go to **Properties** > **Published Certificates**.
   - Click **Add** and import the user's certificate.

### **7.2 Set `altSecurityIdentities` Attribute**

1. **Edit User Properties:**

   - In **Active Directory Users and Computers**, right-click the user > **Properties** > **Attribute Editor**.

2. **Set `altSecurityIdentities`:**

   - For mapping via **Subject**:

     ```
     X509:<I>CN=YourCA,DC=yourdomain,DC=com<S>CN=User Name,OU=Department,DC=yourdomain,DC=com
     ```

   - For mapping via **UPN**:

     ```
     X509:<UPN>username@yourdomain.com
     ```

   - Adjust the values according to your environment.

---

## **Step 8: Test the Configuration**

### **8.1 Access Keycloak Login Page**

- Navigate to `https://keycloak.yourdomain.com:8443/auth/realms/myrealm/account/`.

### **8.2 Certificate Selection**

- The browser should prompt you to select a client certificate.
- Choose the certificate from your smart card.

### **8.3 Authentication Process**

- Keycloak should authenticate you using the smart card certificate.
- You should be logged into the account management page.

---

## **Step 9: Troubleshooting**

### **9.1 Check Keycloak Logs**

- Logs are located at `/opt/keycloak/standalone/log/server.log`.

```bash
tail -f /opt/keycloak/standalone/log/server.log
```

- Look for errors related to SSL, client certificates, or authentication failures.

### **9.2 Verify Certificate Trust**

- Ensure that the CA certificates are correctly imported into the truststore.

### **9.3 Test LDAPS Connection**

- Use `ldapsearch` to test the LDAPS connection:

  ```bash
  ldapsearch -H ldaps://ad.yourdomain.com -b "DC=yourdomain,DC=com" -D "CN=Administrator,CN=Users,DC=yourdomain,DC=com" -W
  ```

### **9.4 Browser Issues**

- If the browser does not prompt for a certificate, check:

  - The browser's configuration for client certificates.
  - That the server is requesting client certificates (verify-client setting).
  - That the smart card middleware is correctly installed.

### **9.5 SSL Handshake Errors**

- Use `openssl` to debug SSL handshake:

  ```bash
  openssl s_client -connect keycloak.yourdomain.com:8443 -showcerts -state -debug
  ```

---

## **Step 10: Security Considerations**

- **Enforce Client Certificate Verification:**

  - Set `verify-client` to `REQUIRED` in Keycloak's HTTPS listener to enforce smart card authentication.

- **Certificate Revocation Checking:**

  - Configure CRL or OCSP in the X.509 authenticator settings in Keycloak.

- **Secure Keycloak Deployment:**

  - Use a reverse proxy (e.g., Apache, Nginx) if needed.
  - Ensure that only HTTPS is used.
  - Keep Keycloak and all components up to date.

---

## **References**

- **Keycloak Documentation:**
  - [Securing Applications and Services Guide](https://www.keycloak.org/docs/latest/securing_apps/)
  - [Server Administration Guide - LDAP User Federation](https://www.keycloak.org/docs/latest/server_admin/#ldap-user-federation)
  - [Server Administration Guide - X.509 Authentication](https://www.keycloak.org/docs/latest/server_admin/#_x509)

- **Active Directory LDAPS Configuration:**
  - [How to enable LDAP over SSL with a third-party certification authority](https://support.microsoft.com/en-us/help/321051/how-to-enable-ldap-over-ssl-with-a-third-party-certification-authority)

- **Smart Card Middleware:**
  - [OpenSC Project](https://github.com/OpenSC/OpenSC/wiki)

- **Java Keytool Documentation:**
  - [keytool - Key and Certificate Management Tool](https://docs.oracle.com/javase/8/docs/technotes/tools/unix/keytool.html)

