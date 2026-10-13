# Xray

Xray is managed by `xrayctl` (Linux) and `Xrayctl.cmd` (Windows). State lives in
`~/.config/xray/state.json`; `~/.config/xray/config.json` is generated output —
do not edit it by hand, and chezmoi no longer manages either file.

## First run

If you still have the legacy `~/.config/xray/env` credentials file:

```sh
xrayctl init
```

imports it into `state.json`, seeds the hand-added routing rules, and generates
the config. On a fresh machine:

```sh
xrayctl node add mynode 'vless://uuid@host:443?security=reality&sni=example.com&fp=chrome&pbk=PUBLICKEY&sid=SHORTID&type=tcp&flow=xtls-rprx-vision#mynode'
```

The `#fragment` of the link becomes the tag; explicit flags
(`--address --port --uuid --sni --public-key --short-id`) work too. Only
vless + reality + xtls-rprx-vision is supported.

## Everyday commands

```sh
xrayctl node list
xrayctl node use mynode
xrayctl node set mynode --port 8443
xrayctl node rm mynode

xrayctl route add direct domain:example.com
xrayctl route add proxy geosite:netflix
xrayctl route add block 1.2.3.4
xrayctl route list
xrayctl route rm domain:example.com

xrayctl port set --socks 10808 --tproxy 10800
xrayctl status
xrayctl test
xrayctl restart
```

Custom routes are evaluated before all built-in rules (udp/443 block, google
via the proxy, private/CN direct), so they always win. Matchers use xray
syntax: `domain:`, `geosite:`, `full:`, `regexp:`, `geoip:`, or a bare IP/CIDR.
Mutating commands regenerate the config, validate it with `xray run -test`,
and restart the service when it is running; pass `--no-restart` to skip.

On Windows the same commands work through `Xrayctl.cmd`; `--tproxy` has no
effect there. The Windows service uses NSSM and needs an elevated terminal:

```powershell
Xrayctl.cmd service install
Xrayctl.cmd service status
Xrayctl.cmd service restart
Xrayctl.cmd service uninstall
```

## Transparent proxy (Linux)

Enabled with the `xrayTProxy` chezmoi prompt. `tproxy.sh` redirects marked
traffic to the tproxy inbound and reads its port from
`/usr/local/etc/xray/tproxy.env` (written by `xrayctl port set --tproxy` and
by the setup script).

To run a command outside the transparent proxy (direct connection):

```sh
xrayctl direct curl -s ifconfig.me
```

This requires membership in the `xray_tproxy` group, which the setup script
grants; a re-login is needed before `sg` works. Before re-login,
`sudo -g xray_tproxy <cmd>` works as well.

Waydroid traffic is exempted from the proxy and its DNS queries (waydroid0,
port 53) are redirected to 223.5.5.5, which is reachable directly from CN.

## See also

- [`PROXY`](PROXY.md) for the `set-proxy` environment proxy tool
- [`PACKAGES`](PACKAGES.md) for the `xray` and `nssm` installers
