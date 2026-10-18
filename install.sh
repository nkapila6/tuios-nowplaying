#!/bin/sh
# symlinks the script and the dock config into tuios, so `git pull` updates them.
#   ./install.sh            install
#   ./install.sh uninstall  remove the links
set -e

dir=$(cd "$(dirname "$0")" && pwd)
tuios="${XDG_CONFIG_HOME:-$HOME/.config}/tuios"

if [ "$1" = "uninstall" ]; then
  rm -f "$tuios/scripts/now-playing" "$tuios/config.d/nowplaying.toml"
  echo "removed. tuios reloads its config on its own."
  exit 0
fi

if [ "$(uname)" != "Darwin" ]; then
  echo "macOS only: media-control reads the macOS Now Playing info." >&2
  exit 1
fi

missing=""
for cmd in media-control jq; do
  PATH="/opt/homebrew/bin:/usr/local/bin:$PATH" command -v "$cmd" >/dev/null || missing="$missing $cmd"
done
if [ -n "$missing" ]; then
  echo "missing:$missing. Install with: brew install$missing" >&2
  exit 1
fi

for f in "$tuios/scripts/now-playing" "$tuios/config.d/nowplaying.toml"; do
  if [ -e "$f" ] && [ ! -L "$f" ]; then
    echo "$f already exists and isn't a link from here. Move it first." >&2
    exit 1
  fi
done

mkdir -p "$tuios/scripts" "$tuios/config.d"
ln -sf "$dir/bin/now-playing" "$tuios/scripts/now-playing"
ln -sf "$dir/nowplaying.toml" "$tuios/config.d/nowplaying.toml"
echo "installed. Play something; it shows up in the middle of the dock."
