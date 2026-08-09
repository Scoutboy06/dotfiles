#!/usr/bin/env python3
import json
import pathlib
import re
import subprocess

ANSI = re.compile(r"\x1b\[[0-9;]*m")


def run(*command):
    try:
        return ANSI.sub("", subprocess.run(command, capture_output=True, text=True, timeout=4).stdout)
    except (OSError, subprocess.TimeoutExpired):
        return ""


def addresses():
    try:
        data = json.loads(run("ip", "-j", "address", "show") or "[]")
    except json.JSONDecodeError:
        return {}
    return {
        item["ifname"]: next((addr["local"] for addr in item.get("addr_info", []) if addr.get("family") == "inet"), "")
        for item in data
    }


def default_interface():
    match = re.search(r"\bdev\s+(\S+)", run("ip", "route", "show", "default"))
    return match.group(1) if match else ""


def wireless_interface():
    for path in pathlib.Path("/sys/class/net").glob("*/wireless"):
        return path.parent.name
    return ""


def physical_wired_interfaces(wifi):
    result = []
    for path in pathlib.Path("/sys/class/net").iterdir():
        name = path.name
        if name == wifi or name == "lo" or not (path / "device").exists():
            continue
        if (path / "operstate").read_text().strip() in ("up", "unknown"):
            result.append(name)
    return result


def parse_iwd(wifi):
    if not wifi:
        return "", []

    station = run("iwctl", "--no-pager", "station", wifi, "show")
    connected_match = re.search(r"Connected network\s+(.+?)\s*$", station, re.MULTILINE)
    connected = connected_match.group(1).strip() if connected_match else ""

    known_output = run("iwctl", "--no-pager", "known-networks", "list")
    known = set()
    for line in known_output.splitlines():
        columns = re.split(r"\s{2,}", line.strip())
        if len(columns) >= 2 and not columns[0].startswith(("Known", "---", "Name")):
            known.add(columns[0])

    visible = []
    networks_output = run("iwctl", "--no-pager", "station", wifi, "get-networks")
    for line in networks_output.splitlines():
        selected = line.lstrip().startswith(">")
        line = line.lstrip().lstrip("> ")
        columns = re.split(r"\s{2,}", line.strip())
        if len(columns) < 3 or columns[0].startswith(("Available", "---", "Network")):
            continue
        name, signal_text = columns[0], columns[-1]
        if name not in known and name != connected:
            continue
        stars = signal_text.count("*")
        signal = min(100, stars * 25) if stars else 0
        visible.append({"name": name, "connected": selected or name == connected, "signal": signal})

    visible.sort(key=lambda network: (not network["connected"], -network["signal"], network["name"].lower()))
    return connected, visible


wifi = wireless_interface()
adapter = pathlib.Path(f"/sys/class/net/{wifi}/phy80211").resolve().name if wifi else ""
adapter_state = run("iwctl", "--no-pager", "adapter", adapter, "show") if adapter else ""
wifi_enabled = bool(re.search(r"Powered\s+on", adapter_state, re.IGNORECASE))
ips = addresses()
default = default_interface()
wired = physical_wired_interfaces(wifi)
ssid, networks = parse_iwd(wifi)

print(json.dumps({
    "defaultInterface": default,
    "wifiAvailable": bool(wifi),
    "wifiInterface": wifi,
    "wifiAdapter": adapter,
    "wifiEnabled": wifi_enabled,
    "wifiAddress": ips.get(wifi, ""),
    "connectedSsid": ssid,
    "networks": networks,
    "wired": [{"name": name, "address": ips.get(name, ""), "default": name == default} for name in wired],
}))
