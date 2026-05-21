# Lemonade — Cross-Machine Clipboard & URL Opener

This directory documents Kevin's lemonade setup. No runtime config lives here —
everything is passed via CLI flags (see below for why).

## What it does

[Lemonade](https://github.com/lemonade-command/lemonade) is a small RPC daemon
that lets a remote machine use another machine's clipboard and default browser.
Two problems solved:

1. **Clipboard from headless devbox** — TUIs like `lazysql`, `nvim`, and
   anything using Go's `atotto/clipboard` probe for `xclip` / `xsel`. Devbox
   has no X server, so those tools don't work. A shim named `xclip` on devbox
   forwards the call over Tailscale to sot, which writes to sot's clipboard.
2. **Open URLs from devbox in a real browser** — lazygit's `o` command,
   `gh pr view --web`, `az login`, and anything honoring `$BROWSER` or calling
   `xdg-open` pop a browser tab on sot instead of failing silently on
   headless devbox.

## Topology

Kevin has one workstation (sot, Framework 16 Dec 2025) and one headless dev
server (devbox). Sot runs the lemonade server; devbox has no server, only
client shims. (Atlas, the previous MacBook Pro workstation, was retired in
May 2026 — see `~/.claude/CLAUDE.md`.)

```
   ┌─────────────────────┐                  ┌──────────────────────┐
   │  devbox (Ubuntu)    │   Tailscale      │  sot (Linux)         │
   │  100.90.74.115      │ ───────────────► │  100.72.212.29       │
   │                     │     TCP 2489     │  lemonade server     │
   │  ~/.local/bin/xclip │                  │  (systemd --user)    │
   │  ~/.local/bin/xsel  │                  │                      │
   │  ~/.local/bin/      │                  │  writes to           │
   │    xdg-open         │                  │    wl-copy / xdg-open│
   │  $BROWSER=          │                  │                      │
   │    lemonade-open    │                  │                      │
   └─────────────────────┘                  └──────────────────────┘
```

Port **2489** (lemonade default). Allow-list **`100.64.0.0/10`** — the full
Tailscale CGNAT range, so any of Kevin's tailnet nodes can talk to the server.

### Probe + fail-fast

Each shim does a 1s `bash /dev/tcp` probe against TCP 2489 on sot. If sot
is unreachable, the shim exits non-zero with an error message — no silent
hangs, no fork bombs (lemonade's local-fallback would otherwise recurse
into the `xclip` shim).

### Fire-and-forget URL open

`lemonade-open` wraps the actual `lemonade ... open` call in
`setsid -f timeout 3 ... </dev/null >/dev/null 2>&1` and immediately
`exit 0`s. Rationale: `lemonade open` has been observed to accept the TCP
connection but never ack the RPC, which would hang the calling TUI (lazygit
froze its whole pane this way). Detaching means lazygit / `az login` /
`gh browse` always return instantly. If the open silently fails on sot,
verify the server (see Troubleshooting below).

## Why no `lemonade.toml` config file

Lemonade reads config via the `monochromegane/conflag` library, which searches
from CWD upward for `lemonade.toml` (like `.editorconfig`). There is no
`$HOME/.config/lemonade.toml` lookup. Running lemonade from outside a dir tree
containing the config means the config is silently ignored. All settings are
therefore baked into either the systemd unit (server) or the client shims
(host/port flags).

## Files managed by chezmoi

| Path | Machine | Purpose |
|---|---|---|
| `~/.config/systemd/user/lemonade.service` | sot | systemd --user unit: starts `lemonade server` at login, restart on failure |
| `~/.local/bin/xclip` | devbox | shim routing `xclip` calls to `lemonade copy`/`paste` |
| `~/.local/bin/xsel` | devbox | symlink to `xclip` (same shim handles both) |
| `~/.local/bin/xdg-open` | devbox | overrides `/usr/local/bin/xdg-open` stub; forwards to `lemonade-open` |
| `~/.local/bin/lemonade-open` | devbox | `$BROWSER` wrapper → `lemonade open` (fire-and-forget) |
| `~/.config/lazygit/config.yml` | both | `os.openLink` routed through lemonade on linux, native `open` on darwin |
| `~/.zshenv` | devbox | exports `BROWSER=$HOME/.local/bin/lemonade-open` (gated on `eq .chezmoi.hostname "devbox"`) |

Chezmoi source locations:

- `dot_local/bin/executable_xclip`
- `dot_local/bin/symlink_xsel` (contents: `xclip`)
- `dot_local/bin/executable_xdg-open`
- `dot_local/bin/executable_lemonade-open`
- `dot_config/systemd/user/lemonade.service`
- `dot_config/lazygit/config.yml.tmpl` (custom `[[ ]]` delimiters to preserve lazygit's `{{ }}` syntax)
- `dot_zshenv.tmpl`

The `BROWSER` export is gated by **hostname** (only `devbox`) inside
`dot_zshenv.tmpl`, because sot has a native browser and should not redirect
its own URL opens through lemonade.

## Installation

### Both machines — install the binary

```bash
# devbox: go already on linuxbrew
go install github.com/lemonade-command/lemonade@latest

# sot: go already installed
go install github.com/lemonade-command/lemonade@latest
```

Binary lands at `~/go/bin/lemonade` on both machines. Shims reference this
absolute path, so `~/go/bin` does not need to be on `PATH`.

### Sot — enable the systemd --user unit

```bash
chezmoi apply                                       # writes the unit
systemctl --user daemon-reload
systemctl --user enable --now lemonade.service
```

Check it's running:

```bash
systemctl --user status lemonade.service           # expect: active (running)
ss -ltnp | grep 2489                                # expect: lemonade LISTEN
journalctl --user -u lemonade.service -n 50         # recent logs
```

If sot should serve when Kevin is logged out (rare — it's a workstation):

```bash
loginctl enable-linger kevin
```

### Devbox — nothing else needed

`chezmoi apply` drops the shims into `~/.local/bin/` (already first in `PATH`
per `~/.zshenv`), which makes `xclip`, `xsel`, and `xdg-open` resolve to the
lemonade shims.

## Testing

**Clipboard** (devbox → sot):

```bash
echo "hello from devbox" | xclip           # send
xclip -o                                    # read back
```

Then on sot: `wl-paste` (Wayland) or `xclip -o` (X11) should print
`hello from devbox`.

**URL open** (devbox → sot browser):

```bash
lemonade-open https://example.com
# or:
xdg-open https://example.com
```

Sot should pop a browser tab.

**lazysql / lazygit**: just use them. Copy rows from lazysql, press `o` on a
commit in lazygit with an upstream. Both should land on sot.

## Troubleshooting

When URLs don't open or clipboard doesn't sync:

1. **Sot online?** `tailscale status | grep sot` — must show online (not
   `offline, last seen Xd ago`).
2. **Port reachable?** `nc -zv 100.72.212.29 2489` from devbox.
3. **Server up on sot?** `systemctl --user status lemonade.service` and
   `ss -ltnp | grep 2489`. If port is open but the RPC hangs (client logs
   "Opening ..." but never returns), the server may need a restart:
   `systemctl --user restart lemonade.service`.
4. **End-to-end probe** from devbox:
   `timeout 3 ~/go/bin/lemonade --host=100.72.212.29 open https://example.com`
   — success = browser tab on sot, no `dial tcp ... timeout`, exits 0.

Past incident: lazygit's `Ctrl+o` froze its pane because the shim called
`lemonade open` synchronously and the sot server accepted the connection
but never acked. Mitigated by `setsid -f timeout 3` in `lemonade-open`.

## Security notes

- Lemonade RPC is **plaintext** — Tailscale encrypts it in transit.
- Allow-list `100.64.0.0/10` restricts to the Tailscale tailnet. Nothing on
  public Wi-Fi or LAN outside Tailscale can talk to the server. Verify with
  `nmap -p 2489 <sot LAN IP>` from a non-tailnet device — should be filtered.
- The `open` subcommand executes `xdg-open <url>` on sot, which can launch
  any registered URL handler. Anything on the tailnet that can reach port
  2489 can open arbitrary URLs on sot. Given Kevin's tailnet membership
  (devbox, iPhone, sot only), acceptable risk.
- Clipboard contents cross the wire in both directions — don't use while on
  a shared/untrusted tailnet.

## Gotchas

- **Mosh session line endings**: `--line-ending=lf` is set on the server so
  copied text doesn't get `\r\n` line endings when paste originates from a
  non-Windows client. Leave it on.
- **Binary path drift**: if `go install` installs somewhere other than
  `~/go/bin` (check `go env GOBIN` / `GOPATH`), update the absolute paths in
  `executable_xclip`, `executable_lemonade-open`, and the systemd unit.
- **Lemonade is unmaintained**: last release v1.1.1 (2022), v1.1.2 on latest
  main. Still works. If it ever breaks, `osc` + tmux OSC 52 is the fallback
  for clipboard (no URL-open equivalent).
- **Multiple clients at once**: server is single-threaded RPC, not a concern
  for this setup.
- **`/usr/local/bin/xdg-open`** on devbox is a root-owned stub that just
  echoes "Open this URL manually". The chezmoi-managed
  `~/.local/bin/xdg-open` shadows it via PATH order, so leave the stub alone.

## Related

- Kevin's global instructions: `~/.claude/CLAUDE.md` (Tailscale IPs, device
  roster, mosh setup).
- Tmux config: `~/.config/tmux/tmux.conf` (does NOT use OSC 52 currently,
  clipboard flows through lemonade instead).
