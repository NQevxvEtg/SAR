# Quick Ansible Guide

# Display the Ansible version
ansible --version

# Add servers to /etc/hosts for name resolution
0.0.0.0    os1
0.0.0.0    os2
0.0.0.0    os3

# Add servers to Ansible inventory (/etc/ansible/hosts)
[group1]
os1

[group2]
os2

[group3]
os3

# Basic Connectivity Test
ansible -m ping os1
ansible -m ping os2
ansible -m ping os3

# Ping all hosts in the inventory
ansible -m ping all

# -----------------------------------------------------------------------------
# Ad-hoc Commands
# -----------------------------------------------------------------------------

# Run commands on specified hosts with 10 parallel forks
ansible group1 -a "uptime" -f 10
ansible all -a "uptime" -f 10 
ansible all -a "df -h" -f 10 -v

# Dangerous command: Remove .ssh directory (use with caution)
ansible all -a "rm -fr /home/user1/.ssh" -f 10 -v

# List contents of /tmp on all hosts
ansible all -a "ls /tmp" -f 10 -v

# Display hostname information
ansible all -a "hostnamectl" -f 10 -v

# -----------------------------------------------------------------------------
# Playbook Commands
# -----------------------------------------------------------------------------

# Run a playbook with 10 forks and verbose mode
ansible-playbook test.yml -f 10 -v

# Run playbook with privilege escalation prompt (-K)
ansible-playbook /home/user1/playbooks/all/update.yml -K -f 10 -v

# Run playbook using a custom inventory file
ansible-playbook /home/user1/playbooks/update.yml -K -f 10 -i my_custom_inventory -v

# Example playbooks
ansible-playbook /home/user1/playbooks/centos/reboot.yml -K -f 10 -v
ansible-playbook /home/user1/playbooks/all/push.yml -K -f 10 -v
ansible-playbook /home/user1/playbooks/all/pull.yml -K -f 10 -v

# Run playbook for specific host/group with custom Python interpreter
ansible-playbook playbooks/example.yml -e 'ansible_python_interpreter=/usr/bin/python' -l <specific_host_or_group> -K -f 10 -v | tee log.txt

# Use a different Python interpreter for ad-hoc commands
ansible centos -m ping -e 'ansible_python_interpreter=/usr/bin/python3'

# Handling Permission Denied Issues (SELinux-related)
semanage login -d <ansible_username>

# -----------------------------------------------------------------------------
# Vault Commands
# -----------------------------------------------------------------------------

# Create a new vault file
ansible-vault create secrets.yml

# Encrypt an existing file
ansible-vault encrypt my_secret_vars.yml

# Decrypt an encrypted file
ansible-vault decrypt my_secret_vars.yml

# Edit an encrypted file
ansible-vault edit secrets.yml

# View the contents of an encrypted file without editing
ansible-vault view secrets.yml

# Change the password of an encrypted file
ansible-vault rekey secrets.yml

# Encrypt files during a playbook run
ansible-playbook playbook.yml --ask-vault-pass

# Use a specific vault password file (to avoid manual password entry)
ansible-playbook playbook.yml --vault-password-file /path/to/password_file


# -----------------------------------------------------------------------------
# Fix SSH Host Key Checking
# -----------------------------------------------------------------------------

# Disable SSH host key checking (use cautiously)
vim /etc/ansible/ansible.cfg

[defaults]
host_key_checking = False

# -----------------------------------------------------------------------------
# Reset Ansible SSH
# -----------------------------------------------------------------------------

echo "DANGER, YOU ARE ABOUT TO WIPE THE .ssh DIRECTORY, Do you wish to continue?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) echo -e "\nOk\n"; break;;
        No ) exit;;
    esac
done

# Copy the SSH key to a server
ssh-copy-id -i ~/.ssh/id_rsa.pub username@host

# Remove old SSH keys and regenerate new ones
ansible all -a "rm -fr /home/user1/.ssh" -f 10 -v
rm -fr /home/user1/.ssh
ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa <<<y >/dev/null 2>&1
touch /home/user1/.ssh/known_hosts
cat /home/user1/hosts.txt | xargs -t -I {} ssh-keyscan -H {} >> /home/user1/.ssh/known_hosts
cat /home/user1/hosts.txt | xargs -t -I {} sshpass -p password ssh-copy-id user1@{}

# Test SSH connectivity with a command
ansible all -a "uptime" -f 10 -v

# -----------------------------------------------------------------------------
# Make Ansible Output More Human-Readable
# -----------------------------------------------------------------------------

# Temporarily enable human-readable output
export ANSIBLE_STDOUT_CALLBACK=debug

# Permanently enable human-readable output in ansible.cfg
vim /etc/ansible/ansible.cfg

[defaults]
stdout_callback = debug

# -----------------------------------------------------------------------------
# Additional Suggestions
# -----------------------------------------------------------------------------

# Check the syntax of a playbook without executing it
ansible-playbook playbooks/example.yml --syntax-check

# List all available hosts in the inventory
ansible all --list-hosts

# Check which groups a specific host belongs to
ansible localhost -m debug -a 'msg={{ groups }}'

# Dry run (Check mode) - see what changes a playbook would make
ansible-playbook playbooks/example.yml --check

