"""Read the Pixel's A2DP transport, without changing Bluetooth state."""
import json
import subprocess

ADDRESS = "E8:D5:2B:74:7E:FE"
SINK_UUID = "0000110b-0000-1000-8000-00805f9b34fb"


def connected(objects):
    devices = {
        path for path, interfaces in objects.items()
        if interfaces.get("org.bluez.Device1", {}).get("Address", {}).get("data") == ADDRESS
    }
    return any(
        transport.get("Device", {}).get("data") in devices
        and transport.get("UUID", {}).get("data") == SINK_UUID
        for interfaces in objects.values()
        for transport in [interfaces.get("org.bluez.MediaTransport1", {})]
    )


if __name__ == "__main__":
    try:
        result = subprocess.run(
            ["busctl", "--system", "--json=short", "--timeout=3", "call",
             "org.bluez", "/", "org.freedesktop.DBus.ObjectManager", "GetManagedObjects"],
            capture_output=True, text=True, check=True, timeout=4,
        )
        print(json.dumps({"connected": connected(json.loads(result.stdout)["data"][0])}))
    except (subprocess.SubprocessError, ValueError, KeyError, OSError):
        print(json.dumps({"error": "Unable to read Bluetooth audio state"}))
