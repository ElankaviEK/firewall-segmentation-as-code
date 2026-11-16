#!/usr/bin/env bash
# Remove the firewall lab: all namespaces, cables, rules and listeners.
#
# Run from the project folder:   sudo bash lab/teardown.sh
# It is safe to run even if the lab doesn't exist.

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run with sudo: sudo bash lab/teardown.sh"
    exit 1
fi

for ns in fw ns-users ns-servers ns-dmz ns-mgmt; do
    # Skip namespaces that don't exist.
    if ip netns list | grep -qw "$ns"; then
        # Stop programs still running inside (our nc listeners).
        # Deleting a namespace does NOT stop them by itself.
        ip netns pids "$ns" | xargs -r kill
        # Deleting the namespace also removes its cables and nft rules.
        ip netns del "$ns"
        echo "Removed $ns"
    fi
done
