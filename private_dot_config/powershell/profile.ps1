$dotfilesEnvironment = Join-Path $env:USERPROFILE ".config\env.ps1"
if (Test-Path -LiteralPath $dotfilesEnvironment -PathType Leaf) {
    . $dotfilesEnvironment
}

if (-not ('WtInput' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class WtInput
{
    [DllImport("user32.dll")]
    private static extern void keybd_event(
        byte virtualKey,
        byte scanCode,
        uint flags,
        UIntPtr extraInfo
    );

    public static void SendShiftedKey(int virtualKey)
    {
        keybd_event(0x10, 0, 0, UIntPtr.Zero);
        keybd_event((byte)virtualKey, 0, 0, UIntPtr.Zero);
        keybd_event((byte)virtualKey, 0, 2, UIntPtr.Zero);
        keybd_event(0x10, 0, 2, UIntPtr.Zero);
    }
}
'@
}

$scoopRoot = if ($env:SCOOP) {
    $env:SCOOP
} elseif ($env:SCOOP_DIR) {
    $env:SCOOP_DIR
} else {
    Join-Path $HOME "scoop"
}
$env:PNPM_HOME = Join-Path $env:LOCALAPPDATA "pnpm"
$env:NPM_CONFIG_USERCONFIG = Join-Path $env:XDG_CONFIG_HOME "npm\npmrc"
$env:NPM_CONFIG_CACHE = Join-Path $env:XDG_CACHE_HOME "npm"
$env:CARGO_HOME = Join-Path $scoopRoot "persist\rustup-msvc\.cargo"
$env:RUSTUP_HOME = Join-Path $scoopRoot "persist\rustup-msvc\.rustup"
$env:UV_CACHE_DIR = Join-Path $scoopRoot "persist\uv\cache"
$env:UV_PYTHON_INSTALL_DIR = Join-Path $scoopRoot "persist\uv\python\versions"
$env:UV_TOOL_BIN_DIR = Join-Path $scoopRoot "persist\uv\tools\shims"
$env:UV_TOOL_DIR = Join-Path $scoopRoot "persist\uv\tools\versions"
$env:Path = @(
    $env:PNPM_HOME,
    (Join-Path $env:PNPM_HOME "bin"),
    (Join-Path $env:CARGO_HOME "bin"),
    $env:UV_TOOL_BIN_DIR,
    $env:Path
) -join [IO.Path]::PathSeparator

$PSStyle.FileInfo.Directory = $PSStyle.Foreground.FromRgb(141, 161, 1)
$PSStyle.FileInfo.Executable = $PSStyle.Foreground.FromRgb(248, 85, 82)
$PSStyle.FileInfo.SymbolicLink = $PSStyle.Foreground.FromRgb(53, 167, 124)
$PSStyle.Formatting.TableHeader = $PSStyle.Foreground.FromRgb(92, 106, 114)
$PSStyle.Formatting.Error = $PSStyle.Foreground.FromRgb(248, 85, 82)
$PSStyle.Formatting.Warning = $PSStyle.Foreground.FromRgb(223, 160, 0)
$PSStyle.Formatting.Verbose = $PSStyle.Foreground.FromRgb(58, 148, 197)
$PSStyle.Formatting.Debug = $PSStyle.Foreground.FromRgb(223, 105, 186)
Set-PSReadLineOption -Colors @{ Default = $PSStyle.Foreground.FromRgb(92, 106, 114) }
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -EditMode Vi

$global:PwshCurrentLocation ??= $PWD.ProviderPath
$global:PwshPreviousLocation ??= $null
if (-not $global:PwshOriginalPrompt) {
    $global:PwshOriginalPrompt = $function:prompt
}

function prompt {
    $currentLocation = $PWD.ProviderPath
    if ($currentLocation -ne $global:PwshCurrentLocation) {
        $global:PwshPreviousLocation = $global:PwshCurrentLocation
        $global:PwshCurrentLocation = $currentLocation
    }
    Write-Host -NoNewline "`e]9;9;$currentLocation`e\"
    & $global:PwshOriginalPrompt
}

function Invoke-WtAction {
    param([Parameter(Mandatory = $true)][string[]]$WtArgs)
    if ($WtArgs[0] -eq "resize-pane") {
        $virtualKey = switch ($WtArgs[2]) {
            "left" { 37 }
            "down" { 40 }
            "up" { 38 }
            "right" { 39 }
            default { throw "Invalid resize direction: $($WtArgs[2])" }
        }
        [WtInput]::SendShiftedKey($virtualKey)
        return
    }
    & wt.exe -w 0 @WtArgs 2>$null
}

function OnViModeChange {
    if ($args[0] -eq 'Command') {
        Write-Host -NoNewline "`e[2 q"
    } else {
        Write-Host -NoNewline "`e[6 q"
    }
}
Set-PSReadLineOption -ViModeIndicator Script -ViModeChangeHandler $Function:OnViModeChange
Write-Host -NoNewline "`e[6 q"

function Save-PwshSession {
    $sessionDirectory = Join-Path $HOME ".config\powershell\sessions"
    $sessionFile = Join-Path $sessionDirectory "last.pwsh-session.json"
    $history = @(Get-History | ForEach-Object { $_.CommandLine })
    New-Item -ItemType Directory -Path $sessionDirectory -Force | Out-Null
    [pscustomobject]@{
        savedAt          = (Get-Date).ToString("o")
        workingDirectory = $PWD.Path
        history          = $history
    } | ConvertTo-Json | Set-Content -Path $sessionFile -Encoding UTF8
    Write-Host "Saved PowerShell session to $sessionFile"
}

function Get-PwshHistoryFilePaths {
    $historyPath = (Get-PSReadLineOption).HistorySavePath
    if (-not (Test-Path -LiteralPath $historyPath -PathType Leaf)) {
        return @()
    }
    $lines = @(Get-Content -LiteralPath $historyPath -Tail 1000)
    if ($lines.Count -eq 0) {
        return @()
    }
    [array]::Reverse($lines)
    $paths = foreach ($line in $lines) {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput(
            $line,
            [ref]$tokens,
            [ref]$errors
        )
        $ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.StringConstantExpressionAst]
            }, $true) | ForEach-Object { $_.Value }
    }
    @(
        $paths |
            Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) } |
            Select-Object -Unique
    )
}

