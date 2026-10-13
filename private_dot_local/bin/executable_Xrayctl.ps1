$ErrorActionPreference = "Stop"

$script:NoRestart = $false
$script:XrayDir = Join-Path $env:USERPROFILE ".config\xray"
$script:StatePath = Join-Path $script:XrayDir "state.json"
$script:ConfigPath = Join-Path $script:XrayDir "config.json"
$script:EnvPath = Join-Path $script:XrayDir "env"
$script:ServiceName = "xray"

function Show-Usage {
    @'
Usage: xrayctl <command> [args]

Node management:
  node add [tag] (vless://link | --address H --port N --uuid U --sni S
                  --public-key P --short-id I) [--use]
                      Add a vless+reality node; when the link carries a
                      #tag the tag argument may be omitted
  node rm <tag>       Remove a node
  node list           List nodes (* marks the active node)
  node use <tag>      Set the active node
  node show [tag]     Show node details
  node set <tag> [--address H] [--port N] [--uuid U] [--sni S]
                  [--public-key P] [--short-id I]

Routing rules (evaluated before all built-in rules):
  route add direct|proxy|block <matcher...>
                      matcher: domain:xxx.com, geosite:cn, full:example.com,
                      regexp:pat, geoip:cn, or a bare IP/CIDR
  route rm <matcher|index>
  route list

Ports:
  port set [--socks N] [--tproxy N]
                      The tproxy port has no effect on Windows

Service (NSSM; requires an elevated terminal):
  service install     Install and start the xray service
  service uninstall   Stop and remove the xray service
  service start
  service stop
  service restart
  service status

Other:
  status              Service state, active node, ports, route count
  restart             Regenerate, validate, and restart the service
  test                Validate the generated configuration
  init                First-run: import the env file, seed defaults

Options:
  --no-restart        Skip the service restart after a mutating command
  -h, --help          Show this help

State lives in ~\.config\xray\state.json; ~\.config\xray\config.json is
generated output. Do not edit config.json by hand.
'@ | Write-Host
}

function Get-State {
    if (-not (Test-Path -LiteralPath $script:StatePath -PathType Leaf)) {
        New-Item -ItemType Directory -Path $script:XrayDir -Force | Out-Null
        Save-State @{
            version = 1
            active  = ""
            ports   = @{ socks = 10808; tproxy = 10800 }
            nodes   = @()
            routes  = @()
        }
    }
    ConvertFrom-Json -AsHashtable -InputObject (Get-Content -LiteralPath $script:StatePath -Raw)
}

function Save-State {
    param([Parameter(Mandatory = $true)][hashtable]$State)

    New-Item -ItemType Directory -Path $script:XrayDir -Force | Out-Null
    $temporary = Join-Path $script:XrayDir "state.$([IO.Path]::GetRandomFileName()).json"
    try {
        ($State | ConvertTo-Json -Depth 32) | Set-Content -LiteralPath $temporary -Encoding utf8
        Move-Item -LiteralPath $temporary -Destination $script:StatePath -Force
    } finally {
        if (Test-Path -LiteralPath $temporary) {
            Remove-Item -LiteralPath $temporary -Force
        }
    }
}

function Read-Options {
    param(
        [Parameter(Mandatory = $true)][object[]]$Arguments,
        [string[]]$ValueFlags,
        [string[]]$SwitchFlags
    )

    $result = @{ positional = @(); flags = @{} }
    for ($i = 0; $i -lt $Arguments.Count; $i++) {
        $item = [string]$Arguments[$i]
        if ($ValueFlags -contains $item) {
            if ($i + 1 -ge $Arguments.Count) {
                throw "$item requires a value"
            }
            $result.flags[$item] = [string]$Arguments[$i + 1]
            $i++
        } elseif ($SwitchFlags -contains $item) {
            $result.flags[$item] = $true
        } elseif ($item.StartsWith("-")) {
            throw "Unknown option: $item"
        } else {
            $result.positional += $item
        }
    }
    $result
}

