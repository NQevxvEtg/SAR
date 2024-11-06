To install and configure Red Hat Satellite 6.12

### Pre-Installation Setup

1. **Create and Configure RHEL VM:**
   - Create a VM on vSphere with RHEL 8.7, assigning 4 vCPUs, 20GB RAM, and 400GB storage.
   - Ensure network access for installation and verify hostname resolution.

2. **Set Hostname and Time Sync:**
   - Set the hostname:
     ```bash
     sudo hostnamectl set-hostname sat01.example.com
     ```
   - Verify time synchronization:
     ```bash
     chronyc sources -v
     ```

3. **Register with Red Hat Subscription:**
   - Register the system:
     ```bash
     sudo subscription-manager register --org=<org_id> --activationkey=<activation_key>
     ```

### Repository Configuration

1. **Enable Repositories:**
   - Disable all repos:
     ```bash
     sudo subscription-manager repos --disable "*"
     ```
   - Enable required repositories:
     ```bash
     sudo subscription-manager repos --enable=rhel-8-for-x86_64-baseos-rpms \
     --enable=rhel-8-for-x86_64-appstream-rpms \
     --enable=satellite-6.12-for-rhel-8-x86_64-rpms \
     --enable=satellite-maintenance-6.12-for-rhel-8-x86_64-rpms
     ```
   - Verify:
     ```bash
     sudo subscription-manager repos --list-enabled
     ```

2. **Enable Satellite Module and Update System:**
   ```bash
   sudo dnf module enable satellite:el8
   sudo dnf update
   ```

3. **Install Essential Packages:**
   ```bash
   sudo dnf install sos
   ```

### Satellite Installation

1. **Install Satellite Server:**
   ```bash
   sudo dnf install satellite
   ```

2. **Run Initial Configuration:**
   ```bash
   sudo satellite-installer --scenario satellite \
   --foreman-initial-organization "<org_name>" \
   --foreman-initial-location "<location_name>"
   ```

3. **Access Satellite Web UI:**
   - Access via `https://<satellite_server_hostname>`.
   - Log in with the credentials configured during setup.

### Post-Installation Configuration


**1. Sync Repositories**

Synchronizing repositories ensures that your Satellite server has the latest content for deployment and updates.

- **Access the Satellite Web UI:**
  - Navigate to `https://<satellite_server_fqdn>/` in your web browser.
  - Log in with your administrative credentials.

- **Enable Red Hat Repositories:**
  - Go to **Content** > **Red Hat Repositories**.
  - Select the repositories relevant to your environment (e.g., RHEL 8 for x86_64 BaseOS, AppStream).
  - Click **Enable** for each chosen repository.

- **Create a Sync Plan:**
  - Navigate to **Content** > **Sync Plans**.
  - Click **Create Sync Plan**.
  - Provide a **Name**, **Interval** (e.g., daily, weekly), and **Start Date/Time**.
  - Click **Save**.

- **Associate Repositories with the Sync Plan:**
  - Go to **Content** > **Red Hat Repositories**.
  - Select the desired repositories.
  - Click **Select Action** > **Manage Sync Plans**.
  - Choose the previously created sync plan and click **Update**.

- **Manually Sync Repositories (if needed):**
  - Navigate to **Content** > **Sync Status**.
  - Click **Select All** and then **Sync Now** to initiate synchronization.

**2. Add Host Groups and Provisioning Templates**

Host Groups and Provisioning Templates streamline the deployment of RHEL systems by standardizing configurations.

- **Create a Host Group:**
  - In the Satellite Web UI, go to **Configure** > **Host Groups**.
  - Click **Create Host Group**.
  - Fill in the following fields:
    - **Name:** Descriptive name for the host group.
    - **Lifecycle Environment:** Select the appropriate environment (e.g., Library, Development).
    - **Content View:** Choose the relevant content view.
    - **Content Source:** Select the Satellite or Capsule server.
    - **Puppet Environment:** If using Puppet, select the environment.
    - **Puppet Classes:** Assign any necessary Puppet classes.
  - Click **Save**.

- **Define Provisioning Templates:**
  - Navigate to **Hosts** > **Provisioning Templates**.
  - Click **Create Template**.
  - Provide a **Name** and select the **Type** (e.g., Kickstart, Preseed).
  - Enter the template content, utilizing ERB syntax for dynamic content.
  - Click **Save**.

- **Associate Templates with Operating Systems:**
  - Go to **Hosts** > **Operating Systems**.
  - Select the desired operating system.
  - Click the **Templates** tab.
  - Assign the appropriate provisioning templates (e.g., Kickstart, Finish).
  - Click **Save**.

**3. Enable Capsule Servers (Optional)**

Capsule Servers enhance scalability by distributing content and services across different locations.

- **Install Capsule Server:**
  - On the designated Capsule server, register the system:
    ```bash
    sudo subscription-manager register --org="<organization>" --activationkey="<activation_key>"
    ```
  - Enable necessary repositories:
    ```bash
    sudo subscription-manager repos \
      --enable=rhel-8-for-x86_64-baseos-rpms \
      --enable=rhel-8-for-x86_64-appstream-rpms \
      --enable=satellite-capsule-6.15-for-rhel-8-x86_64-rpms
    ```
  - Install the Capsule software:
    ```bash
    sudo dnf install satellite-capsule
    ```

- **Generate and Transfer Certificates:**
  - On the Satellite server, generate certificates:
    ```bash
    sudo capsule-certs-generate \
      --foreman-proxy-fqdn "<capsule_fqdn>" \
      --certs-tar "/root/<capsule_fqdn>-certs.tar"
    ```
  - Transfer the tar file to the Capsule server:
    ```bash
    scp /root/<capsule_fqdn>-certs.tar root@<capsule_fqdn>:/root/
    ```

- **Configure the Capsule Server:**
  - On the Capsule server, run the installer:
    ```bash
    sudo satellite-installer --scenario capsule \
      --foreman-proxy-content-parent-fqdn "<satellite_fqdn>" \
      --foreman-proxy-register-in-foreman "true" \
      --foreman-proxy-foreman-base-url "https://<satellite_fqdn>" \
      --foreman-proxy-trusted-hosts "<satellite_fqdn>" \
      --foreman-proxy-trusted-hosts "<capsule_fqdn>" \
      --foreman-proxy-oauth-consumer-key "<oauth_key>" \
      --foreman-proxy-oauth-consumer-secret "<oauth_secret>" \
      --certs-tar-file "/root/<capsule_fqdn>-certs.tar"
    ```

- **Verify Capsule Registration:**
  - On the Satellite server, confirm the Capsule is registered:
    ```bash
    hammer proxy list
    ```
  - Ensure the Capsule appears in the list and is active.

