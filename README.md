# tuios-nowplaying-macos

What's playing on your Mac, in the middle of the [tuios](https://tuios.dev) dock:

```
⏮  ▂▅▇ Old Skool · Prem Dhillon  ⏭
```

Works with anything that shows up in macOS's Now Playing: Spotify, Apple Music, YouTube or SoundCloud in a browser, podcasts. The little equalizer moves while it plays and turns into `⏸` when you pause.

- click the title to play/pause, click `⏮` / `⏭` to skip
- `ctrl+.` next track, `ctrl+,` previous track

macOS only. It reads Now Playing through [media-control](https://github.com/ungive/media-control), which still works after Apple locked that API down in 15.4. Tested on macOS 27.

## Install

```sh
brew install media-control jq
git clone https://github.com/nkapila6/tuios-nowplaying-macos ~/dev/tuios-nowplaying-macos
~/dev/tuios-nowplaying-macos/install.sh
```

`install.sh` symlinks two things, so a `git pull` updates them:

- `bin/now-playing` to `~/.config/tuios/scripts/now-playing`
- `nowplaying.toml` to `~/.config/tuios/config.d/nowplaying.toml`

tuios picks up the config on its own, no restart. `./install.sh uninstall` removes both links.

## Tweaks

Everything lives in `nowplaying.toml`. tuios reads `config.d/` files in name order, then `config.toml` last, so you change things in `config.toml` without touching this repo:

```toml
# put it on the right instead
[dock]
center = []
right = ["custom/np-prev", "custom/nowplaying", "custom/np-next", "clock"]

# different keys
[[keybindings.command]]
name = "nowplaying-next"
key = "alt+]"

# or no key at all
[[keybindings.command]]
name = "nowplaying-prev"
disabled = true
```

`NOW_PLAYING_FPS` sets the equalizer speed (default 5, `0` turns it off). Set it in the environment tuios starts in.

## Gotchas

- `nowplaying.toml` sets `dock.center`, and the name sorts after `look.toml`, so it wins over whatever a look puts there. If you had something of your own in the centre, add it back in `config.toml`.
- `ctrl+,` and `ctrl+.` need a terminal with the kitty keyboard protocol (Ghostty, kitty, WezTerm, foot, Alacritty). Terminal.app can't send them.
- Some players don't do previous/next. A single YouTube video usually ignores both.
- The cell is hidden when nothing is loaded. If it vanishes while something plays, `tuios list-dock-components` says why and `tuios refresh-dock custom/nowplaying` restarts it.
