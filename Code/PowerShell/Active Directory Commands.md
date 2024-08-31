### **Active Directory Commands:**

1. **`dsquery user -name <username>`**
   - **Comment:** Searches Active Directory for a user account by name. Replace `<username>` with the actual name of the user.

2. **`dsadd user "CN=John Doe,OU=Users,DC=domain,DC=com"`**
   - **Comment:** Adds a new user to Active Directory. The full distinguished name (DN) of the user, including the Organizational Unit (OU) and domain components, needs to be specified.

3. **`dsget user "CN=John Doe,OU=Users,DC=domain,DC=com" -memberof`**
   - **Comment:** Retrieves the group memberships for a specific user in Active Directory.

4. **`dsmove "CN=John Doe,OU=Users,DC=domain,DC=com" -newparent "OU=Admins,DC=domain,DC=com"`**
   - **Comment:** Moves an Active Directory object (e.g., a user) to a different OU.

5. **`dsrm "CN=John Doe,OU=Users,DC=domain,DC=com"`**
   - **Comment:** Removes (deletes) an object, such as a user or computer, from Active Directory.

6. **`repadmin /replsummary`**
   - **Comment:** Provides a summary of the replication status between Domain Controllers in the forest. Useful for identifying replication issues.

7. **`repadmin /showrepl <DCName>`**
   - **Comment:** Displays the replication partners and status for a specific Domain Controller. Replace `<DCName>` with the actual name of the DC.

8. **`dcdiag`**
   - **Comment:** Runs a series of diagnostic tests on a Domain Controller to ensure it is functioning properly. This is a key tool for troubleshooting AD issues.

9. **`nltest /dsgetdc:<domain>`**
   - **Comment:** Finds the Domain Controller for the specified domain. Useful for verifying domain connectivity.

10. **`nltest /dclist:<domain>`**
    - **Comment:** Lists all Domain Controllers in a specified domain.

### **FSMO Commands:**

1. **`netdom query fsmo`**
   - **Comment:** Displays the current FSMO role holders in the domain. This is a quick way to verify which DCs hold which roles.

2. **`ntdsutil`**
   - **Comment:** A powerful utility for managing and maintaining Active Directory, including transferring and seizing FSMO roles. Used in conjunction with various subcommands.

3. **`ntdsutil: roles`**
   - **Comment:** After launching `ntdsutil`, use this command to enter the FSMO maintenance mode where you can manage FSMO roles.

4. **`ntdsutil: connections`**
   - **Comment:** In FSMO maintenance mode, this command is used to connect to the DC where FSMO roles will be transferred or seized.

5. **`ntdsutil: transfer <FSMO Role>`**
   - **Comment:** Transfers a specific FSMO role to another Domain Controller. Replace `<FSMO Role>` with the actual role, such as `PDC`, `RID Master`, etc.

6. **`ntdsutil: seize <FSMO Role>`**
   - **Comment:** Forcefully seizes a specific FSMO role from an offline Domain Controller. This is used when the current FSMO role holder is unavailable.

### **Group Policy Commands:**

1. **`gpupdate /force`**
   - **Comment:** Forces an immediate update of Group Policy settings on the local machine. This command can also be used with the `/target:user` or `/target:computer` options to update only user or computer policies.

2. **`gpresult /r`**
   - **Comment:** Displays the Resultant Set of Policy (RSoP) for the current user and computer. This shows which GPOs are applied.

3. **`gpresult /h GPReport.html`**
   - **Comment:** Generates a detailed Group Policy report in HTML format. This report provides in-depth information on applied GPOs and settings.

4. **`gpresult /user <username> /v`**
   - **Comment:** Displays detailed Group Policy information for a specified user. Replace `<username>` with the actual username.

5. **`rsop.msc`**
   - **Comment:** Launches the Resultant Set of Policy Management Console, which provides a graphical interface for viewing the Group Policy settings applied to a user or computer.

6. **`Get-GPO -All` (PowerShell)**
   - **Comment:** Lists all Group Policy Objects (GPOs) in the domain. This command requires the Group Policy module for PowerShell.

7. **`Backup-GPO -Name "<GPOName>" -Path "<BackupPath>"` (PowerShell)**
   - **Comment:** Creates a backup of a specific GPO. Replace `<GPOName>` with the name of the GPO and `<BackupPath>` with the path where the backup will be stored.

8. **`Restore-GPO -Name "<GPOName>" -Path "<BackupPath>"` (PowerShell)**
   - **Comment:** Restores a GPO from a backup. Replace `<GPOName>` with the name of the GPO and `<BackupPath>` with the path where the backup is located.

9. **`New-GPO -Name "<GPOName>"` (PowerShell)**
   - **Comment:** Creates a new Group Policy Object. Replace `<GPOName>` with the name you want to give the new GPO.

10. **`Remove-GPO -Name "<GPOName>"` (PowerShell)**
    - **Comment:** Deletes an existing GPO. Replace `<GPOName>` with the name of the GPO you want to delete.

