$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "..\..\lib\win\helpers.ps1")

if (-not (Test-Installed "songloft-player")) {
    if (-not (scoop bucket list | Where-Object { $_.Name -eq "songloft" })) {
        scoop bucket add songloft https://github.com/songloft-org/songloft-scoop
        if ($LASTEXITCODE -ne 0) {
            throw "scoop bucket add songloft failed"
        }
    }
    Install-ScoopPackage -Package "songloft-player"
}
