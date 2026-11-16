"""fwseg - Firewall Segmentation as Code.

This package reads network zones from a YAML file and
generates nftables firewall rules (default-deny).
"""

import sys

from fwseg.generate import build_rules, load_policy


def main() -> None:
    """Entry point for the `fwseg` command.

    Usage: fwseg [path/to/zones.yaml]
    Reads the policy file and prints the nftables rules.
    If no file is given, it uses policy/zones.yaml.
    """
    # sys.argv is the list of words typed on the command line.
    # sys.argv[0] is the program name, sys.argv[1] is the first argument.
    if len(sys.argv) > 1:
        path = sys.argv[1]
    else:
        path = "policy/zones.yaml"

    policy = load_policy(path)
    # end="" because build_rules already ends with a newline.
    print(build_rules(policy), end="")
