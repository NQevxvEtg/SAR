for srv in $(firewall-cmd --list-services);do firewall-cmd --remove-service=$srv; done
firewall-cmd --add-icmp-block-inversion
firewall-cmd --remove-forward
#firewall-cmd --add-service={ssh,http,https,dhcpv6-client}
firewall-cmd --add-service={ssh,http,https}
firewall-cmd --runtime-to-permanent
firewall-cmd --list-all