function Invoke-PwshHistoryFilePicker {
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        return
    }
    $paths = @(Get-PwshHistoryFilePaths)
    if ($paths.Count -eq 0) {
        return
    }
    $selected = $paths | & fzf `
        "--prompt=History files> " `
        "--height=40%" `
        "--layout=reverse" `
        "--info=inline"
    if ([string]::IsNullOrWhiteSpace($selected)) {
        return
    }
    $quoted = "'" + $selected.Replace("'", "''") + "'"
    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    if ($line.Length -gt 0 -and
        $cursor -gt 0 -and
        -not [char]::IsWhiteSpace($line[$cursor - 1])) {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert(" $quoted")
    } else {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($quoted)
    }
}

foreach ($viMode in @("Insert", "Command")) {
    Set-PSReadLineKeyHandler -ViMode $viMode -Chord Ctrl+o -Function ClearScreen
}
Set-PSReadLineKeyHandler -Chord Ctrl+y -Function AcceptSuggestion

$wtPaneKeys = @{
    "Ctrl+h"       = @("move-focus", "left")
    "Ctrl+j"       = @("move-focus", "down")
    "Ctrl+k"       = @("move-focus", "up")
    "Ctrl+l"       = @("move-focus", "right")
    "Ctrl+Shift+h" = @("swap-pane", "left")
    "Ctrl+Shift+j" = @("swap-pane", "down")
    "Ctrl+Shift+k" = @("swap-pane", "up")
    "Ctrl+Shift+l" = @("swap-pane", "right")
    "Alt+h"        = @("resize-pane", "-d", "left")
    "Alt+j"        = @("resize-pane", "-d", "down")
    "Alt+k"        = @("resize-pane", "-d", "up")
    "Alt+l"        = @("resize-pane", "-d", "right")
}
foreach ($entry in $wtPaneKeys.GetEnumerator()) {
    $wtArgs = $entry.Value
    foreach ($viMode in @("Insert", "Command")) {
        Set-PSReadLineKeyHandler -ViMode $viMode -Chord $entry.Key -ScriptBlock {
            Invoke-WtAction -WtArgs $wtArgs
        }.GetNewClosure() -BriefDescription "Windows Terminal pane action"
    }
}

