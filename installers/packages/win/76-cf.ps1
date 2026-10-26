$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "..\..\lib\win\helpers.ps1")

if (-not (Test-Installed "cf") -and -not (Test-Installed "cloudflare")) {
    if (-not (Test-Installed "pnpm")) {
        Write-Host "Skipping cf: pnpm not found (install pnpm first)"
        return
    }

    pnpm add -g cf
    if ($LASTEXITCODE -ne 0) {
        throw "pnpm add cf failed"
    }
}
