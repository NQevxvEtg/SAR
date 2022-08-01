vcloud [ ~ ]# cat 2nicsfix
#!/bin/bash
for SETTING in $(/sbin/sysctl -aN --pattern "net.ipv4.conf.(all|default|eth.*)\.rp_filter"); do /usr/bin/sed -i -e "/^${SETTING}/d" /etc/sysctl.conf;/usr/bin/echo $SETTING=0>>/etc/sysctl.conf; done; /sbin/sysctl -p


vcloud [ ~ ]# cat 2nicsnetworkingfix.service
[Unit]
Description=Service to get both nics to have network connectivity or else no network connectivity
After=local-fs.target network-online.target network.target
Wants=local-fs.target network-online.target network.target

[Service]
ExecStart=/usr/local/bin/2nicsfix
Type=oneshot

[Install]
WantedBy=multi-user.target




./2nicsfix
cp 2nicsfix /usr/local/bin/
vi 2nicsnetworkingfix.service
cp 2nicsnetworkingfix.service /lib/systemd/system/
systemctl daemon-reload
systemctl status 2nicsnetworkingfix.service
systemctl start 2nicsnetworkingfix.service
reboot

/sbin/sysctl -a --pattern "net.ipv4.conf.(all|default|eth.*)\.rp_filter"
cat 2nicsnetworkingfix.service

 
[Unit]
Description=Service to stop mcafee services
After=local-fs.target network-online.target network.target
Wants=local-fs.target network-online.target network.target

[Service]
ExecStart=/usr/local/bin/specialstopper # m
Type=oneshot

[Install]
WantedBy=multi-user.target  