Set-PSReadLineKeyHandler -Chord Ctrl+t -ScriptBlock {
    Invoke-PwshHistoryFilePicker
}
Set-PSReadLineKeyHandler -Chord @(
    "Ctrl+Shift+S"
    "Ctrl+b,Ctrl+s"
) -ScriptBlock {
    Save-PwshSession
    [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
} -BriefDescription "Save the current PowerShell session" `
    -Description "Saves the working directory and command history to last.pwsh-session.json."

Set-PSReadLineKeyHandler -ViMode Insert -Chord "j" -ScriptBlock {
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    while ($watch.ElapsedMilliseconds -lt 1000) {
        if ([Console]::KeyAvailable) {
            $nextKey = [Console]::ReadKey($true)
            if ($nextKey.KeyChar -eq "j" -and
                (($nextKey.Modifiers -band [ConsoleModifiers]::Control) -eq 0)) {
                [Microsoft.PowerShell.PSConsoleReadLine]::ViCommandMode()
                return
            }

            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("j")
            if ($nextKey.Key -eq [ConsoleKey]::Backspace -and
                (($nextKey.Modifiers -band [ConsoleModifiers]::Control) -eq 0)) {
                [Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteChar()
                return
            }
            if ($nextKey.Key -eq [ConsoleKey]::C -and
                (($nextKey.Modifiers -band [ConsoleModifiers]::Control) -ne 0)) {
                [Microsoft.PowerShell.PSConsoleReadLine]::CopyOrCancelLine()
                return
            }
            if ((($nextKey.Modifiers -band [ConsoleModifiers]::Control) -eq 0) -and
                -not [char]::IsControl($nextKey.KeyChar)) {
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert($nextKey.KeyChar)
            }
            return
        }

        [System.Threading.Thread]::Sleep(10)
    }

    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("j")
}

Set-PSReadLineKeyHandler -Chord Enter -ScriptBlock {
    param($key, $arg)
    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    $trimmed = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed)) {
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
        return
    }
    if ($trimmed -eq '-') {
        $previousLocation = $global:PwshPreviousLocation
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        if ($previousLocation -and $previousLocation -ne $PWD.ProviderPath) {
            $literalPath = "'" + $previousLocation.Replace("'", "''") + "'"
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("Set-Location -LiteralPath $literalPath")
        }
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
        return
    }
    if ($trimmed -match '\s') {
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
        return
    }
    if (Get-Command -Name $trimmed -ErrorAction SilentlyContinue) {
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
        return
    }
    $path = $trimmed.TrimEnd('\', '/')
    if ([string]::IsNullOrWhiteSpace($path)) {
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
        return
    }
    if ($path.Length -eq 2 -and $path[1] -eq ':') {
        $path += '\'
    }
    if (-not (Test-Path -LiteralPath $path -PathType Container)) {
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
        return
    }
    $resolvedPath = (Resolve-Path -LiteralPath $path).ProviderPath
    $literalPath = "'" + $resolvedPath.Replace("'", "''") + "'"
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("Set-Location -LiteralPath $literalPath")
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

$zoxideCompleter = {
    param($wordToComplete, $commandAst, $cursorPosition)

    $keywords = @()
    $elements = @($commandAst.CommandElements)
    for ($i = 1; $i -lt $elements.Count - 1; $i++) {
        $keywords += $elements[$i].ToString()
    }
    if ($wordToComplete) {
        $keywords += $wordToComplete
    }

    $zoxideMatches = @(& zoxide query --list -- @keywords 2>$null)
    foreach ($zoxideMatch in $zoxideMatches | Select-Object -First 50) {
        [System.Management.Automation.CompletionResult]::new(
            $zoxideMatch,
            $zoxideMatch,
            "ParameterValue",
            $zoxideMatch
        )
    }
}
Register-ArgumentCompleter -Native -CommandName z,zi -ScriptBlock $zoxideCompleter

$scoopCompleter = {
    param($wordToComplete)

    $commands = @(
        "alias", "bucket", "cache", "cat", "checkup", "cleanup", "config", "create",
        "depends", "download", "export", "help", "hold", "home", "import", "info",
        "install", "list", "prefix", "reset", "search", "shim", "status", "unhold",
        "uninstall", "update", "virustotal", "which"
    )
    $commands |
        Where-Object { $_.StartsWith($wordToComplete, [StringComparison]::OrdinalIgnoreCase) } |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, "ParameterValue", "scoop $_")
        }
}
Register-ArgumentCompleter -Native -CommandName scoop -ScriptBlock $scoopCompleter

$pnpmCompleter = {
    param($wordToComplete)

    $commands = @(
        "add", "install", "remove", "unlink", "link", "list", "update", "outdated",
        "exec", "dlx", "run", "test", "config", "store", "cache", "runtime", "setup",
        "env", "self-update"
    )
    $commands |
        Where-Object { $_.StartsWith($wordToComplete, [StringComparison]::OrdinalIgnoreCase) } |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, "ParameterValue", "pnpm $_")
        }
}
Register-ArgumentCompleter -Native -CommandName pnpm -ScriptBlock $pnpmCompleter

function npx {
    param([Parameter(ValueFromRemainingArguments = $true)]$Command)

    if ($Command.Count -gt 0) {
        $bin = Join-Path "node_modules\.bin" $Command[0]
        if ((Test-Path -LiteralPath $bin) -or
            (Test-Path -LiteralPath "$bin.cmd") -or
            (Test-Path -LiteralPath "$bin.ps1")) {
            pnpm exec @Command
            return
        }
    }
    pnpm dlx @Command
}

$dotsCompleter = {
    param($wordToComplete, $commandAst)

    if ($commandAst.CommandElements.Count -ne 3) {
        return
    }
    if ($commandAst.CommandElements[1].ToString() -ne "install") {
        return
    }

    $targets = @(
        "shell", "build", "runtimes", "editor", "tools", "dev", "operations", "ai", "terminal", "all",
        "codex", "claude", "codegraph", "cc-switch", "msys2-ai", "posh-git"
    )
    $targets |
        Where-Object { $_.StartsWith($wordToComplete, [StringComparison]::OrdinalIgnoreCase) } |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, "ParameterValue", "dots install $_")
        }
}
Register-ArgumentCompleter -Native -CommandName dots -ScriptBlock $dotsCompleter

Set-Alias -Name vi -Value nvim
Set-Alias -Name vim -Value nvim
Set-Alias -Name g -Value git

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

if (Get-Command uv -ErrorAction SilentlyContinue) {
    (& uv generate-shell-completion powershell) | Out-String | Invoke-Expression
}

if (Get-Command mise -ErrorAction SilentlyContinue) {
    mise completion powershell | Out-String | Invoke-Expression
}

if (Get-Command gh -ErrorAction SilentlyContinue) {
    Invoke-Expression -Command $(gh completion -s powershell | Out-String)
}

if (Get-Command kubectl -ErrorAction SilentlyContinue) {
    kubectl completion powershell | Out-String | Invoke-Expression
}

if (Get-Command chezmoi -ErrorAction SilentlyContinue) {
    chezmoi completion powershell | Out-String | Invoke-Expression
}

if (Get-Command cc-switch -ErrorAction SilentlyContinue) {
    cc-switch completions powershell | Out-String | Invoke-Expression
}

if (Get-Command codex -ErrorAction SilentlyContinue) {
    codex completion powershell | Out-String | Invoke-Expression
}

if (Get-Module -ListAvailable posh-git) {
    $promptBeforePoshGit = $function:prompt
    Import-Module posh-git
    if ($promptBeforePoshGit) {
        Set-Item -Path function:global:prompt -Value $promptBeforePoshGit
    }
    if (Get-Command Expand-GitCommand -ErrorAction SilentlyContinue) {
        Register-ArgumentCompleter -Native -CommandName g -ScriptBlock {
            param($wordToComplete, $commandAst, $cursorPosition)

            $padLength = $cursorPosition - $commandAst.Extent.StartOffset
            $textToComplete = $commandAst.ToString().
                PadRight($padLength, ' ').
                Substring(0, $padLength) -replace '^g(\s|$)', 'git$1'
            Expand-GitCommand $textToComplete
        }
    }
}

function Expand-UniversalArchive {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Position = 1)]
        [string]$DestinationPath
    )
    $resolvedPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).ProviderPath
    $item = Get-Item -LiteralPath $resolvedPath -ErrorAction Stop
    if (-not $item.PSIsContainer -and $item -isnot [System.IO.FileInfo]) {
        throw "Only files can be extracted: $resolvedPath"
    }
    if ($item.PSIsContainer) {
        throw "Archive path is a directory: $resolvedPath"
    }
    $archiveName = [System.IO.Path]::GetFileName($resolvedPath)
    $archiveStem = [System.IO.Path]::GetFileNameWithoutExtension($archiveName)
    $compoundExtensions = @(
        ".tar.bz2", ".tbz2", ".tar.gz", ".tgz", ".tar.lz", ".tar.lzma",
        ".tar.xz", ".txz", ".tar.zst", ".tzst"
    )
    foreach ($extension in $compoundExtensions) {
        if ($archiveName.EndsWith($extension, [System.StringComparison]::OrdinalIgnoreCase)) {
            $archiveStem = $archiveName.Substring(0, $archiveName.Length - $extension.Length)
            break
        }
    }
    if (-not $PSBoundParameters.ContainsKey("DestinationPath")) {
        $DestinationPath = Join-Path (Split-Path -Parent $resolvedPath) $archiveStem
    }
    $DestinationPath = [System.IO.Path]::GetFullPath($DestinationPath, $PWD.ProviderPath)
    if (Test-Path -LiteralPath $DestinationPath) {
        throw "Destination already exists: $DestinationPath"
    }
    New-Item -ItemType Directory -Path $DestinationPath -ErrorAction Stop | Out-Null
    if ($archiveName.EndsWith(".zip", [System.StringComparison]::OrdinalIgnoreCase)) {
        Expand-Archive -LiteralPath $resolvedPath -DestinationPath $DestinationPath -ErrorAction Stop
        return
    }
    $tarPattern = "\.(tar|tar\.bz2|tbz2|tar\.gz|tgz|tar\.lz|tar\.lzma|tar\.xz|txz|tar\.zst|tzst)$"
    if ($archiveName -match $tarPattern) {
        & tar.exe -xf $resolvedPath -C $DestinationPath
        if ($LASTEXITCODE -ne 0) {
            throw "tar failed with exit code $LASTEXITCODE"
        }
        return
    }
    $sevenZip = Get-Command 7z -ErrorAction SilentlyContinue
    if (-not $sevenZip) {
        throw "Install 7-Zip to extract this archive format: $archiveName"
    }
    & $sevenZip.Source x "-o$DestinationPath" -- $resolvedPath
    if ($LASTEXITCODE -ne 0) {
        throw "7-Zip failed with exit code $LASTEXITCODE"
    }
}
Set-Alias -Name x -Value Expand-UniversalArchive

if (Get-Module -ListAvailable PSFzf) {
    try {
        Import-Module PSFzf -ErrorAction Stop
        Set-PSReadLineKeyHandler -Key Tab -ScriptBlock {
            Invoke-FzfTabCompletion
        }
        Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r'
    } catch {
        Write-Warning "Failed to initialize PSFzf: $($_.Exception.Message)"
    }
}
