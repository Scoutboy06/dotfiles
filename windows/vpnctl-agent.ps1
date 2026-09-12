# Version 2: discover installed profiles and reconcile explicit on/off requests.
# All profile names and routing destinations are discovered locally or supplied
# in untracked config.json. There is no lease or automatic profile fallback.
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$StateFile = Join-Path $Root 'state.json'
$StatusFile = Join-Path $Root 'status.json'
$ConfigFile = Join-Path $Root 'config.json'
$LogFile = Join-Path $Root 'vpnctl.log'
$mutex = New-Object System.Threading.Mutex($false, 'Local\vpnctl-agent')
if (-not $mutex.WaitOne(0)) { exit 0 }

function Write-Log($Message) {
    try {
        Add-Content -Path $LogFile -Encoding utf8 -Value ("{0} {1}" -f (Get-Date -Format s), $Message)
        if ((Get-Item $LogFile).Length -gt 512KB) {
            $tail = @(Get-Content $LogFile -Tail 1000)
            Set-Content $LogFile -Encoding utf8 -Value $tail
        }
    } catch { }
}

function Get-Profiles {
    $result = @()
    foreach ($scope in @('user', 'all')) {
        $connections = if ($scope -eq 'all') {
            @(Get-VpnConnection -AllUserConnection -ErrorAction Stop)
        } else {
            @(Get-VpnConnection -ErrorAction Stop)
        }
        foreach ($vpn in $connections) {
            # Machine-certificate all-user profiles are Windows device tunnels,
            # not user-selectable VPNs. Leave them under Windows policy control.
            if ($scope -eq 'all' -and @($vpn.AuthenticationMethod) -contains 'MachineCertificate') { continue }
            $result += [pscustomobject]@{
                id = $scope + ':' + $vpn.Name
                name = [string]$vpn.Name
                scope = $scope
                splitTunneling = [bool]$vpn.SplitTunneling
                connected = $vpn.ConnectionStatus -eq 'Connected'
                dnsSuffix = [string]$vpn.DnsSuffix
                routes = @($vpn.Routes | ForEach-Object { if ($_.DestinationPrefix) { [string]$_.DestinationPrefix } })
            }
        }
    }
    return $result
}

function Invoke-Dial($Profile, [bool]$Disconnect) {
    $arguments = @($Profile.name)
    if ($Disconnect) { $arguments += '/disconnect' }
    if ($Profile.scope -eq 'all') {
        $arguments += '/phonebook:' + (Join-Path $env:ProgramData 'Microsoft\Network\Connections\Pbk\rasphone.pbk')
    }
    $output = & rasdial.exe @arguments 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw "VPN operation failed ($LASTEXITCODE): $($output.Trim())" }
}

function Get-PublicProfiles($Profiles) {
    $config = if (Test-Path $ConfigFile) { Get-Content $ConfigFile -Raw | ConvertFrom-Json } else { $null }
    foreach ($p in $Profiles) {
        $domains = @()
        if ($p.dnsSuffix) { $domains += $p.dnsSuffix.TrimStart('.') }
        $routes = @($p.routes)
        # Optional routing additions belong on this host. Lookup by opaque id
        # or display name, so clients never need a copy of the profile mapping.
        $extra = $null
        if ($config -and $config.routing) {
            $entry = $config.routing.PSObject.Properties[$p.id]
            if (-not $entry) { $entry = $config.routing.PSObject.Properties[$p.name] }
            if ($entry) { $extra = $entry.Value }
        }
        if ($extra) {
            $domains += @($extra.domains | Where-Object { $_ })
            $routes += @($extra.routes | Where-Object { $_ })
        }
        [pscustomobject]@{
            id = $p.id
            name = $p.name
            splitTunneling = $p.splitTunneling
            domains = @($domains | Sort-Object -Unique)
            routes = @($routes | Sort-Object -Unique)
        }
    }
}

function Write-Status($Status) {
    $temp = $StatusFile + '.' + [guid]::NewGuid().ToString('N') + '.tmp'
    try {
        $json = $Status | ConvertTo-Json -Depth 8
        [IO.File]::WriteAllText($temp, $json, (New-Object Text.UTF8Encoding($false)))
        if (Test-Path $StatusFile) { [IO.File]::Replace($temp, $StatusFile, [NullString]::Value) }
        else { [IO.File]::Move($temp, $StatusFile) }
    } finally {
        if (Test-Path $temp) { Remove-Item $temp -Force }
    }
}

function Invoke-Reconcile {
    $profiles = @(Get-Profiles)
    $enabled = $false
    $desired = ''
    $requestId = ''
    $errorText = ''
    try {
        # Missing/legacy requests do not disconnect the user's existing VPN.
        # A v2 client must explicitly take control.
        if (Test-Path $StateFile) {
            $state = Get-Content $StateFile -Raw | ConvertFrom-Json
            if ($state.version -ne 2) { throw 'Legacy request ignored; update the Linux client.' }
            if ($state.enabled -isnot [bool] -or -not ($state.id -is [string]) -or -not $state.id) {
                throw 'Invalid request'
            }
            $enabled = $state.enabled
            $requestId = $state.id
            $desired = if ($enabled) { [string]$state.profileId } else { '' }
            $target = @($profiles | Where-Object { $_.id -eq $desired })
            if ($enabled -and $target.Count -ne 1) { throw 'The requested VPN profile is not installed.' }
            foreach ($p in $profiles) {
                if ($p.connected -and (!$enabled -or $p.id -ne $desired)) { Invoke-Dial $p $true }
            }
            if ($enabled -and !$target[0].connected) { Invoke-Dial $target[0] $false }
            $profiles = @(Get-Profiles)
            # Off is a one-shot request. Once every profile is disconnected,
            # return control to Windows so a later manual connection survives
            # and can be adopted by the next Linux enable request.
            if (!$enabled) { Remove-Item $StateFile -Force }
        }
    } catch {
        $errorText = $_.Exception.Message
        Write-Log $errorText
        $profiles = @(Get-Profiles)
    }
    $public = @(Get-PublicProfiles $profiles)
    Write-Status ([pscustomobject]@{
        version = 2
        updated = [datetime]::UtcNow.ToString('o')
        requestId = $requestId
        enabled = $enabled
        desiredId = $desired
        connectedIds = @($profiles | Where-Object { $_.connected } | ForEach-Object { $_.id })
        profiles = $public
        error = $errorText
    })
}

$watcher = New-Object IO.FileSystemWatcher $Root, 'state.json'
$watcher.NotifyFilter = [IO.NotifyFilters]::LastWrite -bor [IO.NotifyFilters]::FileName -bor [IO.NotifyFilters]::Size
Write-Log "agent v2 started (pid $PID)"
try {
    while ($true) {
        try { Invoke-Reconcile } catch { Write-Log $_.Exception.Message }
        # Only the Windows agent reconciles periodically. Disabled Linux
        # clients have no timer, SSH connection, or status requests.
        $event = $watcher.WaitForChanged([IO.WatcherChangeTypes]::All, 3000)
        if (!$event.TimedOut) { Start-Sleep -Milliseconds 100 }
    }
} finally {
    $watcher.Dispose()
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}
