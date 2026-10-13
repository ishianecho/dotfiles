# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/) for macOS,
Linux/WSL, MSYS2, and Windows.

## Install

Install chezmoi and Git manually.

<details>
<summary>macOS Homebrew</summary>

```sh
brew install chezmoi git
```

</details>

<details>
<summary>macOS (no homebrew)</summary>

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
```

</details>

<details>
<summary>Arch Linux</summary>

```sh
pacman -Sy --needed sudo curl git
useradd -m -G wheel -s /bin/bash <user>
passwd <user>
printf '%%wheel ALL=(ALL:ALL) ALL\n' > /etc/sudoers.d/wheel && chmod 440 /etc/sudoers.d/wheel && visudo -cf /etc/sudoers.d/wheel
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
```

</details>

<details>
<summary>Fedora / RHEL / AlmaLinux</summary>

```sh
dnf install -y curl git
useradd -m -G wheel -s /bin/bash <user>
passwd <user>
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
```

</details>

<details>
<summary>Debian / Ubuntu</summary>

```sh
apt-get update
apt-get install -y curl git
useradd -m -G sudo -s /bin/bash <user>
passwd <user>
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
```

</details>

<details>
<summary>Windows</summary>

```powershell
winget install twpayne.chezmoi
winget install Git.Git
```

</details>

Bootstrap:

```sh
chezmoi init ishianecho
```

## Commands

POSIX:

```sh
dots init
dots update
dots update --init
dots install <target>
```

Windows:

```powershell
.\dots.cmd init
dots update
dots update --init
dots install <target>
dots apply --scoop-prefix D:/Scoop
```

## Features

- Managed packages and runtimes
- PowerShell, Zsh, Bash, MSYS2, and WSL configuration
- Neovim-managed editor configuration
- Automatic font installation
- Optional WSL input-method support
- Private machine-local environment files

See [`PACKAGES.md`](PACKAGES.md) for package groups and installer ordering.

The `proxy`, `xrayctl`, `ghf`, and `updnvim` tools live in
[ishianecho/bin](https://github.com/ishianecho/bin) and are installed into
`~/.local/bin` via `.chezmoiexternal`.

## Notes

- Use `.\dots.cmd` on the first Windows run.
- Configure a proxy with `proxy set` before the first apply when needed.
- The Windows shell is Zsh inside MSYS2 when MSYS2 and Zsh are installed.
- WSL uses mirrored networking.
- Do not commit credentials in `~/.config/env` or `~/.config/env.local.ps1`.

## Managed runtimes

| Runtime | Manager                         | Version    |
| ------- | ------------------------------- | ---------- |
| Go      | mise                            | latest     |
| Java    | mise                            | OpenJDK 21 |
| Lua     | mise, except Windows            | 5.4        |
| Node.js | pnpm runtime                    | 22         |
| Python  | uv                              | 3.13, 3.14 |
| Rust    | rustup                          | stable     |
| LuaJIT  | package manager or source build | 2.1        |
