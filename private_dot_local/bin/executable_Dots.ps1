#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

function Show-Usage {
    @'
Usage: Dots <command> [args]

Commands:
  init                Reinitialize chezmoi, reset script state, and apply
  apply               Apply the current chezmoi state
  diff                Show pending changes
  status              Show chezmoi status
  edit                Open the source in the configured editor
  update              Pull the source repository and apply
  update --init       Pull, reinitialize, reset script state, and apply
  doctor              Run chezmoi doctor
  install <target>    Install a package or a curated group
  proxy [args]        Run proxy set

Options (accepted by non-proxy commands):
  --scoop-prefix <dir>   Install Scoop under <dir>
  --proxy <url>          Set the HTTP/HTTPS proxy before running the command
  --socks <url>          Set the SOCKS proxy before running the command
  --no-proxy <list>      Set hosts which bypass the proxy
  --clear-proxy          Clear the proxy before running the command

Install groups:
  shell, build, runtimes, editor, tools, operations, ai, terminal, all

Examples:
  Dots init
  Dots init --proxy http://127.0.0.1:10808 --socks socks5://127.0.0.1:10808
  Dots apply --scoop-prefix D:/Scoop
  Dots install dev
  Dots proxy http://127.0.0.1:10808 socks5://127.0.0.1:10808
'@ | Write-Host
}

function Invoke-Installer {
    param([string]$Path)

    & $Path
}

function Get-SourceDir {
    (chezmoi source-path).Trim()
}

function Reset-ScriptState {
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $output = chezmoi state delete-bucket --bucket=scriptState 2>&1
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference

    if ($exitCode -ne 0 -and "$output" -notmatch "bucket not found") {
        throw "chezmoi state delete-bucket failed: $output"
    }
}

function Initialize-Dots {
    param([string[]]$Rest = @())

    chezmoi init @Rest
    Reset-ScriptState
    chezmoi apply
}

function Get-ProxyScript {
    $localScript = Join-Path $PSScriptRoot "proxy.exe"
    if (Test-Path -LiteralPath $localScript -PathType Leaf) {
        return $localScript
    }

    Write-Error "proxy.exe was not found"
    exit 1
}

function Find-Installer {
    param([string]$Target)
    $dir = Join-Path (Get-SourceDir) "installers\packages\win"
    Get-ChildItem -LiteralPath $dir -Filter "*-${Target}.ps1" -File |
        Select-Object -First 1 -ExpandProperty FullName
}

function Invoke-MSYS2Installer {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Packages
    )

    $installer = Join-Path (Get-SourceDir) "installers\packages\win\00-msys2.ps1"
    if (-not (Test-Path -LiteralPath $installer -PathType Leaf)) {
        throw "MSYS2 installer not found"
    }

    & $installer -Packages $Packages
}

function Install-Group {
    param([string]$Group)

    if ($Group -eq "all") {
        Invoke-Installer (Join-Path (Get-SourceDir) "installers\main.ps1")
        return
    }

    $dir = Join-Path (Get-SourceDir) "installers\packages\win"
    . (Join-Path $dir "..\..\lib\win\helpers.ps1")
    $msys2Packages = @()
    $prefixPatterns = @{
        "shell"      = "(?!x)x"
        "build"      = "^(1[0-9]|2[0-9])-"
        "runtimes"   = "^3[0-9]-"
        "editor"     = "^4[0-9]-"
        "ai"         = "^5[0-9]-"
        "tools"      = "^6[0-9]-"
        "dev"        = "^6[0-9]-"
        "operations" = "^7[0-9]-"
        "terminal"   = "^8[0-9]-"
    }
    if (-not $prefixPatterns.ContainsKey($Group)) {
        throw "Unknown install group: $Group"
    }

    $packages = Get-ChildItem -LiteralPath $dir -Filter "*.ps1" -File |
        Where-Object { $_.Name -match $prefixPatterns[$Group] } |
        Sort-Object Name

    $msys2Packages = Get-MSYS2GroupPackages -Group $Group

    if ($msys2Packages.Count -gt 0) {
        Write-Host "==> Installing MSYS2 packages: $($msys2Packages -join ', ')"
        Invoke-MSYS2Installer -Packages $msys2Packages
    }

    foreach ($pkg in $packages) {
        Write-Host "==> Installing $($pkg.BaseName)"
        Invoke-Installer $pkg.FullName
    }
}

if ($args.Count -gt 0 -and $args[0] -eq "proxy") {
    $proxyRest = if ($args.Count -gt 1) {
        $args[1..($args.Count - 1)] 
    } else {
        @() 
    }
    & (Get-ProxyScript) set @proxyRest
    if (-not $?) {
        exit 1
    }
    exit 0
}

