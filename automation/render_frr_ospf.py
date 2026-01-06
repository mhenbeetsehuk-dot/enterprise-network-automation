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

    env = Environment(
        loader=FileSystemLoader(str(ROOT / "templates")),
        trim_blocks=True,
        lstrip_blocks=True,
    )
    tpl = env.get_template("frr/frr_ospf.conf.j2")

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
            ospf_ifaces=set(ospf["interfaces"].get(hostname, [])),
            ospf_network_type=ospf.get("network_type", "point-to-point"),
        )
        (node_dir / "frr.conf").write_text(rendered + "\n")

    print("✅ Rendered FRR OSPF configs into automation/rendered/<node>/frr.conf")

if __name__ == "__main__":
    main()
