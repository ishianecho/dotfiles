$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$bin = Join-Path $env:USERPROFILE ".local\bin"
$u = [Environment]::GetEnvironmentVariable("Path", "User")
if ($u -notlike "*$bin*") {
    [Environment]::SetEnvironmentVariable("Path", "$bin;$u", "User")
    $env:Path = "$bin;$env:Path"
    Write-Host "==> Added $bin to user PATH"
}

function Get-InstallOption {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [bool]$Default = $true
    )

    $value = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $Default
    }
    return $value.Trim() -match '^(?i:1|on|t|true|y|yes)$'
}

$installShell = Get-InstallOption -Name "DOTS_INSTALL_SHELL"
$installMsvc = Get-InstallOption -Name "DOTS_INSTALL_BUILD"
$installMingw = Get-InstallOption -Name "DOTS_INSTALL_BUILD"
$installBuild = Get-InstallOption -Name "DOTS_INSTALL_BUILD"
$installRuntimes = Get-InstallOption -Name "DOTS_INSTALL_RUNTIMES"
$installEditor = Get-InstallOption -Name "DOTS_INSTALL_EDITOR"
$installAi = Get-InstallOption -Name "DOTS_INSTALL_AI"
$installUtilities = Get-InstallOption -Name "DOTS_INSTALL_UTILITIES"
$installOperations = Get-InstallOption -Name "DOTS_INSTALL_OPERATIONS"
$installTerminal = Get-InstallOption -Name "DOTS_INSTALL_TERMINAL"
$installEntertainment = Get-InstallOption -Name "DOTS_INSTALL_ENTERTAINMENT" -Default $false
$installMsys2 = $installShell -or
    $installBuild -or
    $installUtilities -or
    $installTerminal

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    $defaultScoopDir = Join-Path $env:USERPROFILE "scoop"
    if (Test-Path -LiteralPath $defaultScoopDir -PathType Container) {
        Remove-Item -LiteralPath $defaultScoopDir -Recurse -Force
        Write-Host "==> Removed stale $defaultScoopDir"
    }
    if ($env:SCOOP_DIR) {
        $env:SCOOP = $env:SCOOP_DIR
        [Environment]::SetEnvironmentVariable("SCOOP", $env:SCOOP_DIR, "User")
    }
    Write-Host "==> Installing Scoop..."
    Invoke-RestMethod -Uri "https://get.scoop.sh" | Invoke-Expression
}

if (-not (scoop bucket list | Where-Object { $_.Name -eq "extras" })) {
    scoop bucket add extras
}

. (Join-Path $scriptDir "lib\win\env.ps1")
. (Join-Path $scriptDir "lib\win\helpers.ps1")

Initialize-ScoopUpdateCheck

$msys2Packages = @()
if ($installMsys2) {
    $msys2Groups = @()
    if ($installShell) {
        $msys2Groups += "shell"
    }
    if ($installBuild) {
        $msys2Groups += "build"
    }
    if ($installUtilities) {
        $msys2Groups += "tools"
    }
    if ($installTerminal) {
        $msys2Groups += "terminal"
    }
    foreach ($group in $msys2Groups) {
        $msys2Packages += Get-MSYS2GroupPackages -Group $group
    }
    $msys2Packages = @($msys2Packages | Select-Object -Unique)
}

$packages = Get-ChildItem -LiteralPath (Join-Path $scriptDir "packages\win") -Filter "*.ps1" | Sort-Object Name
$failedPackages = @()

$msys2Installer = $packages | Where-Object { $_.BaseName -eq "00-msys2" } |
    Select-Object -First 1
if (-not $msys2Installer) {
    throw "MSYS2 installer not found"
}

Write-Host "==> Processing: MSYS2 ($($msys2Packages -join ', '))"
$msys2Name = "00-msys2"
if ($msys2Packages.Count -gt 0) {
    try {
        & $msys2Installer.FullName -Packages $msys2Packages
    } catch {
        Write-Warning "Failed to install $msys2Name`: $($_.Exception.Message)"
        $failedPackages += $msys2Name
    }
}

foreach ($package in $packages) {
    if ($package.BaseName -eq "00-msys2") {
        continue
    }

    $category = switch -Regex ($package.BaseName) {
        "^00-" { "msys2" }
        "^10-" { "msvc" }
        "^11-" { "mingw" }
        "^(1[2-9]|2[0-9])-" { "build" }
        "^3[0-9]-" { "runtimes" }
        "^4[0-9]-" { "editor" }
        "^5[0-9]-" { "ai" }
        "^6[0-9]-" { "utilities" }
        "^7[0-9]-" { "operations" }
        "^8[0-9]-" { "terminal" }
        "^e[0-9]-" { "entertainment" }
        default { "" }
    }
    if (-not $category) {
        throw "No install category configured for package: $($package.BaseName)"
    }

    $categoryEnabled = switch ($category) {
        "msys2" {
            $installMsys2 
        }
        "msvc" {
            $installMsvc 
        }
        "mingw" {
            $installMingw 
        }
        "build" {
            $installBuild
        }
        "runtimes" {
            $installRuntimes 
        }
        "editor" {
            $installEditor 
        }
        "ai" {
            $installAi 
        }
        "utilities" {
            $installUtilities 
        }
        "operations" {
            $installOperations 
        }
        "terminal" {
            $installTerminal
        }
        "entertainment" {
            $installEntertainment
        }
        default {
            throw "Unknown install category: $category" 
        }
    }

    if (-not $categoryEnabled) {
        Write-Host "==> Skipping $($package.BaseName)"
        continue
    }

    Write-Host "==> Processing: $($package.BaseName)"
    try {
        & $package.FullName
    } catch {
        Write-Warning "Failed to install $($package.BaseName): $($_.Exception.Message)"
        $failedPackages += $package.BaseName
    }
}

if ($failedPackages.Count -gt 0) {
    Write-Warning "Failed packages: $($failedPackages -join ', ')"
    exit 1
}