function Parse-VlessLink {
    param([Parameter(Mandatory = $true)][string]$Link)

    if (-not $Link.StartsWith("vless://")) {
        throw "Expected a vless:// link"
    }
    $link = $Link.Substring("vless://".Length)

    $tag = ""
    $hashIndex = $link.IndexOf("#")
    if ($hashIndex -ge 0) {
        $tag = [uri]::UnescapeDataString($link.Substring($hashIndex + 1))
        $link = $link.Substring(0, $hashIndex)
    }

    $query = ""
    $queryIndex = $link.IndexOf("?")
    if ($queryIndex -ge 0) {
        $query = $link.Substring($queryIndex + 1)
        $link = $link.Substring(0, $queryIndex)
    }

    $atIndex = $link.LastIndexOf("@")
    if ($atIndex -lt 0) {
        throw "vless:// link is missing user@host"
    }
    $uuid = $link.Substring(0, $atIndex)
    $hostPort = $link.Substring($atIndex + 1)
    $address = $hostPort
    $port = ""
    $colonIndex = $hostPort.LastIndexOf(":")
    if ($colonIndex -ge 0) {
        $address = $hostPort.Substring(0, $colonIndex)
        $port = $hostPort.Substring($colonIndex + 1)
    }
    $address = $address.Trim("[", "]")

    $security = ""
    $sni = ""
    $publicKey = ""
    $shortId = ""
    $network = ""
    $flow = ""
    foreach ($pair in $query.Split("&")) {
        if (-not $pair) {
            continue
        }
        $key = $pair
        $value = ""
        $equalsIndex = $pair.IndexOf("=")
        if ($equalsIndex -ge 0) {
            $key = $pair.Substring(0, $equalsIndex)
            $value = [uri]::UnescapeDataString($pair.Substring($equalsIndex + 1))
        }
        switch ($key) {
            "security" { $security = $value }
            "sni" { $sni = $value }
            "pbk" { $publicKey = $value }
            "sid" { $shortId = $value }
            "type" { $network = $value }
            "flow" { $flow = $value }
        }
    }
    if ($security -and $security -ne "reality") {
        throw "Only reality security is supported"
    }
    if ($network -and $network -ne "tcp") {
        throw "Only the tcp transport is supported"
    }
    if ($flow -and $flow -ne "xtls-rprx-vision") {
        throw "Only the xtls-rprx-vision flow is supported"
    }

    @{
        tag        = $tag
        address    = $address
        port       = $port
        uuid       = $uuid
        sni        = $sni
        publicKey  = $publicKey
        shortId    = $shortId
    }
}

function Assert-NodeValid {
    param(
        [Parameter(Mandatory = $true)][hashtable]$Node,
        [Parameter(Mandatory = $true)][string]$Name
    )

    if (-not $Node.uuid) {
        throw "$Name is missing a UUID"
    }
    if ($Node.uuid -notmatch "^[0-9a-fA-F-]{36}$") {
        throw "$Name has an invalid UUID"
    }
    if (-not $Node.address) {
        throw "$Name is missing an address"
    }
    if (-not $Node.sni) {
        throw "$Name is missing sni"
    }
    if (-not $Node.publicKey) {
        throw "$Name is missing a public key"
    }
    if (-not $Node.port) {
        $Node.port = "443"
    }
    $port = 0
    if (-not [int]::TryParse([string]$Node.port, [ref]$port) -or $port -lt 1 -or $port -gt 65535) {
        throw "$Name has an invalid port"
    }
    foreach ($value in @($Node.tag, $Node.address, $Node.uuid, $Node.sni, $Node.publicKey, $Node.shortId)) {
        if ($value -match '\s|["'']|\\') {
            throw "$Name must not contain whitespace, quotes, or backslashes"
        }
    }
}

function ConvertTo-StoredNode {
    param([Parameter(Mandatory = $true)][hashtable]$Node)

    [ordered]@{
        tag        = [string]$Node.tag
        address    = [string]$Node.address
        port       = [int]$Node.port
        uuid       = [string]$Node.uuid
        sni        = [string]$Node.sni
        publicKey  = [string]$Node.publicKey
        shortId    = [string]$Node.shortId
    }
}

function Assert-Matcher {
    param([Parameter(Mandatory = $true)][string]$Matcher)

    if ($Matcher -match "^(domain:|geosite:|full:|regexp:|geoip:)") {
        return
    }
    if ($Matcher -notmatch "^[0-9a-fA-F:.]+$") {
        throw "Invalid matcher: $Matcher (use domain: geosite: full: regexp: geoip: or a bare IP/CIDR)"
    }
}

function Assert-Port {
    param([Parameter(Mandatory = $true)][string]$Value)

    $port = 0
    if (-not [int]::TryParse($Value, [ref]$port) -or $port -lt 1 -or $port -gt 65535) {
        throw "Invalid port: $Value"
    }
}

