#!/usr/bin/env bash
set -euo pipefail

LAB="enterprise-skeleton"

# Ensure bgpd enabled in daemons and start it
enable_bgpd () {
  local c="$1"
  docker exec -it "$c" bash -lc '
    sed -i "s/^bgpd=.*/bgpd=yes/" /etc/frr/daemons
    chown frr:frr /etc/frr/daemons || true
    chmod 640 /etc/frr/daemons || true
    pkill -x bgpd 2>/dev/null || true
    sleep 1
    /usr/lib/frr/bgpd -d -F traditional -A 127.0.0.1 -f /etc/frr/frr.conf -u frr -g frr || true
  '
}

cfg () {
  local c="$1"; shift
  docker exec -it "$c" vtysh -c "conf t" $(printf ' -c "%s"' "$@") -c "end" -c "write"
}

# SP-P1 (AS 65100)
C_SP="clab-${LAB}-SP-P1"
enable_bgpd "$C_SP"
cfg "$C_SP" \
"router bgp 65100" \
"bgp router-id 1.1.1.1" \
"no bgp ebgp-requires-policy" \
"neighbor 10.0.0.1 remote-as 65000" \
"neighbor 10.0.0.5 remote-as 65010" \
"neighbor 10.0.0.9 remote-as 65020" \
"neighbor 10.0.0.13 remote-as 65030" \
"address-family ipv4 unicast" \
" neighbor 10.0.0.1 activate" \
" neighbor 10.0.0.5 activate" \
" neighbor 10.0.0.9 activate" \
" neighbor 10.0.0.13 activate" \
"exit-address-family"

# HQ-EDGE (AS 65000)
C_HQ="clab-${LAB}-HQ-EDGE"
enable_bgpd "$C_HQ"
cfg "$C_HQ" \
"router bgp 65000" \
"bgp router-id 1.1.1.2" \
"no bgp ebgp-requires-policy" \
"neighbor 10.0.0.2 remote-as 65100" \
"address-family ipv4 unicast" \
" neighbor 10.0.0.2 activate" \
" network 1.1.1.2/32" \
"exit-address-family"

# BR1 (AS 65010)
C_B1="clab-${LAB}-BR1"
enable_bgpd "$C_B1"
cfg "$C_B1" \
"router bgp 65010" \
"bgp router-id 1.1.1.11" \
"no bgp ebgp-requires-policy" \
"neighbor 10.0.0.6 remote-as 65100" \
"address-family ipv4 unicast" \
" neighbor 10.0.0.6 activate" \
" network 1.1.1.11/32" \
"exit-address-family"

# BR2 (AS 65020)
C_B2="clab-${LAB}-BR2"
enable_bgpd "$C_B2"
cfg "$C_B2" \
"router bgp 65020" \
"bgp router-id 1.1.1.12" \
"no bgp ebgp-requires-policy" \
"neighbor 10.0.0.10 remote-as 65100" \
"address-family ipv4 unicast" \
" neighbor 10.0.0.10 activate" \
" network 1.1.1.12/32" \
"exit-address-family"

# BR3 (AS 65030)
C_B3="clab-${LAB}-BR3"
enable_bgpd "$C_B3"
cfg "$C_B3" \
"router bgp 65030" \
"bgp router-id 1.1.1.13" \
"no bgp ebgp-requires-policy" \
"neighbor 10.0.0.14 remote-as 65100" \
"address-family ipv4 unicast" \
" neighbor 10.0.0.14 activate" \
" network 1.1.1.13/32" \
"exit-address-family"

echo "✅ BGP deployed"
