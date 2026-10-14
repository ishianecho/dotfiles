$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath (Join-Path $env:USERPROFILE ".zshrc") -PathType Leaf)) {
    return
}

$msys2Root = ""
try {
    $msys2Root = (scoop prefix msys2).Trim()
} catch {
    return
}

$msys2Zsh = Join-Path $msys2Root "usr\bin\zsh.exe"
if (-not (Test-Path -LiteralPath $msys2Zsh -PathType Leaf)) {
    return
}

$previousMSystem = $env:MSYSTEM
$env:MSYSTEM = "MSYS"
try {
    & $msys2Zsh -i -l -c 'exit'
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "zinit plugin installation failed"
    }
} finally {
    if ($null -eq $previousMSystem) {
        Remove-Item Env:\MSYSTEM -ErrorAction SilentlyContinue
    } else {
        $env:MSYSTEM = $previousMSystem
    }
}
