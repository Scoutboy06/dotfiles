# Windows VPN agent

This directory belongs on the `windows-scripts` branch. Copy these scripts to
the host; they are not deployed by chezmoi. Keep machine-specific information
in `config.json` beside the agent, which is ignored by Git.

## Upgrade to protocol 2

Stop the running `vpnctl-agent` task, replace `vpnctl-agent.ps1`, then start the
task again. No task reinstallation is necessary. The new agent ignores legacy
state requests; do not leave the old agent running alongside it. The Linux
client refuses older status formats before changing any VPN state.

```powershell
Stop-ScheduledTask -TaskName vpnctl-agent
# Copy the updated vpnctl-agent.ps1 into the existing agent directory here.
Start-ScheduledTask -TaskName vpnctl-agent
```

For a new installation, run `install-task.ps1`, then start the scheduled task.
It runs in the logged-on user session using the existing hidden launcher.

## Profiles and routing

The agent discovers user and all-user Windows VPN profiles with
`Get-VpnConnection`. Machine-certificate all-user profiles are Windows device
tunnels rather than user-selectable VPNs, so the agent leaves them under Windows
policy control and does not publish them. Profile ids include their scope. It
publishes names, split/full mode, DNS suffixes, and configured IPv4 routes. No
Linux profile configuration is needed. The agent never publishes credentials.

If a split profile needs additional domain suffixes or literal IPv4 subnets,
add them to `config.json` under `routing`, keyed by the profile id or name:

```json
{
  "routing": {
    "user:Example VPN": {
      "domains": ["internal.example"],
      "routes": ["192.0.2.0/24"]
    }
  }
}
```

Use real values only in the host's untracked file. The agent reloads it each
pass. Domain matching sends names to the SOCKS endpoint for remote DNS; IPv4
subnet matching applies to literal IP URLs, not locally resolved hostnames.
Full profiles proxy all destinations except loopback. Proxy support is
application-dependent and does not provide a transparent system-wide tunnel.

## Control contract

`status.json` is written atomically as UTF-8 with `version: 2`, a request id,
`enabled`, `desiredId`, `connectedIds` (always an array), `profiles` (always an
array), and `error`. Linux atomically replaces `state.json` with a request:

```json
{"version":2,"id":"unique-request-id","enabled":true,"profileId":"user:Example VPN"}
```

With `enabled: false`, the agent disconnects discovered VPN profiles. With
`enabled: true`, it disconnects other profiles and connects the selected one.
There is no lease, expiry, tailnet watchdog, or automatic profile fallback.
The requested state remains until another request changes it. Windows policy
may prevent disconnecting; errors and actual connected ids remain visible.
Missing state does not disconnect a VPN that was started independently.

Disabling Linux immediately tears down local proxy access and attempts a
bounded host disconnect. If the host is unreachable, local access still stops,
but the host may remain connected. No Linux process retries while disabled.
Losing access to a full-tunnel host now requires restoring access or operating
the host directly; the agent does not revert automatically.
