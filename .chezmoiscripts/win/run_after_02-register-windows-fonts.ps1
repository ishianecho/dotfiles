$ErrorActionPreference = "Stop"

if (-not $env:LOCALAPPDATA) {
    exit 0
}

$fontDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
if (-not (Test-Path -LiteralPath $fontDir -PathType Container)) {
    exit 0
}

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class FontApi
{
    [DllImport("gdi32.dll", SetLastError = true)]
    public static extern int AddFontResource(string lpFileName);
}
"@

$registryPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
New-Item -Path $registryPath -Force | Out-Null

Get-ChildItem -LiteralPath $fontDir -Filter "*.ttf" -File | ForEach-Object {
    [FontApi]::AddFontResource($_.FullName) | Out-Null
    New-ItemProperty -Path $registryPath -Name ($_.BaseName + " (TrueType)") -Value $_.FullName -PropertyType String -Force | Out-Null
}
