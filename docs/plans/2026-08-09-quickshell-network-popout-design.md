# Quickshell Network Popout Design

## Goal

Add an adaptive native Network popout that presents Ethernet status on wired-only systems and Wi-Fi controls plus known networks when wireless hardware is available.

## Environment

The systems use `systemd-networkd` and iwd rather than NetworkManager. Quickshell's native networking API currently supports NetworkManager only, so a shared shell service will gather state from Linux network interfaces, the default route, and `iwctl`.

## Adaptive Layout

### Ethernet-only

The compact card shows the Network heading and settings cog, followed by the connected Ethernet interface, local address, and default-route status. It does not render a disabled Wi-Fi toggle or an empty network list when no wireless interface exists.

### Wi-Fi

When a wireless interface exists, the card adds a Wi-Fi power toggle. It shows the connected SSID, address, and signal strength, followed by visible networks already known to iwd. The connected network is highlighted.

### Ethernet and Wi-Fi

Both active connections appear in the Connected section, with the default-route connection first. Wi-Fi controls and known visible networks remain available below.

## Behavior

- Clicking the bar network icon opens the Network panel beneath that icon.
- It participates in the existing hover morph with Audio and Bluetooth.
- Clicking a connected Wi-Fi network disconnects it.
- Clicking another known visible network connects to it.
- Rows show connecting and disconnecting state inline.
- Unknown networks are omitted from the first version; the settings application handles credentials and new networks.
- The settings cog launches `omarchy launch wifi` and closes the popout.
- Wi-Fi controls are entirely omitted when wireless hardware is unavailable.

## Architecture

A shell-level Network service owns one low-frequency state process and exposes wired interfaces, wireless availability, the active/default connection, known visible networks, and control methods. Bars share this service across monitors.

The network button supplies itself as an anchor to the generalized popout request API. `PopoutHost` registers a third content panel and determines its target size before morphing.

## Styling

Use the existing Omarchy font, semantic colors, spacing, border, device-row styling, and motion tokens. The Ethernet-only card remains intentionally compact, while Wi-Fi sections increase the card's implicit height naturally.

## Validation

- Verify the current Ethernet-only desktop shows no Wi-Fi controls.
- Verify interface, address, and default-route information.
- On the laptop, test hardware detection, power toggling, SSID and signal display, known-network connection, and disconnection.
- Test morphing among Network, Bluetooth, and Audio on each monitor.
- Confirm the settings cog closes the popout.
- Check rapid refreshes, unavailable iwd state, and Quickshell logs.
