# Redhat

./install.sh -i
cd /opt/McAfee/agent/bin/
./maconfig -provision -managed -auto -dir /var/McAfee/agent/keystore -epo x.x.x.x:port

tail -f /var/McAfee/agent/logs/masvc_<servername>.log



/opt/McAfee/agent/bin/cmdagent -p



# Ubuntu

dpkg -l | grep -i mcafeetp
/opt/McAfee/ens/tp/init/mfetpd-control.sh status
