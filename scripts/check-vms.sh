#!/bin/bash

echo "🔍 Checking VM Status..."

# Check if VMs are running via process list
echo "=== Running QEMU Processes ==="
ps aux | grep qemu-system-x86_64 | grep -v grep

echo ""
echo "=== Multipass Service Status ==="
sudo systemctl status snap.multipass.multipassd --no-pager -l

echo ""
echo "=== VM Instance Directories ==="
sudo ls -la /var/snap/multipass/common/data/multipassd/vault/instances/

echo ""
echo "=== Network Interfaces ==="
ip addr show | grep -E "(mpqemu|tap)" || echo "No multipass network interfaces found"

echo ""
echo "=== DHCP Leases ==="
sudo cat /var/snap/multipass/common/data/multipassd/network/dnsmasq.leases 2>/dev/null || echo "No DHCP leases found"
