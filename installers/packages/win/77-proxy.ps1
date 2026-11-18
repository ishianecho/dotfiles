$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "..\..\lib\win\helpers.ps1")

$arch = switch ($env:PROCESSOR_ARCHITECTURE) {
    "AMD64" { "amd64" }
    "ARM64" { "arm64" }
    default { "" }
}
if (-not $arch) {
    Write-Warning "Unsupported architecture for bin releases"
    return
}

$binDir = Join-Path $env:USERPROFILE ".local\bin"
New-Item -ItemType Directory -Force -Path $binDir | Out-Null

$releaseBase = "https://github.com/ishianecho/bin/releases/latest/download"
foreach ($tool in @("proxy", "xrayctl")) {
    $target = Join-Path $binDir "$tool.exe"
    if (Test-Path $target) {
        continue
    }
    $tmp = "$target.tmp"
    try {
        Invoke-WebRequest -Uri "$releaseBase/$tool-windows-$arch.exe" -OutFile $tmp
        Move-Item -Force $tmp $target
        Write-Host "Installed $tool.exe"
    } catch {
        Remove-Item -Force $tmp -ErrorAction SilentlyContinue
        Write-Warning "$tool.exe was not installed: $($_.Exception.Message)"
    }
}
