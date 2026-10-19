#!/usr/bin/env bash
#
# Sync Linux configuration files
#
# Copies live config from the system into this repo. Mirror of the Windows
# windows/sync-config.ps1. Linux-only config goes under linux/; config shared
# with Windows (nvim, mpv, opencode) goes to the repo root.
#
# By default shows an interactive menu to pick which sections to sync. Use --all
# to sync everything non-interactively, or pass any combination of section flags
# (e.g. --zsh) to sync specific sections.
#
# Usage:
#   ./sync-config.sh
#   ./sync-config.sh --all
#   ./sync-config.sh --zsh
#   ./sync-config.sh --wezterm
#   ./sync-config.sh --nvim
#   ./sync-config.sh --mpv
#   ./sync-config.sh --opencode

set -uo pipefail

# Linux-only config = directory this script lives in; shared config = repo root.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="$SCRIPT_DIR"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
XDG_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"

# ---- colors ---------------------------------------------------------
if [[ -t 1 ]]; then
    C_MAGENTA=$'\e[35m'; C_YELLOW=$'\e[33m'; C_CYAN=$'\e[36m'
    C_GREEN=$'\e[32m';   C_RED=$'\e[31m';    C_RESET=$'\e[0m'
else
    C_MAGENTA=''; C_YELLOW=''; C_CYAN=''; C_GREEN=''; C_RED=''; C_RESET=''
fi
say()  { printf '%s%s%s\n' "$1" "$2" "$C_RESET"; }

# ---- copy helper: live file -> repo --------------------------------
# copy_in <source> <target>
copy_in() {
    local src="$1" dst="$2"
    if [[ -e "$src" ]]; then
        mkdir -p "$(dirname "$dst")"
        cp -f "$src" "$dst"
        say "$C_GREEN" "  synced: ${src/#$HOME/\~} -> ${dst#$REPO_ROOT/}"
    else
        say "$C_RED" "  warning: not found: ${src/#$HOME/\~}"
    fi
}

# mirror_in <live_dir> <repo_dir> — replace repo_dir with the files under
# live_dir, so files deleted locally disappear from the repo too.
mirror_in() {
    local src="$1" dst="$2" f
    if [[ ! -d "$src" ]]; then
        say "$C_RED" "  warning: not found: ${src/#$HOME/\~}/"
        return
    fi
    rm -rf "$dst"
    while IFS= read -r f; do
        copy_in "$src/$f" "$dst/$f"
    done < <(cd "$src" && find . -type f ! -name '*.bak.*' | sed 's|^\./||' | sort)
}

# ---- section: zsh ---------------------------------------------------
sync_zsh() {
    say "$C_YELLOW" $'\n--- Syncing zsh setup ---'
    local dst="$CONFIG_ROOT/zsh"
    copy_in "$HOME/.zshrc"                 "$dst/.zshrc"
    copy_in "$XDG_CONFIG/starship.toml"    "$dst/starship.toml"
    copy_in "$XDG_CONFIG/zsh/README.md"    "$dst/README.md"
    # Optional machine-specific overrides — only present on some machines.
    [[ -e "$HOME/.zshrc.local" ]] && copy_in "$HOME/.zshrc.local" "$dst/.zshrc.local"
}

# ---- section: wezterm -----------------------------------------------
sync_wezterm() {
    say "$C_YELLOW" $'\n--- Syncing wezterm setup ---'
    copy_in "$XDG_CONFIG/wezterm/wezterm.lua" "$CONFIG_ROOT/wezterm/wezterm.lua"
}

# ---- section: nvim (shared with Windows) ----------------------------
sync_nvim() {
    say "$C_YELLOW" $'\n--- Syncing Neovim config ---'
    copy_in   "$XDG_CONFIG/nvim/init.lua" "$REPO_ROOT/nvim/init.lua"
    mirror_in "$XDG_CONFIG/nvim/lua"      "$REPO_ROOT/nvim/lua"
}

# ---- section: mpv (shared with Windows) -----------------------------
sync_mpv() {
    say "$C_YELLOW" $'\n--- Syncing mpv config ---'
    copy_in   "$XDG_CONFIG/mpv/mpv.conf"   "$REPO_ROOT/mpv/mpv.conf"
    copy_in   "$XDG_CONFIG/mpv/input.conf" "$REPO_ROOT/mpv/input.conf"
    mirror_in "$XDG_CONFIG/mpv/scripts"    "$REPO_ROOT/mpv/scripts"
}

# ---- section: opencode (shared with Windows) ------------------------
OPENCODE_LIVE="$XDG_CONFIG/opencode"
OPENCODE_REPO="$REPO_ROOT/opencode"

