### 1. **Inspecting Certificates**

To understand the details and validity of a certificate, it’s often necessary to inspect its metadata.

- **Print CA Certificates**:
  ```bash
  awk -v cmd='openssl x509 -noout -subject' '/BEGIN/{close(cmd)};{print | cmd}' < /etc/ssl/certs/ca-certificates.crt
  ```

- **Detailed Certificate Inspection**:
  - PEM format:
    ```bash
    openssl x509 -inform pem -noout -text -in cert.pem
    ```
  - DER format:
    ```bash
    openssl x509 -inform der -noout -text -in cert.crt
    ```
  - **Explanation**: The `-noout -text` options print certificate details like issuer, subject, validity, and extensions without displaying the actual encoded certificate data.

---

### 2. **Converting Between PEM and DER Formats**

Certificates come in PEM (Base64) and DER (binary) formats, and conversion may be necessary for compatibility with different applications.

- **Convert PEM to DER**:
  ```bash
  openssl x509 -outform der -in CERTIFICATE.pem -out CERTIFICATE.crt
  ```
- **Convert DER to PEM**:
  ```bash
  openssl x509 -inform der -in CERTIFICATE.crt -out CERTIFICATE.pem
  ```

  - **Explanation**: PEM format certificates are ASCII-encoded and begin with `-----BEGIN CERTIFICATE-----`, while DER format certificates are binary. Many web servers prefer PEM, whereas some embedded systems and Java environments use DER.

---

### 3. **Creating a Self-Signed Certificate**

Self-signed certificates are often used for development and testing purposes.

```bash
openssl req -new -x509 -days 365 -key private.key -out selfsigned.crt
```

- **Explanation**: This command creates a self-signed certificate valid for 365 days. You’ll need an existing private key (`private.key`) to sign the certificate.

---

### 4. **Signing a Certificate Signing Request (CSR) with a Certificate Authority (CA)**

If you’re managing a CA and need to sign a CSR, use this method.

1. **Generate a CSR**:
   ```bash
   openssl req -new -key private.key -out request.csr
   ```

2. **Sign the CSR with a CA Certificate and Key**:
   ```bash
   openssl x509 -req -in request.csr -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out signed-cert.crt -days 365
   ```

- **Explanation**: The CA uses its certificate (`ca-cert.pem`) and key (`ca-key.pem`) to sign `request.csr`, generating `signed-cert.crt`. This allows clients that trust the CA to trust the new certificate.

---

### 5. **Adding a New Certificate to the System CA Store**

To add a new certificate to the system CA store for broader system trust:

1. **Copy the Certificate to the Trusted CA Directory**:
   ```bash
   sudo cp CERTIFICATE.crt /usr/local/share/ca-certificates/
   ```

2. **Update the CA Store**:
   ```bash
   sudo update-ca-certificates
   ```

- **Explanation**: This command will hash the certificate and add it to the system’s CA bundle, allowing it to be trusted by applications that rely on the system CA store.

---

### 6. **Exporting and Importing Certificates**

Some applications or environments require certificates in PKCS#12 (`.pfx`) format, which includes both the certificate and private key.

- **Convert PEM to PKCS#12 (PFX)**:
  ```bash
  openssl pkcs12 -export -out certificate.pfx -inkey private.key -in cert.pem -certfile ca-cert.pem
  ```

- **Explanation**: This exports a PKCS#12 file (`certificate.pfx`) containing the certificate, CA chain, and private key, which is useful for applications that need both components in a single file.

---

### 7. **Verify Certificate Chains**

To verify that a certificate chain is correct and complete:

```bash
openssl verify -CAfile ca-cert.pem cert.pem
```

- **Explanation**: This checks that `cert.pem` was signed by the CA certificate in `ca-cert.pem`. If successful, this command outputs `cert.pem: OK`.

---

### 8. **Examining Expiry Dates for All Certificates in a Bundle**

To list the expiration dates of all certificates in a CA bundle, you can use the following command:

```bash
awk -v cmd='openssl x509 -noout -enddate' '/BEGIN/{close(cmd)};{print | cmd}' < /etc/ssl/certs/ca-certificates.crt
```

- **Explanation**: This command outputs the expiry dates of each certificate in the bundle, helping you identify any certificates nearing expiration.

---

### 9. **Extracting Certificates from a PEM Bundle**

If you have a bundle of certificates in one file, you may want to extract each certificate individually.

```bash
awk 'BEGIN {c=0} /BEGIN CERTIFICATE/ {c++} { print > "cert" c ".pem" }' < bundle.pem
```

- **Explanation**: This command splits each certificate in the bundle into individual files (`cert1.pem`, `cert2.pem`, etc.).

---

### 10. **Automated Renewal and Installation of Certificates Using Certbot (for Let’s Encrypt)**

If using Let’s Encrypt certificates, `certbot` automates renewal and installation:

1. **Install Certbot**:
   ```bash
   sudo yum install -y certbot
   ```

2. **Obtain and Install a Certificate**:
   ```bash
   sudo certbot certonly --webroot -w /var/www/html -d yourdomain.com
   ```

3. **Automate Renewal**:
   - Certbot automatically schedules renewals, but you can verify this with:
     ```bash
     sudo certbot renew --dry-run
     ```

- **Explanation**: Certbot uses the `--webroot` method to verify domain ownership, placing a temporary file in `/var/www/html`. Certificates are stored in `/etc/letsencrypt/live/yourdomain.com/`, and Certbot handles renewals automatically.

---

### 11. **Encrypting Certificates with a Password**

If you want to protect a private key with a passphrase:

1. **Generate a Private Key with a Passphrase**:
   ```bash
   openssl genpkey -aes256 -out encrypted.key -algorithm RSA
   ```

2. **Convert an Existing Key to a Password-Protected Key**:
   ```bash
   openssl rsa -aes256 -in unencrypted.key -out encrypted.key
   ```

- **Explanation**: AES-256 encryption secures the private key, requiring a passphrase each time it’s used, which is valuable for sensitive environments.

---

### 12. **Removing a Passphrase from a Private Key**

If you have a password-protected key and want to remove the passphrase:

```bash
openssl rsa -in encrypted.key -out unencrypted.key
```

- **Explanation**: This command removes the passphrase, creating an unencrypted version of the private key, which may be necessary for automated processes that don’t support passphrase prompts.

