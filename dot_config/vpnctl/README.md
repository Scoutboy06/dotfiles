# On-demand VPN proxy

Copy `config.example.json` to `config.json` here and set the SSH host and remote
agent directory. Keep that file local, outside Git. The host must run version 2
of the agent from the `windows-scripts` branch. SSH reaches the host's WSL
instance, whose networking must have access to the Windows VPN (as in the POC).
No VPN profile, server, company domain, or company IP belongs in these dotfiles.

The top switch enables/disables access from this machine. `vpnctl on` starts
`vpnctl.service` on demand; there is no install target, auto-start, or automatic
restart. Only while enabled does the worker fetch host status, run an SSH SOCKS
proxy, and serve a loopback PAC file. The popup watches local state files; it
runs no status command, remote request, or polling timer while disabled.

`vpnctl off` stops the entire service, closes proxy connections, restores the
previous system proxy settings, and makes one bounded host disconnect attempt.
If the host is unreachable, local access still stops. Nothing retries remotely
while disabled. The host may remain connected in that case.

Profile names, split/full mode, domains, and routes come from the host. Select a
profile in the popup or use `vpnctl select <id>`. There are no leases or renewal
controls. `vpnctl status` and `vpnctl profiles` read local state only; neither
contacts the host. Turning on initially adopts an already connected profile,
otherwise prefers a split profile discovered on the host.

## Application routing

The worker temporarily sets GNOME-compatible system proxy settings to a PAC URL
served on loopback. Applications must use system proxy settings (in Firefox/Zen,
select **Use system proxy settings**). An existing manual proxy or PAC override
in an application will take precedence. This is not a transparent IP VPN:
applications ignoring system proxies and arbitrary UDP traffic are unaffected.

Split profiles match host-provided domain suffixes and literal IPv4 subnet URLs;
DNS for proxied names is resolved remotely by SOCKS. Full profiles send all proxy
traffic except loopback through the host. Missing split routing data is an error;
configure routing additions only in the Windows host's untracked config.json.
Changes to the PAC URL force a fresh profile's routing configuration to load.

Required local tools: Python 3, OpenSSH, systemd user services, and gsettings.
Do not enable the systemd unit at login. `ExecStopPost` restores proxy settings
and clears local state even after an unexpected worker exit. A configuration
error or incompatible host leaves access off instead of polling indefinitely.

After copying the upgraded Windows agent and starting its task, run
`systemctl --user daemon-reload` once after deploying the Linux unit. The popup
is ready without enabling access automatically. The Windows README documents
the protocol and upgrade steps. Actual Windows VPN behavior needs verification
on that host; Linux tests use a simulated host and SSH endpoint.
