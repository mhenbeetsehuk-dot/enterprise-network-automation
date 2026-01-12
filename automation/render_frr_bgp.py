#!/usr/bin/env python3
from pathlib import Path
import yaml
from jinja2 import Environment, FileSystemLoader

ROOT = Path(__file__).resolve().parents[1]

def load_yaml(p: Path):
    with p.open() as f:
        return yaml.safe_load(f)

def main():
    iface_db = load_yaml(ROOT / "data/topology/interfaces.yml")["interfaces"]
    ospf = load_yaml(ROOT / "data/routing/ospf.yml")["ospf"]
    bgp = load_yaml(ROOT / "data/routing/bgp.yml")["bgp"]

    env = Environment(
        loader=FileSystemLoader(str(ROOT / "templates")),
        trim_blocks=True,
        lstrip_blocks=True,
    )
    tpl = env.get_template("frr/frr_bgp.conf.j2")
    tpl_daemons = env.get_template("frr/daemons.j2")

    out_root = ROOT / "automation" / "rendered"
    out_root.mkdir(parents=True, exist_ok=True)

    for hostname, rid in ospf["router_ids"].items():
        node_dir = out_root / hostname
        node_dir.mkdir(parents=True, exist_ok=True)

        rendered = tpl.render(
            hostname=hostname,
            interfaces=iface_db[hostname],

            ospf_router_id=rid,
            ospf_area=ospf["area"],
            ospf_ifaces=set(ospf.get("interfaces", {}).get(hostname, [])),
            ospf_network_type=ospf.get("network_type", "point-to-point"),
            ospf_prefixes=ospf.get("prefixes", ospf.get("networks", []) ) or ospf.get("loopbacks", {}),

            bgp_asn=bgp["asn"][hostname],
            bgp_router_id=bgp["router_ids"][hostname],
            bgp_neighbors=bgp.get("neighbors", {}).get(hostname, []),
            bgp_networks=bgp.get("networks", {}).get(hostname, []),
        )
        (node_dir / "frr.conf").write_text(rendered + "\n")
        (node_dir / "daemons").write_text(tpl_daemons.render() + "\n")

    print("✅ Rendered FRR OSPF+BGP configs into automation/rendered/<node>/frr.conf")

if __name__ == "__main__":
    main()
