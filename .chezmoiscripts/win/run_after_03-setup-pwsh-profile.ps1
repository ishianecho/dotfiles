$profileContent = '. "$HOME\.config\powershell\profile.ps1"'

if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

$currentContent = Get-Content -Path $PROFILE -Raw -ErrorAction SilentlyContinue

if ($currentContent -notmatch [regex]::Escape($profileContent)) {
    Add-Content -Path $PROFILE -Value $profileContent
}

$scoopShims = "$env:USERPROFILE\scoop\shims"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$pathParts = $userPath -split ';' | Where-Object { $_ -ne '' }

if ($pathParts -notcontains $scoopShims) {
    $newPath = @($scoopShims) + $pathParts -join ';'
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
} elseif ($pathParts[0] -ne $scoopShims) {
    $pathParts = $pathParts | Where-Object { $_ -ne $scoopShims }
    $newPath = @($scoopShims) + $pathParts -join ';'
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
}

$miseShims = Join-Path $env:USERPROFILE ".local\share\mise\shims"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$pathParts = $userPath -split ';' | Where-Object { $_ -ne '' }

if ($pathParts -notcontains $miseShims) {
    $newPath = @($miseShims) + $pathParts -join ';'
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
}
