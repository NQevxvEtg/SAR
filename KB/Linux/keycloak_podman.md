### Step 1: Install Podman on Red Hat

1. **Update your system packages**:
   ```bash
   sudo yum update
   ```

2. **Install Podman**:
   ```bash
   sudo yum install -y podman
   ```

3. **Verify installation**:
   ```bash
   podman --version
   ```

---

### Step 2: Pull the Keycloak Image

1. **Pull the Keycloak image** from the Quay.io container registry:
   ```bash
   podman pull quay.io/keycloak/keycloak:latest
   ```

---

### Step 3: Run Keycloak with Podman

1. **Run Keycloak** as a standalone instance:
   ```bash
   podman run --name keycloak -p 8080:8080 -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=admin quay.io/keycloak/keycloak:latest start-dev
   ```

   This will:
   - Expose Keycloak on port 8080.
   - Set the admin user to `admin` with the password `admin`.

2. **Verify Keycloak is running**:
   Open your browser and go to `http://localhost:8080`. You should see the Keycloak login screen.

---

### Step 4: Run Keycloak with Persistent Data (Optional)

If you want your data to persist between container restarts, you can mount a volume:

1. **Create a directory** for Keycloak data on your host:
   ```bash
   mkdir -p /var/lib/keycloak/data
   ```

2. **Run Keycloak with the volume**:
   ```bash
   podman run --name keycloak -p 8080:8080 -v /var/lib/keycloak/data:/opt/keycloak/data -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=admin quay.io/keycloak/keycloak:latest start-dev
   ```

---

### Step 5: Running Keycloak with HTTPS (Optional)

If you want to run Keycloak over HTTPS, you'll need to provide a certificate and configure it:

1. **Generate a self-signed certificate**:
   ```bash
   openssl req -new -x509 -keyout key.pem -out cert.pem -days 365 -nodes
   ```

2. **Run Keycloak with the certificate**:
   ```bash
   podman run --name keycloak -p 8443:8443 -v /path/to/cert.pem:/etc/x509/https/tls.crt:Z -v /path/to/key.pem:/etc/x509/https/tls.key:Z -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=admin quay.io/keycloak/keycloak:latest start --https-certificate-file=/etc/x509/https/tls.crt --https-certificate-key-file=/etc/x509/https/tls.key
   ```

   Now, Keycloak will be accessible on `https://localhost:8443`.

---

### Step 6: Managing Keycloak with Podman

1. **Start Keycloak**:
   ```bash
   podman start keycloak
   ```

2. **Stop Keycloak**:
   ```bash
   podman stop keycloak
   ```

3. **Remove Keycloak**:
   ```bash
   podman rm keycloak
   ```

---

### Step 7: Using Podman-Compose (Optional)

If you need to run Keycloak along with other services (e.g., a database), you can use **podman-compose**.

1. **Install Podman-Compose**:
   ```bash
   sudo pip3 install podman-compose
   ```

2. **Create a `docker-compose.yml`** file:
   ```yaml
   version: '3'
   services:
     keycloak:
       image: quay.io/keycloak/keycloak:latest
       environment:
         - KEYCLOAK_ADMIN=admin
         - KEYCLOAK_ADMIN_PASSWORD=admin
       ports:
         - "8080:8080"
   ```

3. **Run the services**:
   ```bash
   podman-compose up
   ```