function New-XrayConfig {
    param([Parameter(Mandatory = $true)][hashtable]$State)

    $active = [string]$State.active
    if (-not $active) {
        throw "No active node; run: xrayctl node use <tag>"
    }
    $matched = @($State.nodes | Where-Object { $_.tag -eq $active })
    if ($matched.Count -eq 0) {
        throw "Active node '$active' not found"
    }
    $node = $matched[0]

    $customRules = @()
    foreach ($route in @($State.routes)) {
        $outbound = if ([string]$route.action -eq "proxy") { $active } else { [string]$route.action }
        $rule = [ordered]@{
            type        = "field"
            network     = "tcp,udp"
            outboundTag = $outbound
        }
        if ([string]$route.matcher -match "^(domain:|geosite:|full:|regexp:)") {
            $rule.domain = @([string]$route.matcher)
        } else {
            $rule.ip = @([string]$route.matcher)
        }
        $customRules += $rule
    }

    [ordered]@{
        log      = [ordered]@{ loglevel = "warning" }
        dns      = [ordered]@{
            hosts = [ordered]@{
                "dns.google"         = @("8.8.8.8", "8.8.4.4")
                "dns.alidns.com"     = @("223.5.5.5", "223.6.6.6")
                "one.one.one.one"    = @("1.1.1.1", "1.0.0.1")
                "cloudflare-dns.com" = @("104.16.249.249", "104.16.248.249")
                "doh.pub"            = @("1.12.12.12", "120.53.53.53")
                "dot.pub"            = @("1.12.12.12", "120.53.53.53")
            }
            servers = @(
                [ordered]@{
                    address       = "https://dns.alidns.com/dns-query"
                    domains       = @("geosite:private", "geosite:cn")
                    skipFallback  = $true
                }
                [ordered]@{
                    address       = "223.5.5.5"
                    domains       = @("full:dns.alidns.com", "full:cloudflare-dns.com")
                    skipFallback  = $true
                }
                "https://cloudflare-dns.com/dns-query"
            )
        }
        inbounds = @(
            [ordered]@{
                tag       = "socks"
                port      = [int]$State.ports.socks
                listen    = "0.0.0.0"
                protocol  = "mixed"
                sniffing  = [ordered]@{
                    enabled      = $true
                    destOverride = @("http", "tls")
                    routeOnly    = $false
                }
                settings  = [ordered]@{
                    auth             = "noauth"
                    udp              = $true
                    allowTransparent = $false
                }
            }
            [ordered]@{
                tag      = "tun"
                protocol = "tun"
                settings = [ordered]@{
                    name                     = "XrayTun"
                    desc                     = "Xray"
                    gateway                  = @("172.19.0.1/30")
                    dns                      = @("223.5.5.5", "1.1.1.1")
                    autoSystemRoutingTable   = @("0.0.0.0/0")
                    autoOutboundsInterface   = "auto"
                }
            }
        )
        outbounds = @(
            [ordered]@{
                tag             = $active
                protocol        = "vless"
                settings        = [ordered]@{
                    vnext = @(
                        [ordered]@{
                            address = [string]$node.address
                            port    = [int]$node.port
                            users   = @(
                                [ordered]@{
                                    id         = [string]$node.uuid
                                    email      = "t@t.tt"
                                    security   = "auto"
                                    encryption = "none"
                                    flow       = "xtls-rprx-vision"
                                }
                            )
                        }
                    )
                }
                streamSettings  = [ordered]@{
                    network         = "tcp"
                    security        = "reality"
                    realitySettings = [ordered]@{
                        serverName  = [string]$node.sni
                        fingerprint = "chrome"
                        show        = $false
                        publicKey   = [string]$node.publicKey
                        shortId     = [string]$node.shortId
                        spiderX     = ""
                    }
                }
                mux             = [ordered]@{
                    enabled     = $false
                    concurrency = -1
                }
            }
            [ordered]@{ tag = "direct"; protocol = "freedom" }
            [ordered]@{ tag = "block"; protocol = "blackhole" }
        )
        routing  = [ordered]@{
            domainStrategy = "AsIs"
            rules          = @($customRules) + @(
                [ordered]@{ type = "field"; port = "443"; network = "udp"; outboundTag = "block" }
                [ordered]@{ type = "field"; outboundTag = $active; domain = @("geosite:google") }
                [ordered]@{ type = "field"; outboundTag = "direct"; ip = @("geoip:private") }
                [ordered]@{ type = "field"; outboundTag = "direct"; domain = @("geosite:private") }
                [ordered]@{ type = "field"; outboundTag = "direct"; domain = @("domain:alidns.com", "domain:doh.pub", "domain:dot.pub", "domain:360.cn", "domain:onedns.net") }
                [ordered]@{ type = "field"; outboundTag = "direct"; ip = @("geoip:cn") }
                [ordered]@{ type = "field"; outboundTag = "direct"; domain = @("geosite:cn") }
            )
        }
    }
}

