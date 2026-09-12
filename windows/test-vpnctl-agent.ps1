# Run on any PowerShell host. Function declarations are loaded through the AST;
# no real VPN command, scheduled task, or agent loop is executed.
$ErrorActionPreference = 'Stop'
$tokens = $null
$errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'vpnctl-agent.ps1'), [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw ($errors | Out-String) }
$functions = $ast.FindAll({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] }, $false)
foreach ($f in $functions) { . ([scriptblock]::Create($f.Extent.Text)) }
$Root = Join-Path ([IO.Path]::GetTempPath()) ('vpnctl-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $Root | Out-Null
$StateFile = Join-Path $Root 'state.json'
$StatusFile = Join-Path $Root 'status.json'
$ConfigFile = Join-Path $Root 'config.json'
$LogFile = Join-Path $Root 'log'
$script:connections = @(
    [pscustomobject]@{Name='Example A'; ConnectionStatus='Connected'; SplitTunneling=$true; DnsSuffix='internal.example'; Routes=@(); AuthenticationMethod=@('Eap')},
    [pscustomobject]@{Name='Example B'; ConnectionStatus='Disconnected'; SplitTunneling=$false; DnsSuffix=''; Routes=@(); AuthenticationMethod=@('Eap')}
)
$script:allConnections = @(
    [pscustomobject]@{Name='Device Tunnel'; ConnectionStatus='Connected'; SplitTunneling=$true; DnsSuffix=''; Routes=@(); AuthenticationMethod=@('MachineCertificate')}
)
$script:operations = @()
function Get-VpnConnection {
    param([switch]$AllUserConnection, $ErrorAction)
    if ($AllUserConnection) { return $script:allConnections }
    return $script:connections
}
function rasdial.exe {
    $name = $args[0]
    $disconnect = $args -contains '/disconnect'
    $script:operations += "$name/$disconnect"
    foreach ($p in @($script:connections) + @($script:allConnections)) {
        if ($p.Name -eq $name) { $p.ConnectionStatus = if ($disconnect) { 'Disconnected' } else { 'Connected' } }
    }
    $global:LASTEXITCODE = 0
}
function Assert($Condition, $Message) { if (!$Condition) { throw $Message } }
function Send-Request($Id, $Enabled, $Profile) {
    @{version=2; id=$Id; enabled=$Enabled; profileId=$Profile} | ConvertTo-Json | Set-Content $StateFile
    Invoke-Reconcile
    Get-Content $StatusFile -Raw | ConvertFrom-Json
}
try {
    Invoke-Reconcile
    $s = Get-Content $StatusFile -Raw | ConvertFrom-Json
    Assert ($s.profiles.Count -eq 2) 'Discovery failed or device tunnel was exposed'
    Assert ($s.profiles.name -notcontains 'Device Tunnel') 'Machine device tunnel must not be selectable'
    Assert ($s.profiles[0].domains[0] -eq 'internal.example') 'DNS suffix missing'
    Assert ($script:operations.Count -eq 0) 'Startup must not change existing VPNs'
    $s = Send-Request 'one' $true 'user:Example B'
    Assert ($s.error -eq '') "Connect failed: $($s.error)"
    Assert ($s.connectedIds -is [array]) 'Connected ids must always be an array'
    Assert ($s.connectedIds.Count -eq 1 -and $s.connectedIds[0] -eq 'user:Example B') 'Profile switch failed'
    $count = $script:operations.Count
    Invoke-Reconcile
    Assert ($script:operations.Count -eq $count) 'Repeated reconcile must be idempotent'
    $s = Send-Request 'two' $false ''
    Assert ($s.connectedIds.Count -eq 0 -and !$s.enabled) 'Off did not disconnect'
    Assert (!(Test-Path $StateFile)) 'Off request was not consumed'
    $script:connections[0].ConnectionStatus = 'Connected'
    $count = $script:operations.Count
    Invoke-Reconcile
    $s = Get-Content $StatusFile -Raw | ConvertFrom-Json
    Assert ($script:operations.Count -eq $count) 'Missing state changed a manually connected VPN'
    Assert ($s.connectedIds.Count -eq 1 -and $s.connectedIds[0] -eq 'user:Example A') 'Manual VPN was not published'
    $script:connections[0].ConnectionStatus = 'Disconnected'
    $s = Send-Request 'bad' $true 'missing'
    Assert ($s.error -ne '') 'Unknown profile accepted'
    Assert ($s.connectedIds.Count -eq 0) 'Invalid request changed connections'
    @{routing=@{'user:Example A'=@{domains=@('extra.example');routes=@('192.0.2.0/24')}}} | ConvertTo-Json -Depth 5 | Set-Content $ConfigFile
    Invoke-Reconcile
    $s = Get-Content $StatusFile -Raw | ConvertFrom-Json
    Assert ($s.profiles[0].domains -contains 'extra.example') 'Host routing additions missing'
    Assert ($s.profiles[0].routes -contains '192.0.2.0/24') 'Host routes missing'
    '{"profile":"Example A","expires":"2099-01-01"}' | Set-Content $StateFile
    Invoke-Reconcile
    $s = Get-Content $StatusFile -Raw | ConvertFrom-Json
    Assert ($s.error -like 'Legacy*') 'Legacy request was not rejected'
    Write-Output 'PASS: discovery, device-tunnel filtering, startup preservation, connect/switch/one-shot off, manual connection preservation, idempotence, unknown profile rejection, routing metadata, legacy rejection, atomic JSON arrays.'
} finally {
    Remove-Item $Root -Recurse -Force
}
