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
   forwards the call over Tailscale to atlas (the MacBook), which writes to
   the Mac clipboard.
2. **Open URLs from devbox in the Mac's browser** — lazygit's `o` command,
   `gh pr view --web`, and anything honoring `$BROWSER` now pop a browser tab
   on atlas instead of failing silently on headless devbox.

## Topology

```
           ┌─────────────────────┐               ┌────────────────────┐
           │  devbox (Linux)     │  Tailscale    │  atlas (macOS M1)  │
           │  100.90.74.115      │ ────────────► │  100.81.121.84     │
           │                     │   TCP 2489    │                    │
           │  ~/.local/bin/xclip │               │  lemonade server   │
           │  ~/.local/bin/xsel  │               │  (launchd agent)   │
           │  $BROWSER=          │               │                    │
           │    lemonade-open    │               │  writes to         │
           │                     │               │    pbcopy / open   │
           └─────────────────────┘               └────────────────────┘
```

Port **2489** (lemonade default). Allow-list **`100.64.0.0/10`** — the full
Tailscale CGNAT range, so any of Kevin's tailnet nodes can talk to the server.

## Why no `lemonade.toml` config file

Lemonade reads config via the `monochromegane/conflag` library, which searches
from CWD upward for `lemonade.toml` (like `.editorconfig`). There is no
`$HOME/.config/lemonade.toml` lookup. Running lemonade from outside a dir tree
containing the config means the config is silently ignored. All settings are
therefore baked into either the launchd plist (server) or the client shims
(host/port flags).

## Files managed by chezmoi

| Path | Machine | Purpose |
|---|---|---|
| `~/Library/LaunchAgents/com.lemonade.server.plist` | atlas | launchd agent: starts `lemonade server` at login, keep-alive |
| `~/.local/bin/xclip` | devbox | shim routing `xclip` calls to `lemonade copy`/`paste` |
| `~/.local/bin/xsel` | devbox | symlink to `xclip` (same shim handles both) |
| `~/.local/bin/lemonade-open` | devbox | `$BROWSER` wrapper → `lemonade open` |
| `~/.config/lazygit/config.yml` | both | `os.openLink` routed through lemonade on linux, native `open` on darwin |
| `~/.zshenv` | devbox | exports `BROWSER=$HOME/.local/bin/lemonade-open` |

Chezmoi source locations:

- `dot_local/bin/executable_xclip`
- `dot_local/bin/symlink_xsel` (contents: `xclip`)
- `dot_local/bin/executable_lemonade-open`
- `Library/LaunchAgents/com.lemonade.server.plist.tmpl`
- `dot_config/lazygit/config.yml.tmpl` (custom `[[ ]]` delimiters to preserve lazygit's `{{ }}` syntax)
- `dot_zshenv.tmpl`

Machine targeting is handled via `.chezmoiignore` templating:

```
{{ if ne .chezmoi.os "darwin" -}}
Library/LaunchAgents/com.lemonade.server.plist
{{ end -}}
{{ if ne .chezmoi.os "linux" -}}
.local/bin/xclip
.local/bin/xsel
.local/bin/lemonade-open
{{ end -}}
```

## Installation

### Both machines — install the binary

```bash
# devbox: go already on linuxbrew
go install github.com/lemonade-command/lemonade@latest

# atlas: install go first
brew install go
go install github.com/lemonade-command/lemonade@latest
```

Binary lands at `~/go/bin/lemonade` on both machines. Shims reference this
absolute path, so `~/go/bin` does not need to be on `PATH`.

### Atlas — enable the launchd agent

```bash
chezmoi apply                                      # writes the plist
launchctl bootstrap gui/$(id -u) \
    ~/Library/LaunchAgents/com.lemonade.server.plist
```

Check it's running:

```bash
launchctl list | grep lemonade      # expect: PID  0  com.lemonade.server
lsof -nP -iTCP:2489 -sTCP:LISTEN    # expect: lemonade ... LISTEN
tail ~/Library/Logs/lemonade.log
```

To unload (for debugging):

```bash
launchctl bootout gui/$(id -u) \
    ~/Library/LaunchAgents/com.lemonade.server.plist
```

### Devbox — nothing else needed

`chezmoi apply` drops the shims into `~/.local/bin/` (already first in `PATH`
per `~/.zshenv`), which makes `xclip` and `xsel` resolve to the lemonade shim.

## Testing

**Clipboard** (devbox → atlas):

```bash
echo "hello from devbox" | xclip           # send
xclip -o                                    # read back
```

Then on atlas: `pbpaste` should print `hello from devbox`.

**URL open** (devbox → atlas browser):

```bash
lemonade-open https://example.com
# or:
BROWSER=lemonade-open xdg-open https://example.com  # if xdg-open installed
```

Atlas should pop a browser tab.

**lazysql / lazygit**: just use them. Copy rows from lazysql, press `o` on a
commit in lazygit with an upstream. Both should land on the Mac.

## Security notes

- Lemonade RPC is **plaintext** — Tailscale encrypts it in transit.
- Allow-list `100.64.0.0/10` restricts to the Tailscale tailnet. Nothing on
  public Wi-Fi or LAN outside Tailscale can talk to the server. Verify with
  `nmap -p 2489 <atlas LAN IP>` from a non-tailnet device — should be filtered.
- The `open` subcommand executes `open <url>` on macOS, which can launch any
  registered URL handler (e.g. `slack://`). Anything on the tailnet that can
  reach port 2489 can open arbitrary URLs on atlas. Given Kevin's tailnet
  membership (devbox, iPhone, MacBook only), acceptable risk.
- Clipboard contents cross the wire in both directions — don't use while on
  a shared/untrusted tailnet.

## Gotchas

- **Mosh session line endings**: `--line-ending=lf` is set on the server so
  copied text doesn't get `\r\n` line endings when paste originates from a
  non-Windows client. Leave it on.
- **Binary path drift**: if `go install` installs somewhere other than
  `~/go/bin` (check `go env GOBIN` / `GOPATH`), update the absolute paths in
  `executable_xclip`, `executable_lemonade-open`, and the launchd plist.
- **Lemonade is unmaintained**: last release v1.1.1 (2022), v1.1.2 on latest
  main. Still works. If it ever breaks, `osc` + tmux OSC 52 is the fallback
  for clipboard (no URL-open equivalent).
- **Multiple clients at once**: server is single-threaded RPC, not a concern
  for this setup.

## Related

- Kevin's global instructions: `~/.claude/CLAUDE.md` (Tailscale IPs, device
  roster, mosh setup).
- Tmux config: `~/.config/tmux/tmux.conf` (does NOT use OSC 52 currently,
  clipboard flows through lemonade instead).
