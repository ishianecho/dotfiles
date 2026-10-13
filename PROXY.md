# Proxy

Proxy URLs are stored in `~/.config/proxy/config` and applied through
environment variables only: `HTTP_PROXY`, `HTTPS_PROXY`, `ALL_PROXY`,
`NO_PROXY`. No per-tool configuration is written. SSH uses the managed
`proxy-ssh` helper.

## Commands

```sh
set-proxy http://127.0.0.1:10808 socks5://127.0.0.1:10808
set-proxy --http http://127.0.0.1:10808 --socks socks5://127.0.0.1:10808 \
  --no-proxy "localhost,127.0.0.1,::1,.internal"
set-proxy --show
set-proxy --sync
set-proxy --clear
```

Windows: `Set-Proxy.cmd` with the same positional URLs and `-NoProxy`,
`-Show`, `-Sync`, `-Clear`, `-Help`.

Passing only `--http` (or only `--socks`) merges with the saved
configuration; `--clear` removes everything.

Before the first apply, run `set-proxy` (or `Set-Proxy.cmd`) from the
chezmoi source directory. The `dots`/`Dots` entrypoints also accept proxy
arguments:

```sh
dots proxy http://127.0.0.1:10808 socks5://127.0.0.1:10808
dots init --proxy http://127.0.0.1:10808 --socks socks5://127.0.0.1:10808
dots apply --clear-proxy
```

Shell wrapper functions for `dots`, `xrayctl`, and `set-proxy` re-apply the
saved configuration to the current shell after each run.

Transparent proxying (see [`XRAY`](XRAY.md)) covers tools that ignore the
environment.
