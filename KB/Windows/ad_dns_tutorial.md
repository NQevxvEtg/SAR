Active Directory (AD) is a directory service developed by Microsoft for Windows domain networks. The process involves installing Active Directory Domain Services (AD DS), configuring the domain controller, and promoting the server to a domain controller for the domain "test1."

Here’s the step-by-step guide to setting up Active Directory on Windows Server 2022:

### Step-by-Step Guide to Setting Up Active Directory in Windows Server 2022

#### **1. Prepare Windows Server 2022 for AD Installation**

**Step 1: Set a Static IP Address**
1. Go to the **Server Manager**.
2. Click on **Local Server** on the left side.
3. In the **Properties** section, next to **Ethernet**, click on your network interface.
4. In the **Network Connections** window, right-click your network adapter and select **Properties**.
5. Select **Internet Protocol Version 4 (TCP/IPv4)** and click **Properties**.
6. Set the **IP Address**, **Subnet Mask**, **Default Gateway**, and **DNS Server** (preferably the server’s IP as the DNS).
7. Click **OK** and close all windows.

**Step 2: Change the Computer Name**
1. In **Server Manager**, go to **Local Server**.
2. Click on **Computer Name**.
3. In the **System Properties** window, click **Change**.
4. Set the **Computer Name** (e.g., `DC1` for domain controller 1).
5. Click **OK**. You will be prompted to restart the server for the name change to take effect.

#### **2. Install Active Directory Domain Services (AD DS)**

**Step 1: Open Server Manager**
1. Open **Server Manager** from the taskbar.

**Step 2: Add Roles and Features**
1. In Server Manager, click **Manage** and select **Add Roles and Features**.
2. In the **Add Roles and Features Wizard**, click **Next** on the **Before You Begin** page.
3. On the **Installation Type** page, select **Role-based or feature-based installation** and click **Next**.

**Step 3: Select the Server**
1. On the **Server Selection** page, select your server from the list, then click **Next**.

**Step 4: Install Active Directory Domain Services (AD DS)**
1. On the **Server Roles** page, check the **Active Directory Domain Services** box.
2. A pop-up window will appear, prompting you to install the required features. Click **Add Features**.
3. Click **Next** to continue through the wizard until you reach the **Install** button. Click **Install**.

#### **3. Promote the Server to a Domain Controller**

**Step 1: Post-Installation Configuration**
1. After the AD DS role is installed, a yellow triangle will appear in the upper right corner of the **Server Manager** window. Click the **flag** icon and select **Promote this server to a domain controller**.

**Step 2: Deployment Configuration**
1. In the **Deployment Configuration** window, select **Add a new forest**.
2. In the **Root domain name** field, enter the name of your domain (e.g., `test1.com`).
3. Click **Next**.

**Step 3: Domain Controller Options**
1. On the **Domain Controller Options** page, ensure **Domain Name System (DNS) server** is checked.
2. Choose a **Directory Services Restore Mode (DSRM) password**. This is used for AD recovery, so make sure to store it securely.
3. Click **Next**.

**Step 4: DNS Options**
1. You may get a warning about delegation not being created. This is normal; click **Next**.

**Step 5: Additional Options**
1. The **NetBIOS domain name** will be generated automatically based on the domain name (e.g., `TEST1`). Click **Next**.

**Step 6: Paths**
1. Leave the **database**, **log files**, and **SYSVOL folders** to the default paths unless you have a specific reason to change them.
2. Click **Next**.

**Step 7: Review**
1. Review the configuration, then click **Next**.

**Step 8: Prerequisites Check**
1. The server will run a prerequisites check. If everything is in order, click **Install**.

#### **4. Complete the Installation**

**Step 1: Restart the Server**
1. Once the installation is complete, the server will restart automatically.

**Step 2: Verify the Domain Controller**
1. After the reboot, log in using the domain credentials: `test1\Administrator`.
2. Open **Server Manager** and verify that the Active Directory Domain Services and DNS Server roles are functioning correctly.

#### **5. Verify Active Directory Setup**

**Step 1: Check DNS**
1. Open **DNS Manager** from **Server Manager** under the **Tools** menu.
2. Ensure your domain `test1.com` appears and that there are DNS records for your server.

**Step 2: Check Active Directory**
1. Open **Active Directory Users and Computers** from **Server Manager** under **Tools**.
2. Ensure the domain `test1.com` appears and contains the default organizational units (OUs).

#### **6. Add Additional Domain Controllers (Optional)**
1. To add more domain controllers to `test1.com`, repeat the steps for installing AD DS, but instead of creating a new forest, select **Add a domain controller to an existing domain**.

