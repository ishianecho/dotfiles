$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "..\..\lib\win\helpers.ps1")

$binDir = Join-Path $env:USERPROFILE ".local\bin"
New-Item -ItemType Directory -Force -Path $binDir | Out-Null

$target = Join-Path $binDir "updnvim.ps1"
if (Test-Path $target) {
    return
}

$tmp = "$target.tmp"
try {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ishianecho/bin/main/win/updnvim.ps1" -OutFile $tmp
    Move-Item -Force $tmp $target
    Write-Host "Installed updnvim.ps1"
} catch {
    Remove-Item -Force $tmp -ErrorAction SilentlyContinue
    Write-Warning "updnvim.ps1 was not installed: $($_.Exception.Message)"
}
