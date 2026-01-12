#!/usr/bin/env bash
set -euo pipefail

LAB="enterprise-skeleton"
NODES=(SP-P1 HQ-EDGE BR1 BR2 BR3)

cname () { echo "clab-${LAB}-$1"; }

echo "== Checking containers exist =="
for n in "${NODES[@]}"; do
  docker ps --format '{{.Names}}' | grep -q "^$(cname "$n")$" \
    && echo "OK: $n" \
    || { echo "FAIL: missing container $n"; exit 1; }
done

echo
echo "== OSPF neighbors (SP-P1) =="
docker exec -it "$(cname SP-P1)" vtysh -c "show ip ospf neighbor" || true

echo
echo "== BGP summary (all nodes) =="
for n in "${NODES[@]}"; do
  echo "----- $n -----"
  docker exec -it "$(cname "$n")" vtysh -c "show bgp summary" || true
done

echo
echo "== BGP routes on SP-P1 =="
docker exec -it "$(cname SP-P1)" vtysh -c "show ip bgp" || true

echo
echo "== End-to-end loopback pings (from HQ-EDGE to BRs) =="
for ip in 1.1.1.11 1.1.1.12 1.1.1.13; do
  echo "ping $ip"
  docker exec -it "$(cname HQ-EDGE)" sh -lc "ping -c 2 -W 1 $ip" \
    && echo "OK $ip" || { echo "FAIL $ip"; exit 1; }
done

echo
echo "✅ Verification complete"
