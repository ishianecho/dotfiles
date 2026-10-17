# AGENTS.md

Personal dotfiles (chezmoi) for macOS, Linux/WSL, MSYS2, and Windows.

## Layout

- `.chezmoiscripts/{posix,win}/`: scripts run around apply
- `installers/`: `main.{sh,ps1}`, numbered `packages/{posix,win}/NN-name.*`
  installers, shared `lib/{posix,win}/` helpers, completion seeds
- `private_dot_local/bin/`: `dots` and small Windows helpers
- `private_dot_config/cc-switch/`: saved provider state
- Docs: `README.md` (install), `PACKAGES.md` (installer catalog)

## Externals

`.chezmoiexternal.toml.tmpl` pulls external content on apply: the
`ishian.nvim` git repo, font archives from `ishianecho/assets`, and
`ishianecho/bin` downloads into `~/.local/bin` (`ghf`, `updnvim`,
`completion`, `notify`, `port`, `proxy`, `xrayctl`).

## Conventions

- Linux/Windows pairs stay in sync: `.chezmoiscripts` pairs, installer pairs
- Generated files are never managed, e.g. `~/.config/claude/settings.json`
  (written by cc-switch from the saved seeds)
