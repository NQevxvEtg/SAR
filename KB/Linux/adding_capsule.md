Step 1: Prepare the Capsule Server in Domain2

1. Install the Capsule Packages: Ensure the server in domain2 is ready to act as a Capsule by installing the necessary packages.

sudo yum install satellite-capsule -y


2. Register the Capsule Server: Register the Capsule server with the Satellite server in domain1 using activation keys (or register manually if keys are unavailable).

sudo subscription-manager register --org="YOUR_ORG_NAME" --activationkey="YOUR_ACTIVATION_KEY"
sudo subscription-manager attach --pool="POOL_ID"


3. Enable the Capsule Repositories: Enable repositories for Red Hat Satellite Capsule and dependencies.

sudo subscription-manager repos --enable=rhel-7-server-satellite-capsule-6.11-rpms
sudo subscription-manager repos --enable=rhel-7-server-satellite-tools-6.11-rpms


4. Install Capsule and Dependencies: Update the system and install Capsule along with its dependencies.

sudo yum update -y
sudo yum install satellite-capsule -y




---

Step 2: Configure and Initialize the Capsule

1. Set up the Capsule Configuration: Run the following command to configure the Capsule, ensuring it can securely communicate with the Satellite server.

sudo capsule-installer --parent-fqdn "satellite.domain1.com" --register-in-foreman "true" --foreman-oauth-key "OAUTH_KEY" --foreman-oauth-secret "OAUTH_SECRET"

Replace "satellite.domain1.com" with your Satellite server's FQDN and add the correct OAuth credentials (which can be retrieved from the Satellite web UI under Administer > Settings > Authentication).


2. SSL Certificate Configuration: To establish a secure connection, copy the SSL certificates from the Satellite server to the Capsule server. Ensure the SSL files are in the correct location, typically in /etc/foreman-proxy/settings.d/.

sudo cp /path/to/satellite_cert.pem /etc/foreman-proxy/settings.d/


3. Start the Capsule Services: After configuration, start the Capsule services to initialize the connection to the Satellite server.

sudo systemctl enable --now foreman-proxy
sudo systemctl enable --now pulp




---

Step 3: Sync Content from Satellite to Capsule

1. Log in to the Satellite Web UI (on the Satellite in domain1) and navigate to Infrastructure > Capsules.


2. Add the Capsule: Choose "Add Capsule" and provide the Capsule FQDN (capsule.domain2.com).


3. Enable Content Sync: Set up content synchronization by navigating to Content > Sync Status and selecting repositories to sync to the Capsule.


4. Initiate Sync:

hammer capsule content synchronize --id YOUR_CAPSULE_ID


5. Verify Synchronization: You can verify that content sync is working by checking the Capsule sync status.

hammer capsule content status --id YOUR_CAPSULE_ID




---

Step 4: Register and Manage Domain2 Servers on Capsule

1. Set Up Activation Key for Domain2 Clients: In the Satellite Web UI, navigate to Content > Activation Keys and create an activation key for domain2 clients. Make sure it points to the domain2 Capsule and desired content views.


2. Register Clients with the Capsule: On each client machine in domain2, register with the Capsule server, substituting with the Capsule FQDN and activation key for domain2.

sudo subscription-manager register --org="YOUR_ORG_NAME" --activationkey="ACTIVATION_KEY_FOR_DOMAIN2"


3. Configure the Client to Use the Capsule for Content: Set the baseurl to point to the Capsule server for package updates.

sudo subscription-manager config --server.hostname=capsule.domain2.com


4. Verify Client Connection: Run the following command on each client to confirm connectivity and content availability from the Capsule server.

sudo subscription-manager repos --list


5. Automate Configuration (Optional): To simplify adding more machines, you could use Red Hat Satellite provisioning templates or Ansible playbooks that point to the Capsule server.




---

Step 5: Monitor and Manage Capsule and Domain2 Clients

1. Check Capsule Status: You can verify that the Capsule is operational and syncs properly from the Satellite Web UI or CLI.

hammer capsule list


2. Monitor Clients from Satellite: Satellite will display clients connected to the Capsule under Hosts > All Hosts, allowing you to manage policies, configurations, and updates centrally.


3. Sync Regularly: Schedule regular syncs from the Satellite server to ensure that the Capsule has up-to-date content.

hammer repository synchronize --organization="YOUR_ORG_NAME" --name="YOUR_REPOSITORY"




