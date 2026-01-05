#!/usr/bin/env python3
from pathlib import Path
import ipaddress
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
    tpl = env.get_template("frr/ospf.conf.j2")
    dae_tpl = env.get_template("frr/daemons.j2")

    out_root = ROOT / "automation" / "rendered"
    out_root.mkdir(parents=True, exist_ok=True)

    for hostname, ifaces in iface_db.items():
        # only render OSPF if router-id exists
        if hostname not in ospf["router_ids"]:
            continue

        # build OSPF network statements from interface IPs
        ospf_intfs = []
        for ifname in ospf["networks"].get(hostname, []):
            ipcidr = ifaces[ifname["interface"]]
            net = ipaddress.ip_interface(ipcidr).network
            ospf_intfs.append({"network": str(net), "area": ifname["area"]})

        node_dir = out_root / hostname
        node_dir.mkdir(parents=True, exist_ok=True)

        (node_dir / "daemons").write_text(dae_tpl.render() + "\n")
        (node_dir / "frr.conf").write_text(
            tpl.render(
                hostname=hostname,
                interfaces=ifaces,
                process_id=ospf["process_id"],
                router_id=ospf["router_ids"][hostname],
                ospf_intfs=ospf_intfs,
            ) + "\n"
        )

    print("✅ Rendered OSPF configs for:", ", ".join(sorted(ospf["router_ids"].keys())))

if __name__ == "__main__":
    main()