function Invoke-ServiceRestartIfRunning {
    if ($script:NoRestart) {
        return
    }
    $service = Get-Service -Name $script:ServiceName -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq "Running") {
        Restart-Service -Name $script:ServiceName
        Write-Host "xray restarted"
    }
}

function Invoke-Rebuild {
    param([Parameter(Mandatory = $true)][hashtable]$State)

    $newConfig = Join-Path $script:XrayDir "config.new.json"
    (New-XrayConfig $State) | ConvertTo-Json -Depth 32 | Set-Content -LiteralPath $newConfig -Encoding utf8
    if (Get-Command xray -ErrorAction SilentlyContinue) {
        & xray run -test -c $newConfig | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Remove-Item -LiteralPath $newConfig -Force -ErrorAction SilentlyContinue
            throw "Generated configuration failed 'xray run -test'; the previous config is kept"
        }
    }
    Move-Item -LiteralPath $newConfig -Destination $script:ConfigPath -Force
    Write-Host "Generated $script:ConfigPath"
    Invoke-ServiceRestartIfRunning
}

function Invoke-NodeAdd {
    param([object[]]$Rest)

    $options = Read-Options $Rest @("--address", "--port", "--uuid", "--sni", "--public-key", "--short-id") @("--use")
    $links = @($options.positional | Where-Object { $_ -like "vless://*" })
    $tags = @($options.positional | Where-Object { $_ -notlike "vless://*" })
    if ($links.Count -gt 1) {
        throw "Only one vless:// link is allowed"
    }
    if ($tags.Count -gt 1) {
        throw "Unexpected argument: $($tags[1])"
    }

    $node = if ($links.Count -eq 1) {
        Parse-VlessLink $links[0]
    } else {
        @{
            tag        = ""
            address    = [string]$options.flags["--address"]
            port       = [string]$options.flags["--port"]
            uuid       = [string]$options.flags["--uuid"]
            sni        = [string]$options.flags["--sni"]
            publicKey  = [string]$options.flags["--public-key"]
            shortId    = [string]$options.flags["--short-id"]
        }
    }
    if (-not $node.tag -and $tags.Count -eq 1) {
        $node.tag = $tags[0]
    }
    if (-not $node.tag) {
        throw "The link has no #tag; provide a tag explicitly"
    }
    Assert-NodeValid $node "node '$($node.tag)'"

    $state = Get-State
    if (@($state.nodes | Where-Object { $_.tag -eq $node.tag }).Count -gt 0) {
        throw "Node '$($node.tag)' already exists; use: xrayctl node set"
    }
    $wasEmpty = [string]$state.active -eq ""
    $state.nodes = @($state.nodes) + @(ConvertTo-StoredNode $node)
    if ($wasEmpty -or $options.flags.ContainsKey("--use")) {
        $state.active = [string]$node.tag
    }
    Save-State $state
    Write-Host "Added node $($node.tag)"
    Invoke-Rebuild $state
}

function Invoke-NodeRm {
    param([object[]]$Rest)

    if ($Rest.Count -ne 1) {
        throw "node rm requires exactly one tag"
    }
    $tag = [string]$Rest[0]
    $state = Get-State
    if (@($state.nodes | Where-Object { $_.tag -eq $tag }).Count -eq 0) {
        throw "Node '$tag' not found"
    }
    $state.nodes = @($state.nodes | Where-Object { $_.tag -ne $tag })
    if ([string]$state.active -eq $tag) {
        $state.active = ""
    }
    Save-State $state
    Write-Host "Removed node $tag"
    if ([string]$state.active) {
        Invoke-Rebuild $state
    } else {
        Write-Host "No active node; run: xrayctl node use <tag>"
    }
}