$scoopPrefix = ""
$proxyHttp = ""
$proxySocks = ""
$proxyNoProxy = ""
$proxyClear = $false
$argsList = @()

$i = 0
while ($i -lt $args.Count) {
    switch ($args[$i]) {
        "--scoop-prefix" {
            $i++
            if ($i -ge $args.Count) {
                Write-Error "--scoop-prefix requires a path"; exit 2 
            }
            $scoopPrefix = $args[$i]
            $i++
        }
        "--proxy" {
            $i++
            if ($i -ge $args.Count) {
                Write-Error "--proxy requires a URL"; exit 2 
            }
            $proxyHttp = $args[$i]
            $i++
        }
        "--socks" {
            $i++
            if ($i -ge $args.Count) {
                Write-Error "--socks requires a URL"; exit 2 
            }
            $proxySocks = $args[$i]
            $i++
        }
        "--no-proxy" {
            $i++
            if ($i -ge $args.Count) {
                Write-Error "--no-proxy requires a list"; exit 2 
            }
            $proxyNoProxy = $args[$i]
            $i++
        }
        "--clear-proxy" {
            $proxyClear = $true
            $i++
        }
        default {
            $argsList += $args[$i]
            $i++
        }
    }
}

if ($scoopPrefix) {
    $env:SCOOP_DIR = $scoopPrefix 
}

$proxyParameters = @()
if ($proxyHttp) {
    $proxyParameters += @("--http", $proxyHttp)
}
if ($proxySocks) {
    $proxyParameters += @("--socks", $proxySocks)
}
if ($proxyNoProxy) {
    $proxyParameters += @("--no-proxy", $proxyNoProxy)
}
if ($proxyClear) {
    if ($proxyParameters.Count -gt 0) {
        Write-Error "--clear-proxy cannot be combined with other proxy options"
        exit 2
    }
}
if ($proxyClear) {
    & (Get-ProxyScript) clear
    if (-not $?) {
        exit 1
    }
} elseif ($proxyParameters.Count -gt 0) {
    & (Get-ProxyScript) set @proxyParameters
    if (-not $?) {
        exit 1
    }
}

$command = if ($argsList.Count -gt 0) {
    $argsList[0] 
} else {
    "help" 
}
$rest = @()
if ($argsList.Count -gt 1) {
    $rest = @($argsList[1..($argsList.Count - 1)])
}

switch ($command) {
    "init" {
        Initialize-Dots @rest
    }
    "apply" {
        chezmoi apply @rest
    }
    "diff" {
        chezmoi diff @rest
    }
    "status" {
        chezmoi status @rest
    }
    "edit" {
        chezmoi edit @rest
    }
    "update" {
        $updateInit = $false
        $updateArgs = @()
        foreach ($arg in $rest) {
            if ($arg -eq "--init") {
                $updateInit = $true
            } else {
                $updateArgs += $arg
            }
        }
        git -C (Get-SourceDir) pull --ff-only
        if ($updateInit) {
            Initialize-Dots @updateArgs
        } else {
            chezmoi apply @updateArgs
        }
    }
    "doctor" {
        chezmoi doctor @rest
    }
    "proxy" {
        & (Get-ProxyScript) set @rest
        if (-not $?) {
            exit 1
        }
    }
    "install" {
        if ($rest.Count -eq 0) {
            Write-Error "Dots install requires a package or group name"
            exit 2
        }
        $target = $rest[0]
        switch ($target) {
            { $_ -in @("shell", "build", "runtimes", "editor", "tools", "dev", "operations", "ai", "terminal", "all") } {
                Install-Group $target
            }
            default {
                . (Join-Path (Get-SourceDir) "installers\lib\win\helpers.ps1")
                if ($target -eq "msys2") {
                    Write-Host "==> Installing MSYS2 packages: zsh"
                    Invoke-MSYS2Installer -Packages @("zsh")
                    break
                }

                if (Test-MSYS2Package -Package $target) {
                    Write-Host "==> Installing MSYS2 package: $target"
                    Invoke-MSYS2Installer -Packages @($target)
                    break
                }

                $installer = Find-Installer $target
                if (-not $installer) {
                    Write-Error "Installer not found for target: $target"
                    exit 1
                }
                Write-Host "==> Installing $target"
                Invoke-Installer $installer
            }
        }
    }
    { $_ -in @("help", "-h", "--help") } {
        Show-Usage
    }
    default {
        Write-Error "Unknown command: $command"
        Show-Usage
        exit 2
    }
}
