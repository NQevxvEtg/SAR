ansible --version

# add servers to /etc/hosts

0.0.0.0	os1
0.0.0.0	os2
0.0.0.0	os3

# add servers to /etc/ansible/hosts

[group1]
os1
[group2]
os2
[group3]
os3

ansible -m ping os1
ansible -m ping os2
ansible -m ping os3

ansible -m ping all

# Ad-hoc Commands -------------------------------------------------------------

# in 10 parallel forks at a time
ansible arch -a "uptime" -f 10
ansible all -a "uptime" -f 10 
ansible all -a "df -h" -f 10 -v

ansible all -a "rm -fr /home/user1/.ssh" -f 10 -v

ansible all -a "ls /tmp" -f 10 -v

ansible all -a "hostnamectl" -f 10 -v

# playbook Commands -------------------------------------------------------------

ansible-playbook test.yml -f 10 -v

ansible-playbook /home/user1/playbooks/all/update.yml -K -f 10 -v

ansible-playbook /home/user1/playbooks/update.yml -K -f 10 -i my_custom_inventory -v

ansible-playbook /home/user1/playbooks/centos/reboot.yml -K -f 10 -v


ansible-playbook /home/user1/playbooks/all/push.yml -K -f 10 -v

ansible-playbook /home/user1/playbooks/all/pull.yml -K -f 10 -v



ansible centos -m ping -e 'ansible_python_interpreter=/usr/bin/python3'

# vault Commands -------------------------------------------------------------

# create empty file
ansible-vault create credentials.yml

ansible-vault encrypt some_secret.txt
ansible-vault decrypt some_secret.txt

# change password
ansible-vault rekey some_secret.txt


# fix fingerprint -------------------------------------------------------------

vim /etc/ansible/ansible.cfg 

[defaults]
host_key_checking = False


# reset ansible ssh -------------------------------------------------------------
echo "DANGER, YOU ARE ABOUT TO WIPE THE .ssh DIRECTORY, Do you wish to continue?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) echo -e "\nOk\n"; break;;
        No ) exit;;
    esac
done

# Copy the key to a server 
ssh-copy-id -i ~/.ssh/pubkey username@host

ansible all -a "rm -fr /home/user1/.ssh" -f 10 -v
rm -fr /home/user1/.ssh
ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa <<<y >/dev/null 2>&1
touch /home/user1/.ssh/known_hosts
cat /home/user1/hosts.txt | xargs -t -I {} ssh-keyscan -H {} >> /home/user1/.ssh/known_hosts
cat /home/user1/hosts.txt | xargs -t -I {} sshpass -p password ssh-copy-id user1@{}
ansible all -a "uptime" -f 10 -v

# fix human readable -------------------------------------------------------------
# Ansible 2.4+ has built-in support for human-readable results: Temporarily by setting ANSIBLE_STDOUT_CALLBACK=debug in the environment export ANSIBLE_STDOUT_CALLBACK=debug or permanently by setting stdout_callback=debug in the [default] section of ansible.cfg [default] 
# human-readable stdout/stderr results display stdout_callback = debug From Github – imjoseangel Apr 25, 2018 at 18:11 


