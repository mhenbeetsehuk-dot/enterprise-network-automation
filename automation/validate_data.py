#!/usr/bin/env python3
import ipaddress
import yaml
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def load_yaml(path: Path):
    with path.open() as f:
        return yaml.safe_load(f)

def main():
    sites = load_yaml(ROOT / "data/sites/sites.yml")["sites"]
    routing = load_yaml(ROOT / "data/routing/routing.yml")["routing_intent"]

    # 1) Validate no duplicate subnets across site VLANs
    seen = {}
    for name, s in sites.items():
        for vname, v in s["vlans"].items():
            net = ipaddress.ip_network(v["subnet"])
            if str(net) in seen:
                raise SystemExit(f"Duplicate subnet {net} in {name}/{vname} and {seen[str(net)]}")
            seen[str(net)] = f"{name}/{vname}"

    # 2) Validate WAN subnets are /30
    for name, s in sites.items():
        net = ipaddress.ip_network(s["wan"]["subnet"])
        if net.prefixlen != 30:
            raise SystemExit(f"{name} WAN subnet {net} is not /30")

    # 3) Validate policy: no branch redistribution (policy exists)
    forbidden_devices = set()
    for rule in routing["redistribution_policy"]["forbidden"]:
        if "devices" in rule:
            forbidden_devices.update(rule["devices"])
    # Not checking configs yet (none exist), but we ensure list exists and includes branches
    for b in ["BR1", "BR2", "BR3"]:
        if b not in forbidden_devices:
            raise SystemExit(f"Routing policy missing branch in forbidden redistribution list: {b}")

    print("✅ Data validation passed.")

if __name__ == "__main__":
    main()
