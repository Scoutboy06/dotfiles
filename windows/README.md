# Windows scripts

These run on the work laptop and are not managed by chezmoi; `windows/` is
listed in `.chezmoiignore`. Copy them to the machine by hand. The agent keeps
its state files (`state.json`, `status.json`, `vpnctl.log`) in whatever
directory it is placed in.

## VPN agent

`vpnctl-agent.ps1` keeps the right Always On VPN profile connected. It reads
`state.json` from its own directory and reconciles the connection, which is
what lets `vpnctl` on Linux switch tunnels over SSH. A non-default profile
carries a lease; when the lease expires, or the tailnet has been unreachable
for five ticks, the agent returns to the split tunnel. That is the recovery
path if a route change cuts off remote access.

It is resident rather than periodic: it blocks on a filesystem watcher, so a
state change is acted on at once, and the 30 second wait timeout doubles as the
tick for lease expiry and the health check. Do not start it directly.

Copy `config.example.json` to `config.json` beside the agent and fill in the
two profile names exactly as Windows shows them. That file is untracked,
because this repository is public; the example is not a list of real profiles.
The agent refuses to start without it rather than guess. The Linux side keeps
its own names in `~/.config/vpnctl/config.json`; the two must agree.

`install-task.ps1` registers the agent as a per-user scheduled task. Run it
once, then start the task without logging out:

    powershell -ExecutionPolicy Bypass -File .\install-task.ps1
    Start-ScheduledTask -TaskName vpnctl-agent

No elevation is needed. The task runs as you and only while you are logged on,
which is what the TPM-bound user certificate requires. Remove it with
`Unregister-ScheduledTask -TaskName vpnctl-agent -Confirm:$false`.

`launch-hidden.vbs` starts the agent with no console window. The task invokes
it; there is no reason to run it yourself. `powershell.exe -WindowStyle Hidden`
is not a substitute, because conhost creates the window before PowerShell can
hide it.

## Packages

`install-windows-packages.ps1` is a stub. It is meant to install the packages
in `.packages/packages-winget.yaml` through winget, but currently only prints a
TODO.
