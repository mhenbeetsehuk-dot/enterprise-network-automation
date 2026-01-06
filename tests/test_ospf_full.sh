#!/usr/bin/env bash
set -euo pipefail

NODE="${1:-SP-P1}"
EXPECTED_NEIGHBORS="${2:-2}"

out="$(docker exec -it "$NODE" vtysh -c "show ip ospf neighbor" | tr -d '\r')"
echo "$out"

full_count="$(echo "$out" | awk '$3 ~ /^Full/ {c++} END {print c+0}')"

if [[ "$full_count" -lt "$EXPECTED_NEIGHBORS" ]]; then
  echo "❌ OSPF not FULL enough on $NODE (FULL=$full_count, expected >= $EXPECTED_NEIGHBORS)"
  exit 1
fi

echo "✅ OSPF FULL neighbors on $NODE: $full_count"
