#!/bin/sh
# install or update:
#   curl -fsSL https://raw.githubusercontent.com/nkapila6/tuios-nowplaying-macos/main/install.sh | sh
# uninstall:
#   curl -fsSL https://raw.githubusercontent.com/nkapila6/tuios-nowplaying-macos/main/install.sh | sh -s uninstall
# NOWPLAYING_REF picks a branch or tag (default main). NOWPLAYING_SRC overrides
# the whole base url, e.g. file:///path/to/checkout for testing.
set -eu

src="${NOWPLAYING_SRC:-https://raw.githubusercontent.com/nkapila6/tuios-nowplaying-macos/${NOWPLAYING_REF:-main}}"
tuios="${XDG_CONFIG_HOME:-$HOME/.config}/tuios"
script="$tuios/scripts/now-playing"
conf="$tuios/config.d/nowplaying.toml"
cells="custom/np-prev custom/nowplaying custom/np-next"

die() { printf 'tuios-nowplaying: %s\n' "$*" >&2; exit 1; }

# never overwrite a file of the same name that someone else wrote
ours() {
  [ ! -e "$1" ] || grep -q "tuios-nowplaying-macos" "$1"
}

if [ "${1:-}" = "uninstall" ]; then
  for f in "$conf" "$script"; do
    ours "$f" || die "$f isn't from tuios-nowplaying-macos, leaving it"
    rm -f "$f"
  done
  echo "removed. tuios reloads its config on its own."
  exit 0
fi

[ "$(uname)" = "Darwin" ] || die "macOS only: media-control reads the macOS Now Playing info."

missing=""
for cmd in media-control jq; do
  PATH="/opt/homebrew/bin:/usr/local/bin:$PATH" command -v "$cmd" >/dev/null 2>&1 || missing="$missing $cmd"
done
[ -z "$missing" ] || die "missing:$missing. Install with: brew install$missing"

for f in "$script" "$conf"; do
  ours "$f" || die "$f already exists and isn't from tuios-nowplaying-macos. Move it first."
done

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

curl -fsSL "$src/bin/now-playing" -o "$tmp/now-playing" || die "couldn't download the script"
curl -fsSL "$src/nowplaying.toml" -o "$tmp/nowplaying.toml" || die "couldn't download the config"

# fill in the script path, quoted so a home folder with spaces works under sh -c
esc=$(printf '%s' "$script" | sed 's/[&|\\]/\\&/g')
sed "s|\"@SCRIPT@|\"'$esc'|g" "$tmp/nowplaying.toml" >"$tmp/conf"
chmod +x "$tmp/now-playing"

mkdir -p "$tuios/scripts" "$tuios/config.d"
changed=""
# replace only what differs, so a rerun with no update doesn't reload tuios
put() {
  if cmp -s "$1" "$2"; then
    echo "  up to date  $2"
  else
    mv -f "$1" "$2"
    echo "  installed   $2"
    changed="$changed $3"
  fi
}
put "$tmp/now-playing" "$script" script
put "$tmp/conf" "$conf" conf

# running cells keep the old script until restarted; a config change restarts them anyway
case "$changed" in
  *script*)
    if command -v tuios >/dev/null 2>&1; then
      for c in $cells; do tuios refresh-dock "$c" >/dev/null 2>&1 || true; done
    fi
    ;;
esac

[ -n "$changed" ] && echo "done. play something and it shows up in the middle of the tuios dock." || echo "already on the latest version."
