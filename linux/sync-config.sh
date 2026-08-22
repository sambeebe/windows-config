#!/usr/bin/env bash
#
# Sync Linux configuration files
#
# Copies live config from the system into this repo (under linux/).
# Mirror of the Windows sync-config.ps1, but for Linux dotfiles.
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
#   ./sync-config.sh --agents

set -uo pipefail

# Repo root for the Linux config = directory this script lives in.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="$SCRIPT_DIR"

# Agent configs are shared with Windows, so they live one level up in the repo.
AGENTS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)/agents"

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
        say "$C_GREEN" "  synced: ${src/#$HOME/\~} -> ${dst#$CONFIG_ROOT/}"
    else
        say "$C_RED" "  warning: not found: ${src/#$HOME/\~}"
    fi
}

# ---- section: zsh ---------------------------------------------------
sync_zsh() {
    say "$C_YELLOW" $'\n--- Syncing zsh setup ---'
    local dst="$CONFIG_ROOT/zsh"
    copy_in "$HOME/.zshrc"                 "$dst/.zshrc"
    copy_in "$HOME/.config/starship.toml"  "$dst/starship.toml"
    copy_in "$HOME/.config/zsh/README.md"  "$dst/README.md"
    # Optional machine-specific overrides — only present on some machines.
    [[ -e "$HOME/.zshrc.local" ]] && copy_in "$HOME/.zshrc.local" "$dst/.zshrc.local"
}

# ---- section: wezterm -----------------------------------------------
sync_wezterm() {
    say "$C_YELLOW" $'\n--- Syncing wezterm setup ---'
    local dst="$CONFIG_ROOT/wezterm"
    copy_in "$HOME/.config/wezterm/wezterm.lua" "$dst/wezterm.lua"
}

# ---- section: agent configs -----------------------------------------
# Entries come from agents/manifest.txt: <tool>|<path under agents/>|<path under $HOME>
read_agent_manifest() {
    if [[ ! -f "$AGENTS_ROOT/manifest.txt" ]]; then
        say "$C_RED" "  manifest not found: $AGENTS_ROOT/manifest.txt"
        return 1
    fi
    grep -vE '^[[:space:]]*(#|$)' "$AGENTS_ROOT/manifest.txt"
}

# Codex appends a [projects.'<absolute path>'] block per trusted folder. That is
# machine state, not config — useless on another box and it would publish local
# directory names, so keep it out of the repo copy.
strip_codex_projects() {
    awk '
        /^[[:space:]]*\[projects\./ { skip = 1; next }
        /^[[:space:]]*\[/           { skip = 0 }
        skip                        { next }
        { print }
    ' "$1" | cat -s
}

sync_agents() {
    say "$C_YELLOW" $'\n--- Syncing agent configs ---'
    local tool repo_rel home_rel src dst last_tool=''
    while IFS='|' read -r tool repo_rel home_rel; do
        [[ -n "${home_rel:-}" ]] || continue
        if [[ "$tool" != "$last_tool" ]]; then
            say "$C_CYAN" "  $tool"
            last_tool="$tool"
        fi
        src="$HOME/$home_rel"
        dst="$AGENTS_ROOT/$repo_rel"
        if [[ ! -e "$src" ]]; then
            say "$C_CYAN" "    not present, skipped: ~/$home_rel"
            continue
        fi
        mkdir -p "$(dirname "$dst")"
        rm -rf "$dst"
        if [[ "$repo_rel" == "codex/config.toml" ]]; then
            strip_codex_projects "$src" > "$dst"
            say "$C_GREEN" "    synced (trust entries stripped): ~/$home_rel"
        else
            cp -a "$src" "$dst"
            say "$C_GREEN" "    synced: ~/$home_rel"
        fi
    done < <(read_agent_manifest)
}

# ---- argument / menu handling --------------------------------------
DO_ZSH=false
DO_WEZTERM=false
DO_AGENTS=false
DO_ALL=false
ANY_FLAG=false

for arg in "$@"; do
    case "$arg" in
        --all)  DO_ALL=true;  ANY_FLAG=true ;;
        --zsh)  DO_ZSH=true;  ANY_FLAG=true ;;
        --wezterm) DO_WEZTERM=true; ANY_FLAG=true ;;
        --agents)  DO_AGENTS=true;  ANY_FLAG=true ;;
        -h|--help)
            grep -E '^#( |$)' "$0" | sed -E 's/^# ?//'
            exit 0 ;;
        *)
            say "$C_RED" "Unknown option: $arg"
            exit 2 ;;
    esac
done

say "$C_MAGENTA" "=== Linux Configuration Sync ==="

if $DO_ALL; then
    DO_ZSH=true
    DO_WEZTERM=true
    DO_AGENTS=true
elif ! $ANY_FLAG; then
    say "$C_YELLOW" $'\nSelect what to sync:'
    echo "  1) zsh setup (.zshrc, starship.toml, README)"
    echo "  2) wezterm setup (wezterm.lua)"
    echo "  3) agent configs (Claude Code, Codex, opencode)"
    echo "  A) All"
    echo "  Q) Quit"
    printf '%sEnter selection (e.g. '\''1'\'' or '\''A'\''): %s' "$C_CYAN" "$C_RESET"
    read -r choice
    choice="$(echo "${choice:-}" | tr '[:lower:]' '[:upper:]' | tr -d '[:space:]')"

    case "$choice" in
        Q|"") say "$C_YELLOW" "Cancelled."; exit 0 ;;
        A)    DO_ZSH=true; DO_WEZTERM=true; DO_AGENTS=true ;;
        *)
            IFS=',' read -ra parts <<< "$choice"
            for p in "${parts[@]}"; do
                case "$p" in
                    1) DO_ZSH=true ;;
                    2) DO_WEZTERM=true ;;
                    3) DO_AGENTS=true ;;
                    *) say "$C_RED" "Ignoring unknown selection: $p" ;;
                esac
            done ;;
    esac

    if ! $DO_ZSH && ! $DO_WEZTERM && ! $DO_AGENTS; then
        say "$C_YELLOW" "Nothing selected. Cancelled."
        exit 0
    fi
fi

$DO_ZSH && sync_zsh
$DO_WEZTERM && sync_wezterm
$DO_AGENTS && sync_agents

say "$C_MAGENTA" $'\n=== Configuration Sync Complete ==='
say "$C_CYAN" "Synced into: $CONFIG_ROOT"
