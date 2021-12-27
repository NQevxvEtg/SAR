#!/bin/bash

echo "DANGER, YOU ARE ABOUT TO WIPE THE .ssh DIRECTORY, Do you wish to continue?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) echo -e "\nOk\n"; break;;
        No ) exit;;
    esac
done

ansible all -a "rm -fr /home/user1/.ssh" -f 10 -v
rm -fr /home/user1/.ssh
ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa <<<y >/dev/null 2>&1
touch /home/user1/.ssh/known_hosts
cat /home/user1/hosts.txt | xargs -t -I {} ssh-keyscan -H {} >> /home/user1/.ssh/known_hosts
cat /home/user1/hosts.txt | xargs -t -I {} sshpass -p Outland ssh-copy-id user1@{}
ansible all -a "uptime" -f 10 -v
