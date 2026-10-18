# tuios-nowplaying

What's playing, in the middle of the [tuios](https://tuios.dev) dock. macOS and Linux.

```
⏮  ▂▅▇ Old Skool · Prem Dhillon  ⏭
```

The little equalizer moves while it plays and turns into `⏸` when you pause.

- click the title to play/pause, click `⏮` / `⏭` to skip
- in window mode (`ctrl+b` `esc`): `ctrl+/` play/pause, `ctrl+.` next, `ctrl+,` previous
- from anywhere: `ctrl+b` then `alt+/`, `alt+.`, `alt+,`

The plain `ctrl` keys only work in window mode, so inside a pane they still go to nvim or your shell.

## Where it gets the music from

- **macOS**: the system Now Playing, through [media-control](https://github.com/ungive/media-control), which still works after Apple locked that API down in 15.4. Spotify, Apple Music, YouTube or SoundCloud in a browser, podcasts. Tested on macOS 27.
- **Linux**: MPRIS, through [playerctl](https://github.com/altdesktop/playerctl). Spotify, Firefox, Chromium, VLC, mpv (with mpv-mpris), most desktop players. Needs a D-Bus session, so a normal desktop. Tested on Debian with mpv in a container, not yet on a real desktop.

## Install

Dependencies first:

```sh
brew install media-control jq     # macOS
sudo apt install playerctl        # Debian/Ubuntu (dnf/pacman have it too)
```

Then:

```sh
curl -fsSL https://raw.githubusercontent.com/nkapila6/tuios-nowplaying/main/install.sh | sh
```

It drops two files into your tuios config (`$XDG_CONFIG_HOME/tuios` if you set that):

- `scripts/now-playing`
- `config.d/nowplaying.toml`

tuios picks it up on its own, no restart. Run the same command again to update. It only replaces what changed, the dock restarts onto the new version by itself, and it never touches a file of the same name that it didn't write.

To uninstall:

```sh
curl -fsSL https://raw.githubusercontent.com/nkapila6/tuios-nowplaying/main/install.sh | sh -s uninstall
```

Pin a version with `NOWPLAYING_REF=<tag or branch>` in front of `sh`.

## Tweaks

tuios reads `config.d/` files in name order, then `config.toml` last, so you change things in `config.toml` without touching the installed file:

```toml
# put it on the right instead
[dock]
center = []
right = ["custom/np-prev", "custom/nowplaying", "custom/np-next", "clock"]

# different window-mode keys
[keybindings.window_management]
"command:nowplaying-next" = ["shift+right"]
"command:nowplaying-prev" = ["shift+left"]

# different leader key
[[keybindings.command]]
name = "nowplaying-toggle"
key = "prefix+alt+p"

# or drop one entirely (and set its key under [keybindings.window_management] to [])
[[keybindings.command]]
name = "nowplaying-prev"
disabled = true
```

Environment variables, set wherever tuios starts:

- `NOW_PLAYING_FPS`: equalizer speed, default 5. `0` turns it off.
- `NOW_PLAYING_PLAYER` (Linux): which player to follow, as `playerctl --player` takes it, e.g. `spotify` or `spotify,firefox`. By default playerctl picks the first one it finds.

## Gotchas

- `nowplaying.toml` sets `dock.center`, and the name sorts after `look.toml`, so it wins over whatever a look puts there. If you had something of your own in the centre, add it back in `config.toml`.
- `ctrl+/`, `ctrl+,` and `ctrl+.` need a terminal with the kitty keyboard protocol (Ghostty, kitty, WezTerm, foot, Alacritty). Terminal.app can't send them.
- Some players don't do previous/next. A single YouTube video usually ignores both.
- The cells run where your tuios client runs. Attached to a session on another machine, you still see your local music.
- The cell is hidden when nothing is loaded. If it vanishes while something plays, `tuios list-dock-components` says why, and `tuios refresh-dock custom/nowplaying` brings back one that gave up.
