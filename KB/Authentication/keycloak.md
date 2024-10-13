### **Step 1: Prepare the Environment (FIPS Compliance)**

1. **Install FIPS-Compliant Java and Cryptography Libraries**:
   - Ensure your Java runtime is FIPS-compliant. For Keycloak, this means using a FIPS 140-2 compliant version of OpenJDK and **BouncyCastle FIPS** as the cryptography provider.
   
   - **Download and configure** FIPS-compliant BouncyCastle provider:
     ```bash
     wget https://www.bouncycastle.org/download/bc-fips-1.0.2.jar
     wget https://www.bouncycastle.org/download/bctls-fips-1.0.10.jar
     ```

2. **Configure Java Security for FIPS Mode**:
   Edit your Java security file (`$JAVA_HOME/lib/security/java.security`) and update the security provider list to include the FIPS provider:
   ```bash
   security.provider.1=org.bouncycastle.jcajce.provider.BouncyCastleFipsProvider
   security.provider.2=sun.security.provider.Sun
   ```
   
   - Ensure the Java Virtual Machine (JVM) enforces FIPS mode by adding the following flags:
     ```bash
     -Djava.security.properties=/path/to/java.security
     ```

   - Restart Keycloak to apply FIPS mode.

### **Step 2: Install and Configure Keycloak with FIPS Mode**

1. **Deploy Keycloak**:
   Download and run Keycloak using Docker. You can either pull the latest version or the FIPS-compliant version from Red Hat's container registry:
   ```bash
   docker pull quay.io/keycloak/keycloak:latest
   ```

2. **Configure Keycloak for STIG Manager**:
   - Navigate to the **Keycloak Admin Console** at `http://localhost:8080/admin`.
   - Create a new **realm** named `stigman`.
   - In **Realm Roles**, create the required roles: `user`, `create_collection`, and `admin`.

3. **Add Keycloak Client**:
   - In **Clients**, add a new client called `stig-manager`.
   - Enable the **Authorization Code Flow with PKCE** by selecting **Standard Flow Enabled**.
   - Set **Valid Redirect URIs** to match your STIG Manager URL, e.g., `http://localhost:54000/*`.
   - Configure **Web Origins** (either your domain or `*` for testing purposes).

4. **Add Scopes**:
   In **Client Scopes**, create the following scopes for STIG Manager:
   - `stig-manager:collection`
   - `stig-manager:stig:read`
   - `stig-manager:op:read`
   - Map these scopes to corresponding roles (`user` for `read` permissions, `admin` for operational scopes).

### **Step 3: Configure Persistent MySQL Database**

1. **Create Persistent Volume for MySQL**:
   To ensure your MySQL database data persists between container restarts, create a persistent volume:
   ```bash
   docker volume create stig-manager-mysql-data
   ```

2. **Set Up MySQL in Docker Compose**:
   Modify the `docker-compose.yml` file to add persistent storage for MySQL. Here is an updated version:
   ```yaml
   version: '3.7'

   services:
     auth:
       image: nuwcdivnpt/stig-manager-auth
       ports:
         - "8080:8080"

     db:
       image: mysql:8.0
       environment:
         - MYSQL_ROOT_PASSWORD=rootpw
         - MYSQL_USER=stigman
         - MYSQL_PASSWORD=stigman
         - MYSQL_DATABASE=stigman
       volumes:
         - stig-manager-mysql-data:/var/lib/mysql  # Persistent storage for database
       cap_add:
         - SYS_NICE  # Workaround for MySQL logging bug

     api:
       image: nuwcdivnpt/stig-manager:latest
       environment:
         - STIGMAN_OIDC_PROVIDER=http://auth:8080/realms/stigman
         - STIGMAN_DB_HOST=db
         - STIGMAN_DB_PASSWORD=stigman
       ports:
         - "54000:54000"

   volumes:
     stig-manager-mysql-data:  # Declare persistent volume for MySQL
   ```

### **Step 4: Deploy and Run STIG Manager with Persistent Database**

1. **Start the Services**:
   From the directory where your `docker-compose.yml` is located, run the following command to start Keycloak, MySQL (with persistent storage), and STIG Manager:
   ```bash
   docker-compose up -d
   ```

2. **Check Startup Logs**:
   Verify that all services start correctly by checking the logs:
   ```bash
   docker-compose logs -f
   ```

3. **Verify Database Persistence**:
   To ensure that MySQL data is persisted:
   - Stop the containers:
     ```bash
     docker-compose down
     ```
   - Start them again:
     ```bash
     docker-compose up -d
     ```
   - Verify that all users and configurations created in Keycloak and STIG Manager are still intact.

### **Step 5: Backup and Restore Persistent Database**

1. **Backup MySQL Data**:
   To create a backup of your persistent MySQL database:
   ```bash
   docker exec stig-manager-db mysqldump -u stigman -pstigman stigman > backup.sql
   ```

2. **Restore MySQL Data**:
   To restore the database from a backup:
   ```bash
   docker exec -i stig-manager-db mysql -u stigman -pstigman stigman < backup.sql
   ```

### **Step 6: Access STIG Manager**

1. **Login to STIG Manager**:
   Navigate to `http://localhost:54000` to access the STIG Manager interface.
   - Use the credentials created in Keycloak (e.g., admin/password for testing).

2. **Test FIPS and Persistence**:
   Ensure that your deployment is running in FIPS mode by checking Keycloak's logs for any cryptographic activity, and confirm the persistence of the database.

---

This approach ensures that your **Keycloak** is set up with **FIPS mode**, and the **MySQL database** remains persistent, even after container restarts. This setup is suitable for production environments that require compliance with FIPS 140-2 standards.

For additional information, please refer to:
- [STIG Manager Authentication Setup](https://stig-manager.readthedocs.io/en/latest/installation-and-setup/authentication.html)
- [Keycloak FIPS Setup](https://www.keycloak.org/server/fips)
