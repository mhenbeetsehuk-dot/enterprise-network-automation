#!/usr/bin/env bash
set -euo pipefail

echo "[1/6] Deploy topology"
sudo containerlab deploy -t topology/topology.clab.yml

echo "[2/6] Render WAN IP + OSPF configs"
python3 automation/render_linux_ips.py
python3 automation/render_frr_ospf.py

echo "[3/6] Apply WAN IPs"
bash automation/deploy_linux_ips.sh

echo "[4/6] Deploy OSPF (copies frr.conf + daemons)"
bash automation/deploy_frr_ospf.sh

echo "[5/6] Verify neighbors"
docker exec -it clab-enterprise-skeleton-SP-P1 vtysh -c "show ip ospf neighbor"

echo "[6/6] Verify HQ routes to branch loopbacks"
docker exec -it clab-enterprise-skeleton-HQ-EDGE bash -lc 'vtysh -c "show ip route ospf" | egrep "1\.1\.1\.(11|12|13)"'

echo "✅ Build complete"
