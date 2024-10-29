Creating a custom bootable ISO with Red Hat Satellite involves:

1. **Setting Up Kickstart Trees**: Defining a repository for the required OS packages.
2. **Configuring a Kickstart File**: Establishing the instructions for system provisioning.
3. **Creating an Activation Key**: Defining configurations and subscriptions.
4. **Deploying a Content View**: Publishing an organized collection of repositories and packages.
5. **Building the ISO Image**: Using `livemedia-creator` or other compatible tools with Satellite to bundle these configurations into a bootable image.

### Step-by-Step Guide

---

**1. Configure Red Hat Satellite Server and Enable Repositories**

1. First, ensure that your Red Hat Satellite server is properly set up and connected to the relevant Content Delivery Network (CDN) for Red Hat content.
2. Enable the necessary repositories to create a custom ISO. This includes base OS repositories and any additional repositories you need.

   ```bash
   satellite-installer --scenario satellite --foreman-initial-organization "YourOrg" --foreman-initial-location "Default Location"
   ```

   Run this command if you’re configuring your Red Hat Satellite server for the first time, where `"YourOrg"` represents your organization's name.

---

**2. Sync Repositories**

In the Satellite web UI:

1. Go to **Content > Products** and select your OS product.
2. Choose the base OS repositories you need and click **Sync Now** to download content.
3. Wait for synchronization to complete.

---

**3. Create a Content View**

Content Views allow you to define which repositories are included in the ISO. In Satellite:

1. Go to **Content > Content Views** and click **Create New View**.
2. Name the Content View (e.g., “RHEL8_Custom_ISO”) and add the repositories you synchronized earlier.
3. Publish the Content View.

   ```bash
   hammer content-view create --name "RHEL8_Custom_ISO" --organization "YourOrg"
   hammer content-view add-repository --name "RHEL8_Custom_ISO" --product "Red Hat Enterprise Linux" --repository "rhel-8-for-x86_64-appstream-rpms"
   hammer content-view publish --name "RHEL8_Custom_ISO" --organization "YourOrg"
   ```

   Ensure you use the appropriate repository name and product ID.

---

**4. Configure a Kickstart File**

A Kickstart file automates the OS installation.

1. Go to **Hosts > Provisioning Templates** and click **Create Template**.
2. Write your custom Kickstart script or use an existing template, adjusting parameters like partitioning, timezone, etc.

   Here's a minimal example of a Kickstart configuration:

   ```plaintext
   #version=RHEL8
   lang en_US.UTF-8
   keyboard us
   timezone America/New_York --utc
   rootpw --iscrypted <encrypted_password>
   reboot
   bootloader --location=mbr
   clearpart --all --initlabel
   part /boot --fstype="xfs" --size=500
   part pv.01 --size=1 --grow
   volgroup VolGroup --pesize=4096 pv.01
   logvol / --fstype="xfs" --name=lv_root --vgname=VolGroup --size=5120
   ```

3. Associate this Kickstart file with the Content View:

   ```bash
   hammer hostgroup set-parameter --hostgroup "YourHostGroup" --name "kickstart" --value "RHEL8_Custom_Kickstart"
   ```

---

**5. Create an Activation Key**

1. In Satellite, go to **Content > Activation Keys**.
2. Click **Create Activation Key**, name it (e.g., `RHEL8_Custom_Key`), and link it to the Content View and subscriptions needed.

   ```bash
   hammer activation-key create --name "RHEL8_Custom_Key" --organization "YourOrg" --content-view "RHEL8_Custom_ISO"
   hammer activation-key add-subscription --name "RHEL8_Custom_Key" --organization "YourOrg" --subscription-id <subscription_id>
   ```

3. Associate this activation key with the host group you’ll use for deployment.

---

**6. Generate the Bootable ISO**

Using **livemedia-creator**:

1. Install `lorax` and `pungi` if they are not already installed:

   ```bash
   yum install lorax pungi -y
   ```

2. Execute the `livemedia-creator` command with the necessary parameters:

   ```bash
   livemedia-creator --make-iso --iso=/path/to/base-boot.iso --ks=/path/to/kickstart.ks --image-name="RHEL8_Custom_Bootable.iso" --project="RHEL 8 Custom" --releasever=8 --vmlinuz-args="inst.ks=http://satellite.example.com/pub/ks.cfg"
   ```

   - **--make-iso**: Generates the ISO.
   - **--iso**: Base bootable ISO (e.g., RHEL minimal ISO).
   - **--ks**: Path to your Kickstart file.
   - **--image-name**: Name of the final ISO.

   Copy the generated ISO to a location accessible by Satellite users or network storage.

