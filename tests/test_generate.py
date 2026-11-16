"""Tests for the nftables rule generator (src/fwseg/generate.py)."""

from pathlib import Path

from fwseg.generate import build_rules, load_policy

# Path to the real policy file: go up from tests/ to the project folder.
ZONES_FILE = Path(__file__).parent.parent / "policy" / "zones.yaml"


def make_rules():
    """Load the real policy and return the generated rules as text."""
    return build_rules(load_policy(ZONES_FILE))


def test_default_policy_is_drop():
    # Default-deny: the chain must drop anything not explicitly allowed.
    assert "policy drop;" in make_rules()


def test_replies_are_allowed():
    # Without this line, replies to allowed connections would be dropped.
    assert "ct state established,related accept" in make_rules()


def test_every_allow_rule_has_an_accept_line():
    policy = load_policy(ZONES_FILE)
    rules = make_rules()
    for rule in policy["allow"]:
        src = policy["zones"][rule["from"]]["subnet"]
        dst = policy["zones"][rule["to"]]["subnet"]
        assert f"ip saddr {src} ip daddr {dst}" in rules, f"missing: {rule}"


def test_users_to_mgmt_is_not_allowed():
    # users -> mgmt is not in the YAML, so no rule should allow it.
    # users = 10.0.10.0/24, mgmt = 10.0.99.0/24
    assert "ip saddr 10.0.10.0/24 ip daddr 10.0.99.0/24" not in make_rules()


def test_ports_are_written_correctly():
    # A small hand-made policy, so we know exactly what to expect.
    policy = {
        "zones": {"a": {"subnet": "10.1.0.0/24"}, "b": {"subnet": "10.2.0.0/24"}},
        "allow": [{"from": "a", "to": "b", "proto": "tcp", "ports": [80, 443]}],
    }
    expected = "ip saddr 10.1.0.0/24 ip daddr 10.2.0.0/24 tcp dport { 80, 443 } accept"
    assert expected in build_rules(policy)
