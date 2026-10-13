# Proxy

Custom proxy are configured in `~/.config/proxy/config`

## Before the first apply

From the chezmoi source directory, use `set-proxy`:

```sh
./set-proxy http://127.0.0.1:10808 socks5://127.0.0.1:10808
```

On Windows, use `Set-Proxy.cmd`:

```bat
.\Set-Proxy.cmd http://127.0.0.1:10808 socks5://127.0.0.1:10808
```

Package installers read the resulting configuration directly.

## Entrypoint commands

The proxy command remains available through `dots` and `Dots`:

```sh
dots proxy http://127.0.0.1:10808 socks5://127.0.0.1:10808
dots proxy --show
dots proxy --sync
dots proxy --clear
```

```powershell
Dots proxy http://127.0.0.1:10808 socks5://127.0.0.1:10808
Dots proxy -Show
Dots proxy -Sync
Dots proxy -Clear
```

Proxy options are also accepted after any non-proxy `dots` or `Dots` command and are applied before that command runs:

```sh
dots init --proxy http://127.0.0.1:10808 --socks socks5://127.0.0.1:10808
dots apply --proxy http://127.0.0.1:10808 --socks socks5://127.0.0.1:10808
dots install all --proxy http://127.0.0.1:10808
dots update --clear-proxy
```

```powershell
Dots init --proxy http://127.0.0.1:10808 --socks socks5://127.0.0.1:10808
Dots apply --proxy http://127.0.0.1:10808 --socks socks5://127.0.0.1:10808
Dots install all --proxy http://127.0.0.1:10808
Dots update --clear-proxy
```

## Direct command

After the repository has been applied, use the installed command:

```sh
set-proxy http://127.0.0.1:10808 socks5://127.0.0.1:10808
set-proxy --no-proxy "localhost,127.0.0.1,::1,.internal" \
  --http http://127.0.0.1:10808 \
  --socks socks5://127.0.0.1:10808
set-proxy --show
set-proxy --sync
set-proxy --clear
```

On Windows, use `Set-Proxy.cmd` with the same positional URLs and `-NoProxy`,
`-Show`, `-Sync`, `-Clear`, and `-Help` options.

## Consumers

The command stores the URLs once and applies them through environment
variables only:

- Shell environment: `HTTP_PROXY`, `HTTPS_PROXY`, `ALL_PROXY`, and `NO_PROXY`
  (sourced from `~/.config/proxy/config` by the shell profile on POSIX, set as
  user-level environment variables on Windows)
- SSH: the managed `proxy-ssh` helper used by `.ssh/config`

No per-tool proxy configuration is written. Git, pnpm, npm, and other CLI
tools read the environment variables directly. On Linux, transparent proxying
(see [`XRAY`](XRAY.md)) covers everything else, including tools that ignore the
environment.

To re-apply the saved configuration to the current environment, run:

```sh
set-proxy --sync
```
