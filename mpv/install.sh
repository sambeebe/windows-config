#!/usr/bin/env bash
# Symlinks mpv config from this repo into ~/.config/mpv/.
# Assumes mpv is installed via the system package manager (dnf install mpv).
set -euo pipefail

src="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
dest="${XDG_CONFIG_HOME:-$HOME/.config}/mpv"

mkdir -p "$dest"

for item in mpv.conf input.conf scripts; do
    ln -sfn "$src/$item" "$dest/$item"
    echo "  $dest/$item -> $src/$item"
done

echo "Done. Run: mpv --version"
