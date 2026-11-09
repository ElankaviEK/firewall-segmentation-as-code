"""fwseg - Firewall Segmentation as Code.

This package reads network zones from a YAML file and
generates nftables firewall rules (default-deny).
"""


def main() -> None:
    """Entry point for the `fwseg` command.

    For now it only prints a message. In step 3 it will
    read zones.yaml and print the firewall rules.
    """
    print("Hello from fwseg!")
