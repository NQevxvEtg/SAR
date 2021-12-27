cat << EOF > /etc/firewalld/zones/public.xml
<?xml version="1.0" encoding="utf-8"?>
<zone>
  <short>Public</short>
  <description>For use in public areas. You do not trust the other computers on networks to not harm your computer. Only selected incoming connections are accepted.</description>
  <service name="ssh"/>
  <service name="http"/>
  <service name="https"/>
  <interface name="enp0s3"/>
  <interface name="enp0s8"/>
  <icmp-block-inversion/>
</zone>
EOF

systemctl restart firewalld