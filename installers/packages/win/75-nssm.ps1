$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "..\..\lib\win\helpers.ps1")

if (-not (Test-Installed "nssm")) {
    Install-ScoopPackage -Package "nssm"
}
