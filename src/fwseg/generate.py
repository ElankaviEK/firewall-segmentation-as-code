"""Turn the YAML zone policy into nftables firewall rules.

The policy is default-deny: the generated chain drops everything,
except replies to existing connections and the flows listed under
"allow" in the YAML file.
"""

import yaml


def load_policy(path):
    """Read the YAML policy file and return it as a Python dictionary."""
    with open(path) as f:
        return yaml.safe_load(f)


def build_rules(policy):
    """Build the nftables ruleset as text from a policy dictionary.

    The result can be loaded later with: sudo nft -f <file>
    """
    # Look up table: zone name -> subnet, e.g. "users" -> "10.0.10.0/24".
    subnets = {name: zone["subnet"] for name, zone in policy["zones"].items()}

    # We collect the output one line at a time, then join them at the end.
    lines = [
        "table inet fwseg {",
        "    chain forward {",
        # Default-deny: anything that matches no rule below is dropped.
        "        type filter hook forward priority 0; policy drop;",
        "",
        "        # Let replies to allowed connections back through",
        "        ct state established,related accept",
        "",
    ]

    # One accept rule for each "allow" entry in the YAML.
    for rule in policy["allow"]:
        src = subnets[rule["from"]]
        dst = subnets[rule["to"]]
        # [80, 443] -> "80, 443"
        ports = ", ".join(str(port) for port in rule["ports"])
        lines.append(f"        # {rule['from']} -> {rule['to']}")
        lines.append(
            f"        ip saddr {src} ip daddr {dst} "
            f"{rule['proto']} dport {{ {ports} }} accept"
        )

    lines.append("    }")
    lines.append("}")
    # "\n".join puts a newline between lines; add one more at the very end.
    return "\n".join(lines) + "\n"
