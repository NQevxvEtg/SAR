cd /usr/lib/systemd/system

touch nftables.service

whereis nft

vim nftables.service
 
[Unit]
Description=Netfilter Tables
Documentation=man:nft(8)
Wants=network-pre.target
Before=network-pre.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/nft -f /etc/nftables.conf

[Install]
WantedBy=multi-user.target


systemctl enable --now nftables.service
systemctl status nftables.service
nft list ruleset
