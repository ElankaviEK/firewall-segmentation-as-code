"""Checks that policy/zones.yaml is valid.

These tests catch typos in the policy file (for example a rule that
points to a zone that doesn't exist) before any firewall rules are made.
"""

from pathlib import Path

import yaml

# Path to the policy file: go up from tests/ to the project folder.
ZONES_FILE = Path(__file__).parent.parent / "policy" / "zones.yaml"


def load_policy():
    """Read the YAML file and return it as a Python dictionary."""
    with open(ZONES_FILE) as f:
        return yaml.safe_load(f)


def test_all_four_zones_exist():
    policy = load_policy()
    # set() ignores order, so we only check WHICH zones exist.
    assert set(policy["zones"]) == {"users", "servers", "dmz", "mgmt"}


def test_rules_use_real_zones():
    policy = load_policy()
    zone_names = policy["zones"].keys()
    for rule in policy["allow"]:
        # The message after the comma is shown if the check fails.
        assert rule["from"] in zone_names, f"unknown zone in rule: {rule}"
        assert rule["to"] in zone_names, f"unknown zone in rule: {rule}"


def test_ports_are_valid():
    policy = load_policy()
    for rule in policy["allow"]:
        for port in rule["ports"]:
            # Port numbers only go from 1 to 65535.
            assert 1 <= port <= 65535, f"bad port {port} in rule: {rule}"
