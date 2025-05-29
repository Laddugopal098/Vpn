#!/bin/bash

# Exit on any error
set -e

echo "[+] Updating system..."
apt update && apt upgrade -y

echo "[+] Installing WireGuard and dependencies..."
apt install -y wireguard iptables-persistent

echo "[+] Generating server keys..."
SERVER_PRIVATE_KEY=$(wg genkey)
SERVER_PUBLIC_KEY=$(echo "$SERVER_PRIVATE_KEY" | wg pubkey)

echo "[+] Creating WireGuard configuration..."
cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
Address = 10.66.66.1/24
ListenPort = 51820
PrivateKey = $SERVER_PRIVATE_KEY
SaveConfig = true
EOF

echo "[+] Enabling IP forwarding..."
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

echo "[+] Setting up firewall and NAT..."
iptables -t nat -A POSTROUTING -s 10.66.66.0/24 -o eth0 -j MASQUERADE
netfilter-persistent save

echo "[+] Enabling and starting WireGuard..."
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

echo
echo "[✔] WireGuard server is set up and running."
echo "[i] Save these keys for client configuration:"
echo "Server Private Key: $SERVER_PRIVATE_KEY"
echo "Server Public Key:  $SERVER_PUBLIC_KEY"
