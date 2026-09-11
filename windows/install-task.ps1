# Registers the vpnctl agent as a per-user scheduled task.
# No elevation required - it runs as you, only while you are logged on, which
# is exactly what the TPM-bound user certificate needs.
#
# The task starts the agent at logon and re-checks every 5 minutes. That is a
# supervisor, not a poll: if the agent is already resident it takes a mutex,
# exits in milliseconds, and does no work. The agent itself is event-driven.
#
# Everything is launched through launch-hidden.vbs, so no console window is
# ever created - not at logon, not on the supervisor ticks.

$ErrorActionPreference = 'Stop'

$Root     = Split-Path -Parent $MyInvocation.MyCommand.Path
$Launcher = Join-Path $Root 'launch-hidden.vbs'
$Agent    = Join-Path $Root 'vpnctl-agent.ps1'
$Name     = 'vpnctl-agent'

foreach ($f in @($Launcher, $Agent)) {
    if (-not (Test-Path $f)) { throw "missing $f" }
}

$action = New-ScheduledTaskAction `
    -Execute 'wscript.exe' `
    -Argument "`"$Launcher`""

# At logon, plus a supervisor sweep every 5 minutes to restart it if it died.
$atLogon = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
$sweep   = New-ScheduledTaskTrigger -Once -At (Get-Date) `
               -RepetitionInterval (New-TimeSpan -Minutes 5) `
               -RepetitionDuration (New-TimeSpan -Days 3650)

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -DontStopOnIdleEnd `
    -MultipleInstances IgnoreNew `
    -ExecutionTimeLimit ([TimeSpan]::Zero)      # resident agent: never time it out

$principal = New-ScheduledTaskPrincipal `
    -UserId "$env:USERDOMAIN\$env:USERNAME" `
    -LogonType Interactive `
    -RunLevel Limited

Unregister-ScheduledTask -TaskName $Name -Confirm:$false -ErrorAction SilentlyContinue

Register-ScheduledTask `
    -TaskName $Name `
    -Action $action `
    -Trigger @($atLogon, $sweep) `
    -Settings $settings `
    -Principal $principal `
    -Description 'Reconciles explicit VPN on/off and profile requests from state.json.' | Out-Null

Write-Host "Registered scheduled task '$Name'."
Write-Host ""
Write-Host "Start it now without logging out:"
Write-Host "  Start-ScheduledTask -TaskName $Name"
Write-Host ""
Write-Host "Check the agent is resident:"
Write-Host "  Get-Process powershell | Where-Object { `$_.StartTime -gt (Get-Date).AddMinutes(-5) }"
Write-Host ""
Write-Host "Remove everything:"
Write-Host "  Unregister-ScheduledTask -TaskName $Name -Confirm:`$false"
