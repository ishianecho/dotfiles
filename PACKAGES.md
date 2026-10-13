# Package installers

## Features

- POSIX installers: `installers/packages/posix/*.sh`
- Windows installers: `installers/packages/win/*.ps1`
- Platform selection with `.chezmoi.os`
- Linux release selection with `.chezmoi.osRelease.id`
- POSIX package managers: `apt`, `dnf`, `pacman`, and Homebrew on macOS
- Persisted package-group choices with `promptBoolOnce`

## Numbering

| Range | Group |
| ----- | ----- |
| `00-09` | Shell and platform bootstrap |
| `10-29` | Build and base libraries |
| `30-39` | Language runtimes |
| `40-49` | Editor tooling |
| `50-59` | AI tools |
| `60-69` | Command-line utilities |
| `70-79` | Operations tools |
| `80-89` | Terminal applications |
| `90-99` | Input support |
| `g0-g9` | Gaming host libraries |

## Windows

- Packages install through Scoop.
- Default Scoop root: `%USERPROFILE%\scoop`
- Custom Scoop root:

```powershell
Dots apply --scoop-prefix D:/Scoop
```

or:

```powershell
$env:SCOOP_DIR = "D:\Scoop"
.\main.ps1
```

- `00-msys2.ps1` handles MSYS2 packages in one `pacman --needed` transaction.
- AI tools install for both Windows pnpm Node.js and MSYS2 UCRT64 Node.js.
- uv, Python, tools, Cargo, and Rustup use Scoop persisted paths; pnpm lives in `%LOCALAPPDATA%\pnpm`.
- Codex and Claude configuration homes stay under `~/.config`.

## Groups

| Group | Packages |
| ----- | -------- |
| `shell` | POSIX `vim`, `zsh`; Windows MSYS2 + `zsh` |
| `build` | Compilers, MSVC/MinGW on Windows, build tools, and base libraries |
| `runtimes` | `uv`, `mise`, `pnpm` (with `npm` fallback), `luajit`, `rust` |
| `editor` | `nvim`, `tree-sitter` |
| `tools` / `dev` | `7-Zip`, `fzf`, `PSFzf`, `posh-git`, `fd`, `ripgrep`, `gh`, `sqlite3`, `zoxide`, `jq`, `yq`; POSIX clipboard providers `wl-clipboard` (Linux) and `xclip` (WSL); Windows `tree` and `less` through MSYS2 |
| `operations` | `kubectl`, `netcat`, `openssh` (POSIX; Windows uses system OpenSSH); Arch-based Linux additionally installs `paru` (AUR helper) and `xray-bin`; Windows additionally installs `xray` and `nssm` (Xray service wrapper) |
| `ai` | `cc-switch`, `codex`, `claude`, `serena`, `github-mcp-server`, `codegraph`; Windows additionally installs the MSYS2 bundle |
| `terminal` | POSIX `tmux`, `kitty`; Windows MSYS2 `tmux` and Windows Terminal |
| `input` | Linux `fcitx5` with Chinese addons and Rime (`librime`, 白霜拼音); `breeze-cursor-theme` set as the default cursor (Linux) |
| `gaming` | Linux host libraries for Lutris, umu, and Proton: 32-bit and 64-bit Vulkan loaders, 32-bit ALSA/PulseAudio/OpenAL/Mesa, `gamemode`, `libayatana-appindicator` (also used by MaaEnd) |

## Targeted installation

```sh
dots install shell
dots install build
dots install ai
dots install codegraph
```

```powershell
Dots install shell
Dots install build
Dots install ai
Dots install codegraph
```

## Notes

- Package-group prompts default to `true`.
- Use `--promptDefaults` for noninteractive initialization.
- WSL uses mirrored networking.
- Restart WSL after `.wslconfig` changes.
