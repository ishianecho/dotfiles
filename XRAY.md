# Xray

Xray is managed by `xrayctl` (a Go binary, `xrayctl.exe` on Windows). State
lives in `~/.config/xray/state.json`; `~/.config/xray/config.json` is
generated output — do not edit it by hand. The `xrayctl` command lives in
[ishianecho/bin](https://github.com/ishianecho/bin) and is installed into
`~/.local/bin` through `.chezmoiexternal` from the latest release.

## Commands

```sh
xrayctl init
xrayctl node add mynode 'vless://uuid@host:443?security=reality&sni=example.com&fp=chrome&pbk=PUBLICKEY&sid=SHORTID&type=tcp&flow=xtls-rprx-vision#mynode'
xrayctl node list
xrayctl node use mynode
xrayctl node set mynode --port 8443
xrayctl node rm mynode
xrayctl node show [tag]

xrayctl route add direct|proxy|block domain:example.com
xrayctl route add proxy geosite:netflix
xrayctl route add block 1.2.3.4
xrayctl route list
xrayctl route rm <matcher|index>

xrayctl port set --socks 10808 --tproxy 10800
xrayctl status
xrayctl test
xrayctl restart
xrayctl tproxy status
xrayctl direct curl -s ifconfig.me
```

Only vless + reality + xtls-rprx-vision is supported. Custom routes are
evaluated before all built-in rules. Mutating commands regenerate the
config, validate it with `xray run -test`, and restart the service when
running (`--no-restart` skips). When the socks port changes, `proxy set`
is called automatically (see [`PROXY`](PROXY.md)).

## Transparent proxy (Linux)

Enabled with the `xrayTProxy` chezmoi prompt. The tproxy port is read
from `state.json` (`.ports.tproxy`) at runtime.

Interception covers both locally generated traffic (OUTPUT) and anything
traversing the host (PREROUTING: Waydroid, Docker, VMs, containers, LAN
devices). Waydroid gets its own `XRAY_WD` chain; everything else uses
`XRAY`. Bypassed in all chains: private/reserved destinations, bridged
frames, DNS (UDP/TCP 53), and xray's own marked traffic (0xff). fwmark-1
packets are accepted in INPUT (required with default-deny firewalls such
as ufw). Forwarded clients using foreign resolvers bypass the proxy; point
them at a CN-reachable resolver or the host.

`xrayctl direct <cmd>` runs a command outside the transparent proxy; it
needs `xray_tproxy` group membership (granted by the setup script,
re-login required; `sudo -g xray_tproxy <cmd>` works before re-login).

## Windows

Same commands via `xrayctl.exe`; `--tproxy` has no effect. The generated
config includes a `tun` inbound (wintun adapter `XrayTun`) that captures
all traffic system-wide; the socks mixed inbound stays available. Requires
`wintun.dll` next to `xray.exe`. The NSSM service needs an elevated
terminal (`xrayctl service install|uninstall|start|stop|restart|status`).

## See also

- [`PROXY`](PROXY.md) for the `proxy` environment proxy tool
- [`PACKAGES`](PACKAGES.md) for the `xray` and `nssm` installers
