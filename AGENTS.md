# AGENTS.md

Personal dotfiles (chezmoi) for macOS, Linux/WSL, MSYS2, and Windows.

## Layout

- `.chezmoiscripts/{posix,win}/`: scripts run around apply
- `installers/`: `main.{sh,ps1}`, numbered `packages/{posix,win}/NN-name.*`
  installers, shared `lib/{posix,win}/` helpers, completion seeds
- `private_dot_local/bin/`: `dots` and small Windows helpers
- `dot_termux/`: Termux:Boot script starting the root sing-box tunnel
  (applied on android only, gated by `.chezmoiignore`)
- `private_dot_config/cc-switch/`: saved provider state
- Docs: `README.md` (install), `PACKAGES.md` (installer catalog)

## Externals

`.chezmoiexternal.toml.tmpl` pulls external content on apply: the
`ishian.nvim` git repo and font archives from `ishianecho/assets`. The
`ishianecho/bin` tools are installed by installer packages instead, which
download only missing tools: `69-handy` (`ghf`, `updnvim`, `notify`,
`port`; Windows `updnvim.ps1`) and `77-proxy` (`proxy`, `xrayctl`,
`sbctl` on Linux).

## Conventions

- Linux/Windows pairs stay in sync: `.chezmoiscripts` pairs, installer pairs
- Generated files are never managed, e.g. `~/.config/claude/settings.json`
  (written by cc-switch from the saved seeds)