# Files under <dir>, relative, minus what opencode regenerates on startup
# (node_modules, lockfiles, its own .gitignore) and restore backups.
opencode_files() {
    (cd "$1" && find . \( -name node_modules -o -name bun.lock -o -name package-lock.json \
        -o -name .gitignore -o -name '*.bak.*' \) -prune -o -type f -print | sed 's|^\./||' | sort)
}

# The repo is public. A provider key written inline (rather than as {env:VAR}
# or {file:path}) must never be copied in.
opencode_secrets() {
    local f
    while IFS= read -r f; do
        [[ "$f" == *.json || "$f" == *.jsonc ]] || continue
        grep -nHEi '"(api_?key|token|secret|password)"[[:space:]]*:[[:space:]]*"[^"{]' "$OPENCODE_LIVE/$f" \
            | cut -d: -f1,2   # file:line only, never echo the value
    done < <(opencode_files "$OPENCODE_LIVE")
}

sync_opencode() {
    say "$C_YELLOW" $'\n--- Syncing opencode config ---'
    if [[ ! -d "$OPENCODE_LIVE" ]]; then
        say "$C_RED" "  warning: not found: ${OPENCODE_LIVE/#$HOME/\~}"
        return
    fi
    local hits
    hits="$(opencode_secrets)"
    if [[ -n "$hits" ]]; then
        say "$C_RED" "  refusing to sync: these lines look like inline secrets (use {env:VAR} instead):"
        say "$C_RED" "${hits//$HOME/\~}"
        return
    fi
    # Mirror, so files deleted locally disappear from the repo too.
    rm -rf "$OPENCODE_REPO"
    local f
    while IFS= read -r f; do
        mkdir -p "$(dirname "$OPENCODE_REPO/$f")"
        cp -f "$OPENCODE_LIVE/$f" "$OPENCODE_REPO/$f"
        say "$C_GREEN" "  synced: ${OPENCODE_LIVE/#$HOME/\~}/$f"
    done < <(opencode_files "$OPENCODE_LIVE")
}

# ---- argument / menu handling --------------------------------------
SECTIONS=(zsh wezterm nvim mpv opencode)
declare -A DO=()
ANY_FLAG=false

for arg in "$@"; do
    case "$arg" in
        --all) for s in "${SECTIONS[@]}"; do DO[$s]=true; done; ANY_FLAG=true ;;
        --zsh|--wezterm|--nvim|--mpv|--opencode)
            DO[${arg#--}]=true; ANY_FLAG=true ;;
        -h|--help)
            grep -E '^#( |$)' "$0" | sed -E 's/^# ?//'
            exit 0 ;;
        *)
            say "$C_RED" "Unknown option: $arg"
            exit 2 ;;
    esac
done

say "$C_MAGENTA" "=== Linux Configuration Sync ==="

if ! $ANY_FLAG; then
    say "$C_YELLOW" $'\nSelect what to sync:'
    echo "  1) zsh setup (.zshrc, starship.toml, README)"
    echo "  2) wezterm setup (wezterm.lua)"
    echo "  3) Neovim config (~/.config/nvim)"
    echo "  4) mpv config (~/.config/mpv)"
    echo "  5) opencode config (~/.config/opencode)"
    echo "  A) All"
    echo "  Q) Quit"
    printf '%sEnter selection (e.g. '\''1,3'\'' or '\''A'\''): %s' "$C_CYAN" "$C_RESET"
    read -r choice
    choice="$(echo "${choice:-}" | tr '[:lower:]' '[:upper:]' | tr -d '[:space:]')"

    case "$choice" in
        Q|"") say "$C_YELLOW" "Cancelled."; exit 0 ;;
        A)    for s in "${SECTIONS[@]}"; do DO[$s]=true; done ;;
        *)
            IFS=',' read -ra parts <<< "$choice"
            for p in "${parts[@]}"; do
                if [[ "$p" =~ ^[1-5]$ ]]; then
                    DO[${SECTIONS[p-1]}]=true
                else
                    say "$C_RED" "Ignoring unknown selection: $p"
                fi
            done ;;
    esac

    if (( ${#DO[@]} == 0 )); then
        say "$C_YELLOW" "Nothing selected. Cancelled."
        exit 0
    fi
fi

for s in "${SECTIONS[@]}"; do
    [[ -n "${DO[$s]:-}" ]] && "sync_$s"
done

say "$C_MAGENTA" $'\n=== Configuration Sync Complete ==='
say "$C_CYAN" "Synced into: $REPO_ROOT"
