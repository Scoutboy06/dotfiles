# vpnctl-agent.ps1 - resident agent that reconciles the active VPN profile.
#
# Started once at logon (and re-checked every 5 min in case it died). It does
# NOT poll: it blocks on a filesystem watcher, so a state.json write from WSL
# is acted on in milliseconds. The 30s wait timeout doubles as the tick for
# lease expiry and the tailnet health check.
#
# Runs in the interactive logon session so rasdial can reach the TPM-bound
# user certificate. Launched via launch-hidden.vbs so there is no console.
#
# Fail-safe: a non-default profile must carry an expiry. If the lease is not
# renewed (because remote access died), the machine reverts to SAFE_PROFILE.

$ErrorActionPreference = 'Stop'

$Root         = Split-Path -Parent $MyInvocation.MyCommand.Path
$StateFile    = Join-Path $Root 'state.json'
$StatusFile   = Join-Path $Root 'status.json'
$LogFile      = Join-Path $Root 'vpnctl.log'
$ConfigFile   = Join-Path $Root 'config.json'

$TailscaleExe = 'C:\Program Files\Tailscale\tailscale.exe'
$MaxOffline   = 5                             # consecutive ticks offline -> revert
$TickMs       = 30000

# ---- single instance ------------------------------------------------------
# The 5-minute supervisor trigger fires this script again; if an agent is
# already resident, exit immediately and invisibly.
$mutex = New-Object System.Threading.Mutex($false, 'Local\vpnctl-agent')
if (-not $mutex.WaitOne(0)) { exit 0 }

# ---- helpers --------------------------------------------------------------

function Write-Log($msg) {
    try {
        Add-Content -Path $LogFile -Encoding utf8 `
            -Value ("{0}  {1}" -f (Get-Date -Format 's'), $msg)
        if ((Get-Item $LogFile).Length -gt 512KB) {
            Set-Content -Path $LogFile -Encoding utf8 -Value (Get-Content $LogFile -Tail 2000)
        }
    } catch { }
}

# ---- configuration --------------------------------------------------------
# Profile names live in config.json, which is untracked: this repository is
# public. Copy config.example.json and fill in the two names exactly as they
# appear in Windows. Refusing to run without it is deliberate - an agent that
# guessed at profile names could disconnect the wrong tunnel.

if (-not (Test-Path $ConfigFile)) {
    Write-Log "missing $ConfigFile - copy config.example.json and fill it in"
    exit 1
}
try {
    $config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
} catch {
    Write-Log "unreadable config.json: $($_.Exception.Message)"
    exit 1
}

$SafeProfile = $config.splitProfile
$FullProfile = $config.fullProfile
if (-not $SafeProfile -or -not $FullProfile -or $SafeProfile -eq $FullProfile) {
    Write-Log 'config.json needs distinct splitProfile and fullProfile values'
    exit 1
}
$AllProfiles = @($SafeProfile, $FullProfile)

function Get-ConnectedProfiles {
    @(Get-VpnConnection -ErrorAction SilentlyContinue |
        Where-Object { $_.ConnectionStatus -eq 'Connected' } |
        Select-Object -ExpandProperty Name)
}

function Test-TailnetOnline {
    if (-not (Test-Path $TailscaleExe)) { return $true }   # can't tell -> don't punish
    try {
        $json = & $TailscaleExe status --json --peers=false 2>$null | Out-String
        if (-not $json) { return $false }
        return [bool]((ConvertFrom-Json $json).Self.Online)
    } catch { return $false }
}

function Set-Profile($want) {
    $connected = Get-ConnectedProfiles
    if ($connected.Count -eq 1 -and $connected -contains $want) { return $false }

    foreach ($p in $AllProfiles) {
        if ($p -ne $want -and $connected -contains $p) {
            Write-Log "disconnecting '$p'"
            & rasdial.exe $p /disconnect | Out-Null
        }
    }
    if ($connected -notcontains $want) {
        Write-Log "connecting '$want'"
        $out = & rasdial.exe $want 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) { Write-Log "rasdial FAILED ($LASTEXITCODE): $($out.Trim())" }
        else                     { Write-Log "connected '$want'" }
    }
    return $true
}

# ---- one reconcile pass ---------------------------------------------------

$script:offlineStreak = 0

function Invoke-Reconcile {
    $desired = $SafeProfile
    $reason  = 'default'

    if (Test-Path $StateFile) {
        try {
            $state = Get-Content $StateFile -Raw | ConvertFrom-Json
            if ($state.profile -and ($AllProfiles -contains $state.profile)) {
                $exp = [datetime]::MinValue
                if ($state.expires -and [datetime]::TryParse($state.expires, [ref]$exp)) {
                    if ($exp.ToUniversalTime() -gt [datetime]::UtcNow) {
                        $desired = $state.profile
                        $reason  = "lease until $($exp.ToUniversalTime().ToString('s'))Z"
                    } else {
                        $reason = 'lease expired -> reverting'
                    }
                } else {
                    $reason = 'no valid expiry -> refusing to hold non-default'
                }
            } elseif ($state.profile) {
                $reason = "unknown profile '$($state.profile)'"
            }
        } catch {
            $reason = "unreadable state.json: $($_.Exception.Message)"
        }
    }

    # dead-man's switch: sustained tailnet loss forces the safe profile
    $online = Test-TailnetOnline
    if ($online) {
        $script:offlineStreak = 0
    } else {
        $script:offlineStreak++
        if ($desired -ne $SafeProfile -and $script:offlineStreak -ge $MaxOffline) {
            Write-Log "tailnet offline $($script:offlineStreak) ticks on '$desired' - forcing safe profile"
            $desired = $SafeProfile
            $reason  = "tailnet offline $($script:offlineStreak) ticks"
            Remove-Item $StateFile -ErrorAction SilentlyContinue
            $script:offlineStreak = 0
        }
    }

    $acted = Set-Profile $desired

    [pscustomobject]@{
        updated       = (Get-Date).ToUniversalTime().ToString('s') + 'Z'
        desired       = $desired
        connected     = Get-ConnectedProfiles
        reason        = $reason
        tailnetOnline = $online
        offlineStreak = $script:offlineStreak
        acted         = $acted
    } | ConvertTo-Json -Depth 4 | Set-Content -Path $StatusFile -Encoding utf8
}

# ---- main loop ------------------------------------------------------------
# WaitForChanged returns the instant state.json is touched, or after $TickMs.
# So: interactive changes are immediate, and lease/health still tick on their
# own. No polling, no spawned processes, no windows.

Write-Log "agent started (pid $PID)"

$fsw = New-Object System.IO.FileSystemWatcher $Root, '*.json'
$fsw.NotifyFilter = [System.IO.NotifyFilters]::LastWrite -bor
                    [System.IO.NotifyFilters]::FileName  -bor
                    [System.IO.NotifyFilters]::Size

while ($true) {
    try { Invoke-Reconcile }
    catch { Write-Log "reconcile error: $($_.Exception.Message)" }

    $r = $fsw.WaitForChanged([System.IO.WatcherChangeTypes]::All, $TickMs)
    if (-not $r.TimedOut) { Start-Sleep -Milliseconds 300 }   # debounce multi-event writes
}
