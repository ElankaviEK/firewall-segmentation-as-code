#!/usr/bin/env bash
# Build the firewall lab with Linux network namespaces.
#
# Run from the project folder:   sudo bash lab/setup.sh
#
# It creates 5 namespaces (separate mini network stacks):
#   ns-users, ns-servers, ns-dmz, ns-mgmt  -> one per zone
#   fw                                     -> the router + firewall
# Each zone is connected to "fw" by a virtual cable (veth pair).
# The generated nftables rules are loaded ONLY inside "fw", so the
# firewall of your real machine is not touched.

# Stop at the first command that fails, instead of carrying on.
set -e

# Network commands need root.
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run with sudo: sudo bash lab/setup.sh"
    exit 1
fi

# Go to the project folder (the folder above lab/), so the relative
# paths below work no matter where the script is started from.
cd "$(dirname "$0")/.."

# The zones and the third number of their subnet (10.0.X.0/24).
# These MUST match policy/zones.yaml.
ZONES="users:10 servers:20 dmz:30 mgmt:99"

# Start from a clean state: remove any lab left over from before.
bash lab/teardown.sh

echo "== Creating the firewall namespace"
ip netns add fw
ip -n fw link set lo up
# Turn on forwarding, so fw passes packets between zones like a router.
ip netns exec fw sysctl -q -w net.ipv4.ip_forward=1

for entry in $ZONES; do
    # Split "users:10" into zone="users" and net="10".
    zone="${entry%%:*}"
    net="${entry##*:}"
    ns="ns-$zone"

    echo "== Creating zone $zone (10.0.$net.0/24)"
    ip netns add "$ns"
    ip -n "$ns" link set lo up

    # Create a virtual cable. One end is called "to-$zone" and goes into
    # fw; the other end is called "eth0" and goes into the zone.
    ip link add "to-$zone" netns fw type veth peer name eth0 netns "$ns"

    # fw's side of the cable gets .1, the zone's machine gets .2.
    ip -n fw addr add "10.0.$net.1/24" dev "to-$zone"
    ip -n "$ns" addr add "10.0.$net.2/24" dev eth0
    ip -n fw link set "to-$zone" up
    ip -n "$ns" link set eth0 up

    # Send all traffic for other networks to fw (the "default gateway").
    ip -n "$ns" route add default via "10.0.$net.1"
done

echo "== Generating and loading the firewall rules into fw"
# .venv/bin/fwseg is the "fwseg" command that uv installed.
# (We don't call "uv" here because root usually can't find it.)
# PYTHONDONTWRITEBYTECODE stops Python leaving root-owned cache files.
if [ ! -x .venv/bin/fwseg ]; then
    echo "Can't find .venv/bin/fwseg - run 'uv sync' first (without sudo)."
    exit 1
fi
PYTHONDONTWRITEBYTECODE=1 .venv/bin/fwseg policy/zones.yaml > lab/rules.nft
ip netns exec fw nft -f lab/rules.nft

echo "== Starting listeners (fake services) with nc"
# start_listener <zone> <port>
# "nc -l -k PORT" listens on PORT and keeps going after each connection.
# "&" runs it in the background; output is thrown away.
start_listener() {
    ip netns exec "ns-$1" nc -l -k "$2" > /dev/null 2>&1 &
}
start_listener dmz 80
start_listener dmz 443
start_listener servers 443
start_listener servers 5432
# SSH port 22 in every zone, so we can test that only mgmt reaches it.
for zone in users servers dmz mgmt; do
    start_listener "$zone" 22
done

# Give the listeners a moment to start.
sleep 1
echo "== Lab is ready. Next: sudo bash lab/test_traffic.sh"
