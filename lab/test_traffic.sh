#!/usr/bin/env bash
# Test real traffic through the lab firewall.
#
# Run AFTER setup:   sudo bash lab/test_traffic.sh
#
# Each check tries to open a TCP connection from one zone to another
# and compares the result with what the policy says should happen.
# NOTE: if you change policy/zones.yaml, update the checks below too.

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run with sudo: sudo bash lab/test_traffic.sh"
    exit 1
fi

# IP address of the test machine in each zone (set up by setup.sh).
declare -A IP=(
    [users]=10.0.10.2
    [servers]=10.0.20.2
    [dmz]=10.0.30.2
    [mgmt]=10.0.99.2
)

passed=0
failed=0

# check <from> <to> <port> <allow|block>
check() {
    local from=$1 to=$2 port=$3 expected=$4

    # nc -z : only test if the connection opens, send no data
    # nc -w 1 : give up after 1 second (blocked packets get no answer)
    if ip netns exec "ns-$from" nc -z -w 1 "${IP[$to]}" "$port" 2>/dev/null; then
        result=allow
    else
        result=block
    fi

    if [ "$result" = "$expected" ]; then
        echo "PASS  $from -> $to:$port  ($result)"
        passed=$((passed + 1))
    else
        echo "FAIL  $from -> $to:$port  (expected $expected, got $result)"
        failed=$((failed + 1))
    fi
}

echo "== Flows the policy allows"
check users dmz     80   allow
check users dmz     443  allow
check users servers 443  allow
check dmz   servers 5432 allow
check mgmt  users   22   allow
check mgmt  servers 22   allow
check mgmt  dmz     22   allow

echo "== Flows that must be blocked (default-deny)"
check users   mgmt    22   block
check users   servers 5432 block
check users   servers 22   block
check dmz     users   22   block
check servers dmz     80   block

echo
echo "$passed passed, $failed failed"
# Exit code 1 means "something failed" - CI will use this later.
if [ "$failed" -gt 0 ]; then
    exit 1
fi
