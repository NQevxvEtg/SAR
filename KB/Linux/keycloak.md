### Step 1: Install Keycloak (No Docker)

1. **Download Keycloak**:
   
   Download the latest Keycloak version from the [official site](https://www.keycloak.org/downloads). After downloading, unzip the file.

2. **Set up Keycloak**:
   
   Navigate to the Keycloak directory and run the following command to start Keycloak:

   ```bash
   ./bin/kc.sh start-dev
   ```

   The admin console should now be available at `http://localhost:8080`.

3. **Create an Admin User**:

   If not already done, create an admin user:

   ```bash
   ./bin/kc.sh create-admin --user admin --password admin
   ```

4. **Access the Admin Console**:
   
   Open a browser and visit `http://localhost:8080/admin`. Log in with the admin username and password.

---

### Step 2: Configure LDAP Integration for Active Directory

1. **Log in to the Keycloak Admin Console**:

   Go to the admin console (`http://localhost:8080/admin`) and log in using the admin credentials.

2. **Add LDAP as User Federation**:

   In the Keycloak admin console:
   - Navigate to **User Federation** in the left menu.
   - Click **Add provider** and choose **LDAP**.

3. **Configure LDAP for AD**:

   In the LDAP configuration, set the following values based on your AD environment:

   - **Edit Mode**: `READ_ONLY` or `WRITABLE` (depending on whether you want to allow Keycloak to modify users in AD).
   - **Vendor**: `Active Directory`
   - **Connection URL**: `ldap://<AD_SERVER_IP>:389` (change to `ldaps://` and port 636 if using SSL)
   - **Bind DN**: `CN=your_bind_user,OU=Users,DC=example,DC=com` (this is the user Keycloak will use to connect to AD)
   - **Bind Credentials**: The password for the bind user.
   - **Users DN**: `OU=Users,DC=example,DC=com` (the base DN where your users are located in AD).
   - **Authentication**: Set this to **simple**.
   - **Search Scope**: `One Level`.

4. **Test the Connection**:

   After entering the connection details, click **Test Connection** to verify Keycloak can connect to your AD.

5. **Synchronize Users**:

   Once you have verified the connection, scroll down to the **User Federation** settings and click **Synchronize all users**. This action will import all users from AD into Keycloak.

---

### Step 3: Create a Keycloak Realm and Client for STIG Manager

1. **Create a Realm**:

   In the Keycloak admin console:
   - Navigate to **Realm Settings**.
   - Click **Add Realm** and create a new realm (e.g., `stigman`).

2. **Create a Client for STIG Manager**:

   Inside the newly created realm:
   - Go to **Clients**.
   - Click **Create** and configure a new client:
     - **Client ID**: `stig-manager`
     - **Client Protocol**: `openid-connect`
     - **Root URL**: The URL of your STIG Manager installation.
     - Set **Access Type** to **confidential**.

   - After saving, go to **Credentials** for the client and note the **client secret**.

---

### Step 4: Configure Roles and Mappings for AD Users

1. **Create Roles in Keycloak**:
   - Navigate to **Roles** in the realm.
   - Add roles such as `user` and `admin`.

2. **Map AD Roles to Keycloak**:
   - Navigate to **User Federation** > **LDAP Mappers**.
   - Create mappers for roles and groups so AD groups can be mapped to Keycloak roles.

   For example, you can map the AD group `AdminGroup` to the Keycloak `admin` role.

---

### Step 5: STIG Manager Configuration

1. **Set Environment Variables**:

   On the server where STIG Manager is hosted, set the following environment variables:

   ```bash
   export STIGMAN_OIDC_PROVIDER="https://<keycloak-server>/auth/realms/stigman"
   export STIGMAN_OIDC_CLIENT_ID="stig-manager"
   export STIGMAN_OIDC_CLIENT_SECRET="<client-secret-from-keycloak>"
   ```

2. **Configure Token Claims**:

   Ensure that the token claims from Keycloak match the expected format for STIG Manager. Typically, the username claim should be `preferred_username`.

---

### Step 6: Testing and Validation

1. **Log in to STIG Manager**:
   
   Navigate to the STIG Manager login page and try logging in with your AD credentials. Keycloak should handle the authentication, and if all settings are correct, the user should be successfully authenticated.

2. **Check Role Assignments**:

   Verify that users are assigned the correct roles based on their AD groups.