function Invoke-NodeList {
    $state = Get-State
    foreach ($node in @($state.nodes)) {
        $marker = if ([string]$state.active -eq [string]$node.tag) { " *" } else { "" }
        Write-Host "$($node.tag)$marker`t$($node.address):$($node.port)"
    }
}

function Invoke-NodeUse {
    param([object[]]$Rest)

    if ($Rest.Count -ne 1) {
        throw "node use requires exactly one tag"
    }
    $tag = [string]$Rest[0]
    $state = Get-State
    if (@($state.nodes | Where-Object { $_.tag -eq $tag }).Count -eq 0) {
        throw "Node '$tag' not found"
    }
    $state.active = $tag
    Save-State $state
    Write-Host "Active node: $tag"
    Invoke-Rebuild $state
}

function Invoke-NodeShow {
    param([object[]]$Rest)

    $state = Get-State
    $tag = if ($Rest.Count -ge 1) { [string]$Rest[0] } else { [string]$state.active }
    if (-not $tag) {
        throw "No active node; run: xrayctl node use <tag>"
    }
    $matched = @($state.nodes | Where-Object { $_.tag -eq $tag })
    if ($matched.Count -eq 0) {
        throw "Node '$tag' not found"
    }
    $matched[0] | ConvertTo-Json -Depth 8
}

function Invoke-NodeSet {
    param([object[]]$Rest)

    if ($Rest.Count -lt 1) {
        throw "node set requires a tag"
    }
    $tag = [string]$Rest[0]
    $options = Read-Options ($Rest | Select-Object -Skip 1) @("--address", "--port", "--uuid", "--sni", "--public-key", "--short-id") @()
    $state = Get-State
    $matched = @($state.nodes | Where-Object { $_.tag -eq $tag })
    if ($matched.Count -eq 0) {
        throw "Node '$tag' not found"
    }
    $node = $matched[0]
    $fields = @{
        "--address"    = "address"
        "--port"       = "port"
        "--uuid"       = "uuid"
        "--sni"        = "sni"
        "--public-key" = "publicKey"
        "--short-id"   = "shortId"
    }
    foreach ($flag in $fields.Keys) {
        if (-not $options.flags.ContainsKey($flag)) {
            continue
        }
        $field = $fields[$flag]
        $value = [string]$options.flags[$flag]
        if ($value -match '\s|["'']|\\') {
            throw "Values must not contain whitespace, quotes, or backslashes"
        }
        if ($field -eq "port") {
            Assert-Port $value
            $node[$field] = [int]$value
        } else {
            $node[$field] = $value
        }
    }
    Save-State $state
    Write-Host "Updated node $tag"
    if ([string]$state.active -eq $tag) {
        Invoke-Rebuild $state
    }
}

function Invoke-Node {
    param([object[]]$Rest)

    if ($Rest.Count -lt 1) {
        throw "node requires a subcommand: add, rm, list, use, show, set"
    }
    $sub = [string]$Rest[0]
    $rest = $Rest | Select-Object -Skip 1
    switch ($sub) {
        "add" { Invoke-NodeAdd $rest }
        "rm" { Invoke-NodeRm $rest }
        "list" { Invoke-NodeList }
        "use" { Invoke-NodeUse $rest }
        "show" { Invoke-NodeShow $rest }
        "set" { Invoke-NodeSet $rest }
        default { throw "Unknown node subcommand: $sub" }
    }
}

function Invoke-RouteAdd {
    param([object[]]$Rest)

    if ($Rest.Count -lt 2) {
        throw "route add requires an action and at least one matcher"
    }
    $action = [string]$Rest[0]
    if ($action -notin @("direct", "proxy", "block")) {
        throw "Action must be direct, proxy, or block"
    }
    $matchers = @($Rest | Select-Object -Skip 1)
    foreach ($matcher in $matchers) {
        Assert-Matcher ([string]$matcher)
    }
    $state = Get-State
    foreach ($matcher in $matchers) {
        if (@($state.routes | Where-Object { [string]$_.matcher -eq [string]$matcher }).Count -gt 0) {
            throw "Route '$matcher' already exists; run: xrayctl route rm $matcher first"
        }
    }
    foreach ($matcher in $matchers) {
        $state.routes = @($state.routes) + @{ action = $action; matcher = [string]$matcher }
    }
    Save-State $state
    Write-Host "Added $($matchers.Count) route(s)"
    Invoke-Rebuild $state
}

