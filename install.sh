#!/bin/sh
# install or update:
#   curl -fsSL https://raw.githubusercontent.com/nkapila6/tuios-nowplaying/main/install.sh | sh
# uninstall:
#   curl -fsSL https://raw.githubusercontent.com/nkapila6/tuios-nowplaying/main/install.sh | sh -s uninstall
# NOWPLAYING_REF picks a branch or tag (default main). NOWPLAYING_SRC overrides
# the whole base url, e.g. file:///path/to/checkout for testing.
set -eu

src="${NOWPLAYING_SRC:-https://raw.githubusercontent.com/nkapila6/tuios-nowplaying/${NOWPLAYING_REF:-main}}"
tuios="${XDG_CONFIG_HOME:-$HOME/.config}/tuios"
script="$tuios/scripts/now-playing"
conf="$tuios/config.d/nowplaying.toml"

die() { printf 'tuios-nowplaying: %s\n' "$*" >&2; exit 1; }

# never overwrite a file of the same name that someone else wrote
ours() {
  [ ! -e "$1" ] || grep -q "tuios-nowplaying" "$1"
}

if [ "${1:-}" = "uninstall" ]; then
  for f in "$conf" "$script"; do
    ours "$f" || die "$f isn't from tuios-nowplaying, leaving it"
    rm -f "$f"
  done
  echo "removed. tuios reloads its config on its own."
  exit 0
fi

case "$(uname)" in
  Darwin) deps="media-control jq" ;;
  Linux) deps="playerctl" ;;
  *) die "macOS and Linux only." ;;
esac

missing=""
for cmd in $deps; do
  PATH="/opt/homebrew/bin:/usr/local/bin:$PATH" command -v "$cmd" >/dev/null 2>&1 || missing="$missing $cmd"
done
if [ -n "$missing" ]; then
  if [ "$(uname)" = Darwin ]; then how="brew install$missing"
  elif command -v apt-get >/dev/null 2>&1; then how="sudo apt install$missing"
  elif command -v dnf >/dev/null 2>&1; then how="sudo dnf install$missing"
  elif command -v pacman >/dev/null 2>&1; then how="sudo pacman -S$missing"
  else how="your package manager"
  fi
  die "missing:$missing. Install with: $how"
fi

for f in "$script" "$conf"; do
  ours "$f" || die "$f already exists and isn't from tuios-nowplaying. Move it first."
done

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

curl -fsSL "$src/bin/now-playing" -o "$tmp/now-playing" || die "couldn't download the script"
curl -fsSL "$src/nowplaying.toml" -o "$tmp/nowplaying.toml" || die "couldn't download the config"

# fill in the script path, quoted so a home folder with spaces works under sh -c.
# The trailing "# <checksum>" changes the config whenever the script changes,
# which is what makes tuios restart running push cells (refresh-dock doesn't)
esc=$(printf '%s' "$script" | sed 's/[&|\\]/\\&/g')
ver=$(cksum <"$tmp/now-playing" | cut -d' ' -f1)
sed "s|\"@SCRIPT@\([^\"]*\)\"|\"'$esc'\\1 # $ver\"|g" "$tmp/nowplaying.toml" >"$tmp/conf"
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
    changed=1
  fi
}
put "$tmp/now-playing" "$script"
put "$tmp/conf" "$conf"

[ -n "$changed" ] && echo "done. play something and it shows up in the middle of the tuios dock." || echo "already on the latest version."
