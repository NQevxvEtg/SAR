cat << EOF > /etc/nftables.conf
flush ruleset

table inet firewall {

    # Trace chain is useful for debugging but can be removed or disabled in production
    # type filter hook prerouting priority -1;
    # meta nftrace set 1

    chain inbound_ipv4 {
        # Drop all ICMP echo-requests (pings) by default for stealth
        icmp type echo-request drop
    }

    chain inbound_ipv6 {
        # Accept neighbour discovery for IPv6 connectivity
        icmpv6 type { nd-neighbor-solicit, nd-router-advert, nd-neighbor-advert } accept
        # Drop all ICMPv6 echo-requests (pings) by default for stealth
        icmpv6 type echo-request drop
    }

    chain inbound {
        # By default, drop all inbound traffic unless explicitly allowed.
        type filter hook input priority 0; policy drop;

        # Allow traffic from established and related connections, drop invalid ones.
        ct state vmap { established : accept, related : accept, invalid : drop }

        # Allow all loopback traffic.
        iifname lo accept

        # Jump to IPv4 or IPv6 specific inbound chains based on protocol.
        meta protocol vmap { ip : jump inbound_ipv4, ip6 : jump inbound_ipv6 }

        # Allow SSH on TCP/22 for management.
        tcp dport 22 accept

        # Allow HTTP(S) on TCP/80 and TCP/443 for web access.
        tcp dport { 80, 443 } accept

        # Uncomment to enable logging of denied inbound traffic for monitoring.
        # This can be very useful for debugging and security analysis.
        # log prefix "[nftables] Inbound Denied: " counter drop
    }

    chain forward {
        # IMPORTANT: For a workstation, default to dropping all forwarded traffic.
        # This prevents the system from acting as an unintentional router.
        # Docker or other containerization solutions will add their own rules here
        # *before* this policy, allowing their traffic to be forwarded.
        type filter hook forward priority 0; policy drop;
    }

    # no need to define output chain, default policy is accept if undefined.
}
EOF

systemctl enable nftables
systemctl start nftables # Start the service immediately after applying rules