function Invoke-RouteRm {
    param([object[]]$Rest)

    if ($Rest.Count -ne 1) {
        throw "route rm requires a matcher or index"
    }
    $target = [string]$Rest[0]
    $state = Get-State
    if ($target -match "^[0-9]+$") {
        $index = [int]$target
        $count = @($state.routes).Count
        if ($index -lt 1 -or $index -gt $count) {
            throw "Index out of range: $target (1-$count)"
        }
        $position = 0
        $state.routes = @($state.routes | Where-Object { ($position++) -ne $index - 1 })
    } else {
        if (@($state.routes | Where-Object { [string]$_.matcher -eq $target }).Count -eq 0) {
            throw "Route not found: $target"
        }
        $state.routes = @($state.routes | Where-Object { [string]$_.matcher -ne $target })
    }
    Save-State $state
    Write-Host "Removed route $target"
    Invoke-Rebuild $state
}

function Invoke-RouteList {
    $state = Get-State
    $index = 0
    foreach ($route in @($state.routes)) {
        $index++
        Write-Host "$index $($route.action) $($route.matcher)"
    }
}

function Invoke-Route {
    param([object[]]$Rest)

    if ($Rest.Count -lt 1) {
        throw "route requires a subcommand: add, rm, list"
    }
    $sub = [string]$Rest[0]
    $rest = $Rest | Select-Object -Skip 1
    switch ($sub) {
        "add" { Invoke-RouteAdd $rest }
        "rm" { Invoke-RouteRm $rest }
        "list" { Invoke-RouteList }
        default { throw "Unknown route subcommand: $sub" }
    }
}

function Invoke-Port {
    param([object[]]$Rest)

    if ($Rest.Count -lt 1 -or [string]$Rest[0] -ne "set") {
        throw "port requires a subcommand: set"
    }
    $options = Read-Options ($Rest | Select-Object -Skip 1) @("--socks", "--tproxy") @()
    $socks = [string]$options.flags["--socks"]
    $tproxy = [string]$options.flags["--tproxy"]
    if (-not $socks -and -not $tproxy) {
        throw "port set requires --socks or --tproxy"
    }
    $state = Get-State
    $currentSocks = [string]$state.ports.socks
    if (-not $socks) {
        $socks = [string]$state.ports.socks
    }
    if (-not $tproxy) {
        $tproxy = [string]$state.ports.tproxy
    }
    Assert-Port $socks
    Assert-Port $tproxy
    if ($socks -eq $tproxy) {
        throw "The socks and tproxy ports must differ"
    }
    if ($options.flags.ContainsKey("--tproxy")) {
        Write-Host "The tproxy port has no effect on Windows"
    }
    $state.ports = @{ socks = [int]$socks; tproxy = [int]$tproxy }
    Save-State $state
    Write-Host "Ports: socks=$socks tproxy=$tproxy"
    Invoke-Rebuild $state
    if ($socks -ne $currentSocks) {
        $setProxy = Join-Path $PSScriptRoot "Set-Proxy.ps1"
        if (Test-Path -LiteralPath $setProxy -PathType Leaf) {
            & $setProxy -Http "http://127.0.0.1:$socks" -Socks "socks5://127.0.0.1:$socks"
        }
    }
}

function Invoke-Status {
    $state = Get-State
    $service = Get-Service -Name $script:ServiceName -ErrorAction SilentlyContinue
    $serviceState = if ($service) { [string]$service.Status } else { "not installed" }
    Write-Host "service: $serviceState"
    Write-Host "node: $($state.active)"
    Write-Host "ports: socks=$($state.ports.socks) tproxy=$($state.ports.tproxy)"
    Write-Host "routes: $(@($state.routes).Count) custom"
}

function Invoke-Test {
    if (-not (Test-Path -LiteralPath $script:ConfigPath -PathType Leaf)) {
        throw "No generated config at $script:ConfigPath; run: xrayctl init"
    }
    if (-not (Get-Command xray -ErrorAction SilentlyContinue)) {
        throw "xray not found"
    }
    & xray run -test -c $script:ConfigPath
}

