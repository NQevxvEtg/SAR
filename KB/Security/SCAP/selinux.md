### Example: Configuring SELinux for a Custom Web Application

#### 1. Preparation and Installation
1. **Ensure SELinux is enabled**: First, verify that SELinux is in enforcing mode.
   ```bash
   sudo sestatus
   ```
   Output should show `Current mode: enforcing`. If it's in `permissive` mode, enable enforcing mode by editing the SELinux config file:
   ```bash
   sudo nano /etc/selinux/config
   ```
   Set `SELINUX=enforcing`, save the file, and reboot the system.

2. **Install an HTTP Server (Apache)**:
   ```bash
   sudo yum install httpd -y
   sudo systemctl start httpd
   sudo systemctl enable httpd
   ```

#### 2. Setting up the Web Application Directory
Let’s assume the application files are located in a custom directory, `/webapp`.

1. **Create a Directory** for the web application and set appropriate permissions:
   ```bash
   sudo mkdir /webapp
   sudo chown -R apache:apache /webapp
   ```

2. **Set up a simple test file** in the `/webapp` directory:
   ```bash
   echo "<h1>SELinux Test Page</h1>" | sudo tee /webapp/index.html
   ```

#### 3. Configuring SELinux Contexts
By default, SELinux may block access to this new directory. To allow Apache to read files from `/webapp`, we need to set the correct SELinux context.

1. **List the Current Context**:
   ```bash
   ls -Z /webapp
   ```

2. **Set the Apache Context** (`httpd_sys_content_t`) on the `/webapp` directory:
   ```bash
   sudo semanage fcontext -a -t httpd_sys_content_t "/webapp(/.*)?"
   sudo restorecon -Rv /webapp
   ```
   This command applies the `httpd_sys_content_t` context, which allows Apache to serve files from `/webapp`.

#### 4. Adjusting SELinux Policies
If your application requires Apache to write to a directory (such as uploading files), additional permissions are necessary.

1. **Enable Write Access** for Apache:
   ```bash
   sudo semanage fcontext -a -t httpd_sys_rw_content_t "/webapp(/.*)?"
   sudo restorecon -Rv /webapp
   ```

2. **Allow HTTPD Network Access** if the application needs to connect to the network:
   ```bash
   sudo setsebool -P httpd_can_network_connect 1
   ```

#### 5. Troubleshooting and Verification
If the application still fails to serve the files, check for SELinux denials.

1. **Check SELinux Logs** for Denials:
   ```bash
   sudo ausearch -m avc -ts recent
   ```

2. **Generate Suggested Policy** (if needed):
   ```bash
   sudo audit2allow -a
   ```
   Review any suggested rules carefully before implementing them, as they can potentially open unnecessary permissions.

3. **Verify SELinux Configuration**:
   After applying policies, confirm access by visiting the server's IP address and checking if `index.html` loads as expected.

