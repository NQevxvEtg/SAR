Step 1: Configure Satellite Content Export

1. Identify the Content View and Lifecycle Environment: Before scheduling exports, identify the content view (e.g., Default Content View) and lifecycle environment (e.g., Library) that you want to export. You’ll need these names for the export command.


2. Prepare Export Directory: Choose or create a directory on the Satellite server where export files will be stored. For example:

sudo mkdir -p /var/lib/exports
sudo chown foreman /var/lib/exports




---

Step 2: Create an Export Script

Create a script that will handle the export and compression. This script will automate the export process, store it in the specified directory, and compress it for transfer.

1. Create the Script: Using your preferred text editor, create a script file named content_export.sh in /usr/local/bin/:

sudo vi /usr/local/bin/content_export.sh


2. Script Content: Copy the following script content into content_export.sh. This script exports content from the specified content view and lifecycle environment, then compresses it.

#!/bin/bash

# Variables
EXPORT_DIR="/var/lib/exports"
CONTENT_VIEW="Default Content View"  # replace with actual content view name
LIFECYCLE_ENV="Library"              # replace with actual lifecycle environment
ORG_NAME="YOUR_ORG_NAME"             # replace with your organization name
DATE=$(date +"%Y%m%d")

# Export Content
echo "Starting content export..."
hammer content-export create \
    --organization="${ORG_NAME}" \
    --content-view="${CONTENT_VIEW}" \
    --environment="${LIFECYCLE_ENV}" \
    --export-dir="${EXPORT_DIR}/${DATE}"

# Compress the Exported Content
echo "Compressing export..."
tar -czvf "${EXPORT_DIR}/satellite_export_${DATE}.tar.gz" -C "${EXPORT_DIR}/${DATE}" .

# Clean up the uncompressed export files
echo "Cleaning up..."
rm -rf "${EXPORT_DIR}/${DATE}"

echo "Content export and compression completed successfully."


3. Make the Script Executable:

sudo chmod +x /usr/local/bin/content_export.sh



This script performs the following actions:

Exports content based on the specified view and environment.

Compresses the export into a tar.gz archive for easy transfer to an air-gapped system.

Cleans up the temporary export files, leaving only the compressed archive.



---

Step 3: Schedule the Script to Run Automatically Using Cron

To automate the export and compression every Sunday at 0 UTC, we’ll add a cron job.

1. Open the Crontab for the Foreman User: Since the export commands need access to Satellite’s Hammer CLI, run the cron job as the foreman user.

sudo crontab -e -u foreman


2. Add the Cron Job: Add the following line to the crontab file to run the script at 0 UTC every Sunday:

0 0 * * 0 /usr/local/bin/content_export.sh >> /var/log/satellite_content_export.log 2>&1

This line does the following:

0 0 * * 0: Specifies Sunday at 0 UTC.

/usr/local/bin/content_export.sh: Runs the script we created.

>> /var/log/satellite_content_export.log 2>&1: Redirects the output and errors to a log file for troubleshooting.



3. Save and Exit the Crontab.



Step 4: Verify and Monitor the Automated Export

After setting up the cron job, you can monitor its output to ensure it runs as expected.

1. Check the Log: After the first scheduled run, review the log file at /var/log/satellite_content_export.log for any errors or output messages.

tail -f /var/log/satellite_content_export.log


2. Verify Compressed Export Files: The compressed export files should appear in /var/lib/exports with a filename like satellite_export_YYYYMMDD.tar.gz. You can then transfer this file to your air-gapped system using secure methods (e.g., USB, offline transfer methods).


3. Manual Run for Testing (Optional): To confirm the setup before the scheduled time, run the export script manually.

sudo /usr/local/bin/content_export.sh




---

Summary of Commands

Script creation:

sudo vi /usr/local/bin/content_export.sh

Make executable:

sudo chmod +x /usr/local/bin/content_export.sh

Add cron job:

sudo crontab -e -u foreman

Manual script execution (for testing):

sudo /usr/local/bin/content_export.sh