function Get-NssmPath {
    $nssm = (Get-Command nssm -ErrorAction SilentlyContinue).Source
    if (-not $nssm) {
        $root = if ($env:SCOOP) { $env:SCOOP } else { Join-Path $env:USERPROFILE "scoop" }
        $candidate = Join-Path $root "apps\nssm\current\nssm.exe"
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $nssm = $candidate
        }
    }
    if (-not $nssm) {
        throw "nssm not found; install it with the nssm installer or: scoop install nssm"
    }
    $nssm
}

function Assert-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "Service management requires an elevated (administrator) terminal"
    }
}

function Invoke-Service {
    param([object[]]$Rest)

    if ($Rest.Count -lt 1) {
        throw "service requires a subcommand: install, uninstall, start, stop, restart, status"
    }
    $action = [string]$Rest[0]
    if ($action -eq "status") {
        Get-Service -Name $script:ServiceName -ErrorAction SilentlyContinue
        return
    }
    Assert-Admin
    $nssm = Get-NssmPath
    switch ($action) {
        "install" {
            $exe = (Get-Command xray -ErrorAction Stop).Source
            & $nssm install $script:ServiceName $exe "run -c $script:ConfigPath"
            if ($LASTEXITCODE -ne 0) { throw "nssm install failed" }
            & $nssm set $script:ServiceName AppDirectory (Split-Path -Parent $exe)
            & $nssm start $script:ServiceName
        }
        "uninstall" {
            & $nssm stop $script:ServiceName
            & $nssm remove $script:ServiceName confirm
        }
        "start" { & $nssm start $script:ServiceName }
        "stop" { & $nssm stop $script:ServiceName }
        "restart" { & $nssm restart $script:ServiceName }
        default { throw "Unknown service subcommand: $action" }
    }
}

function Import-Env {
    $values = @{}
    foreach ($line in Get-Content -LiteralPath $script:EnvPath) {
        if ($line -match "^\s*(XRAY_[A-Z_]+)=(.*)$") {
            $values[$Matches[1]] = $Matches[2]
        }
    }
    if (-not $values.ContainsKey("XRAY_ADDRESS") -or -not $values.ContainsKey("XRAY_UUID")) {
        throw "$script:EnvPath lacks XRAY_ADDRESS or XRAY_UUID"
    }
    $node = @{
        tag        = [string]$values["XRAY_TAG"]
        address    = [string]$values["XRAY_ADDRESS"]
        port       = [string]$values["XRAY_PORT"]
        uuid       = [string]$values["XRAY_UUID"]
        sni        = [string]$values["XRAY_SNI"]
        publicKey  = [string]$values["XRAY_PUBLIC_KEY"]
        shortId    = [string]$values["XRAY_SHORT_ID"]
    }
    Assert-NodeValid $node "env node"
    $state = Get-State
    $state.nodes = @(ConvertTo-StoredNode $node)
    $state.active = [string]$node.tag
    $state.routes = @(
        @{ action = "direct"; matcher = "domain:sourceforge.net" }
        @{ action = "direct"; matcher = "domain:stackoverflow.com" }
    )
    Save-State $state
    Write-Host "Imported node $($node.tag) from $script:EnvPath"
    Write-Host "The env file is deprecated; state.json is authoritative and $script:EnvPath may be deleted"
}

function Invoke-Init {
    if (-not (Test-Path -LiteralPath $script:StatePath -PathType Leaf)) {
        $state = Get-State
        if (Test-Path -LiteralPath $script:EnvPath -PathType Leaf) {
            Import-Env
        } else {
            Write-Host "Created empty state at $script:StatePath"
            Write-Host "Add a node: xrayctl node add <tag> vless://..."
            return
        }
    }
    Invoke-Rebuild (Get-State)
}

$arguments = @()
foreach ($argument in $Args) {
    if ("$argument" -eq "--no-restart") {
        $script:NoRestart = $true
    } else {
        $arguments += "$argument"
    }
}

if ($arguments.Count -lt 1) {
    Show-Usage
    exit 2
}

$command = $arguments[0]
$rest = $arguments | Select-Object -Skip 1

switch ($command) {
    "node" { Invoke-Node $rest }
    "route" { Invoke-Route $rest }
    "port" { Invoke-Port $rest }
    "status" { Invoke-Status }
    "restart" { Invoke-Rebuild (Get-State) }
    "test" { Invoke-Test }
    "service" { Invoke-Service $rest }
    "init" { Invoke-Init }
    "-h" { Show-Usage }
    "--help" { Show-Usage }
    "help" { Show-Usage }
    default {
        Show-Usage
        exit 2
    }
}
