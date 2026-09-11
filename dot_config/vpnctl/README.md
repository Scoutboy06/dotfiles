# VPN controller configuration

Copy `config.example.json` to `config.json` in this directory and fill in the
SSH destination, remote agent state directory, and the two Windows VPN profile
names. Keep `config.json` local to the machine; do not add it to chezmoi.
The example is not a list of profiles discovered on Windows.

`VPNCTL_CONFIG` selects a different configuration file. `VPNCTL_HOST` and
`VPNCTL_DIR` override its SSH destination and remote directory.

`vpnctl profiles` prints the configured profile names without contacting the
laptop. `vpnctl status` reads the Windows agent status unchanged.
`vpnctl snapshot` adds configured profile names to that status for the popup.
The controller requires `jq` and SSH key authentication.

The existing Windows agent supports split tunnel and leased full tunnel.
The full-tunnel switch returns to split tunnel when off; it cannot disconnect
the VPN entirely. That requires support in the Windows agent. Leases retain
the agent's existing recovery behavior if a route change cuts off remote access.
