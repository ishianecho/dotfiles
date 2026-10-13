# Proxy

Proxy URLs are stored in `~/.config/proxy/config` and applied through
environment variables only: `HTTP_PROXY`, `HTTPS_PROXY`, `ALL_PROXY`,
`NO_PROXY`. No per-tool configuration is written. SSH uses the managed
`proxy ssh` helper.

The `proxy` command is a Go binary from
[ishianecho/bin](https://github.com/ishianecho/bin), installed into
`~/.local/bin` through `.chezmoiexternal` from the latest release.

## Commands

```sh
proxy set http://127.0.0.1:10808 socks5://127.0.0.1:10808
proxy set --http http://127.0.0.1:10808 --socks socks5://127.0.0.1:10808 \
  --no-proxy "localhost,127.0.0.1,::1,.internal"
proxy show
proxy sync
proxy clear
```

Windows: `proxy.exe` with the same subcommands.

Passing only `--http` (or only `--socks`) to `proxy set` merges with the
saved configuration; `proxy clear` removes everything.

Before the first apply, run `proxy` from a checkout of
[ishianecho/bin](https://github.com/ishianecho/bin) (for example
`cd ~/src/bin && go run ./cmd/proxy set ...`); the binary itself is only
installed into `~/.local/bin` during the apply. The `dots`/`Dots`
entrypoints also accept proxy arguments:

```sh
dots proxy http://127.0.0.1:10808 socks5://127.0.0.1:10808
dots init --proxy http://127.0.0.1:10808 --socks socks5://127.0.0.1:10808
dots apply --clear-proxy
```

Shell wrapper functions for `dots`, `xrayctl`, and `proxy` re-apply the
saved configuration to the current shell after each run.

Transparent proxying (see [`XRAY`](XRAY.md)) covers tools that ignore the
environment.
