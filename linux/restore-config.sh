#!/usr/bin/env bash
#
# Restore Linux configuration files from this repo to their system locations
#
# Reverse of sync-config.sh: copies config from this repo (under linux/) back
# out to their live system locations. Mirror of the Windows restore-config.ps1.
#
# Existing files are backed up to <file>.bak.YYYYMMDDHHMMSS before being
# overwritten, unless the content is already identical.
#
# The zsh section also installs what the config needs to actually work: the
# plugins .zshrc sources, and the starship prompt binary. Anything it cannot
# install itself (system packages, login shell) is reported at the end.
#
# By default shows an interactive menu to pick which sections to restore. Use
# --all to restore everything non-interactively, or pass any combination of
# section flags (e.g. --zsh) to restore specific sections.
#
# Usage:
#   ./restore-config.sh
#   ./restore-config.sh --all
#   ./restore-config.sh --zsh
#   ./restore-config.sh --wezterm
#   ./restore-config.sh --agents
#   ./restore-config.sh --zsh --no-install   # copy config only, skip installs

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

# ---- copy helper: repo -> live (with backup) -----------------------
# copy_out <repo_source> <live_target>
copy_out() {
    local src="$1" dst="$2"
    if [[ ! -e "$src" ]]; then
        say "$C_RED" "  warning: not in repo: ${src#$CONFIG_ROOT/}"
        return
    fi
    if [[ -e "$dst" ]] && cmp -s "$src" "$dst"; then
        say "$C_CYAN" "  unchanged: ${dst/#$HOME/\~}"
        return
    fi
    mkdir -p "$(dirname "$dst")"
    if [[ -e "$dst" ]]; then
        local backup="$dst.bak.$(date +%Y%m%d%H%M%S)"
        cp -f "$dst" "$backup"
        say "$C_YELLOW" "  backed up: ${dst/#$HOME/\~} -> ${backup/#$HOME/\~}"
    fi
    cp -f "$src" "$dst"
    say "$C_GREEN" "  restored: ${src#$CONFIG_ROOT/} -> ${dst/#$HOME/\~}"
}

# ---- section: zsh ---------------------------------------------------

# Plugins sourced by .zshrc. Keep in sync with its "Plugins" block — a plugin
# missing here is silently skipped at startup rather than erroring, so a new
# machine would come up subtly degraded instead of visibly broken.
ZSH_PLUGIN_REPOS=(
    "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions"
    "fast-syntax-highlighting|https://github.com/zdharma-continuum/fast-syntax-highlighting"
    "zsh-shift-select|https://github.com/jirutka/zsh-shift-select"
)

# Tools the config calls. Required ones gate a headline feature; optional ones
# are all guarded by `command -v` in .zshrc and degrade to a sane fallback.
ZSH_TOOLS_REQUIRED=("zsh|zsh" "git|git" "fzf|fzf" "zoxide|zoxide" "nvim|neovim")
ZSH_TOOLS_OPTIONAL=(
    "fd|fd-find" "yazi|yazi" "eza|eza" "bat|bat" "rg|ripgrep"
    "wl-copy|wl-clipboard" "xclip|xclip" "xsel|xsel" "xdotool|xdotool"
)

install_zsh_plugins() {
    local dir="$HOME/.local/share/zsh/plugins"
    if ! command -v git >/dev/null 2>&1; then
        say "$C_RED" "  error: git not found — cannot install plugins"
        return
    fi
    mkdir -p "$dir"
    local entry name url dest
    for entry in "${ZSH_PLUGIN_REPOS[@]}"; do
        name="${entry%%|*}"; url="${entry#*|}"; dest="$dir/$name"
        if [[ -d "$dest/.git" ]]; then
            say "$C_CYAN" "  present: $name ($(git -C "$dest" rev-parse --short HEAD))"
        elif git clone --depth 1 "$url" "$dest" >/dev/null 2>&1; then
            say "$C_GREEN" "  installed: $name ($(git -C "$dest" rev-parse --short HEAD))"
        else
            say "$C_RED" "  failed to clone $name from $url"
        fi
    done
}

install_starship() {
    if command -v starship >/dev/null 2>&1; then
        say "$C_CYAN" "  present: $(starship --version | head -1)"
        return
    fi
    if ! command -v curl >/dev/null 2>&1; then
        say "$C_RED" "  starship missing and curl unavailable — install curl, then re-run"
        return
    fi
    mkdir -p "$HOME/.local/bin"
    if curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin" >/dev/null 2>&1; then
        say "$C_GREEN" "  installed: starship -> ~/.local/bin"
    else
        say "$C_RED" "  failed: starship install (see https://starship.rs)"
    fi
}

# Report-only: installing system packages needs sudo, which a config-restore
# script has no business taking on its own.
check_zsh_tools() {
    local entry cmd pkg missing_req=() missing_opt=()
    for entry in "${ZSH_TOOLS_REQUIRED[@]}"; do
        cmd="${entry%%|*}"; pkg="${entry#*|}"
        command -v "$cmd" >/dev/null 2>&1 || missing_req+=("$pkg")
    done
    for entry in "${ZSH_TOOLS_OPTIONAL[@]}"; do
        cmd="${entry%%|*}"; pkg="${entry#*|}"
        command -v "$cmd" >/dev/null 2>&1 || missing_opt+=("$pkg")
    done

    if (( ${#missing_req[@]} )); then
        say "$C_RED" "  missing (required): ${missing_req[*]}"
        say "$C_YELLOW" "    sudo dnf install ${missing_req[*]}"
    else
        say "$C_CYAN" "  all required tools present"
    fi
    if (( ${#missing_opt[@]} )); then
        say "$C_YELLOW" "  missing (optional, config falls back): ${missing_opt[*]}"
        say "$C_YELLOW" "    sudo dnf install ${missing_opt[*]}"
    fi

    local shell_path
    shell_path="$(getent passwd "$(id -un)" | cut -d: -f7)"
    if [[ "$shell_path" == */zsh ]]; then
        say "$C_CYAN" "  login shell: $shell_path"
    else
        say "$C_YELLOW" "  login shell is $shell_path — run: chsh -s \"\$(command -v zsh)\""
    fi
}

restore_zsh() {
    say "$C_YELLOW" $'\n--- Restoring zsh setup ---'
    local src="$CONFIG_ROOT/zsh"
    copy_out "$src/.zshrc"        "$HOME/.zshrc"
    copy_out "$src/starship.toml" "$HOME/.config/starship.toml"
    copy_out "$src/README.md"     "$HOME/.config/zsh/README.md"
    # Optional machine-specific overrides — only restore if present in the repo.
    [[ -e "$src/.zshrc.local" ]] && copy_out "$src/.zshrc.local" "$HOME/.zshrc.local"

    if $NO_INSTALL; then
        say "$C_CYAN" "  (--no-install: skipped plugins, starship, and dependency check)"
        return
    fi

    say "$C_YELLOW" $'\n--- zsh plugins ---'
    install_zsh_plugins
    say "$C_YELLOW" $'\n--- starship prompt ---'
    install_starship
    say "$C_YELLOW" $'\n--- dependency check ---'
    check_zsh_tools
}

# ---- section: wezterm -----------------------------------------------

# Report-only, same reasoning as check_zsh_tools: wezterm is a system package
# and installing it needs sudo.
check_wezterm() {
    if command -v wezterm >/dev/null 2>&1; then
        say "$C_CYAN" "  present: $(wezterm --version 2>/dev/null | head -1)"
    else
        say "$C_RED" "  missing: wezterm"
        say "$C_YELLOW" "    sudo dnf install wezterm"
    fi
    # The config pins default_prog to this path, so a missing zsh there means
    # every new window fails to spawn rather than falling back to $SHELL.
    if [[ ! -x /usr/bin/zsh ]]; then
        say "$C_YELLOW" "  /usr/bin/zsh not found — config's default_prog points at it"
    fi
}

restore_wezterm() {
    say "$C_YELLOW" $'\n--- Restoring wezterm setup ---'
    copy_out "$CONFIG_ROOT/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"

    if $NO_INSTALL; then
        say "$C_CYAN" "  (--no-install: skipped dependency check)"
        return
    fi
    say "$C_YELLOW" $'\n--- dependency check ---'
    check_wezterm
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

restore_agents() {
    say "$C_YELLOW" $'\n--- Restoring agent configs ---'
    local tool repo_rel home_rel src dst backup last_tool=''
    while IFS='|' read -r tool repo_rel home_rel; do
        [[ -n "${home_rel:-}" ]] || continue
        if [[ "$tool" != "$last_tool" ]]; then
            say "$C_CYAN" "  $tool"
            last_tool="$tool"
        fi
        src="$AGENTS_ROOT/$repo_rel"
        dst="$HOME/$home_rel"
        if [[ ! -e "$src" ]]; then
            say "$C_CYAN" "    not in repo, skipped: $repo_rel"
            continue
        fi
        if [[ -e "$dst" ]] && diff -rq "$src" "$dst" >/dev/null 2>&1; then
            say "$C_CYAN" "    unchanged: ~/$home_rel"
            continue
        fi
        mkdir -p "$(dirname "$dst")"
        if [[ -e "$dst" ]]; then
            # These files are hand-edited and the live copy can hold machine-specific
            # settings this repo does not track, so never overwrite without a copy.
            backup="$dst.bak.$(date +%Y%m%d%H%M%S)"
            cp -a "$dst" "$backup"
            say "$C_YELLOW" "    backed up: ~/$home_rel -> $(basename "$backup")"
            rm -rf "$dst"
        fi
        cp -a "$src" "$dst"
        say "$C_GREEN" "    restored: ~/$home_rel"
    done < <(read_agent_manifest)
}

# ---- argument / menu handling --------------------------------------
DO_ZSH=false
DO_WEZTERM=false
DO_AGENTS=false
DO_ALL=false
ANY_FLAG=false
NO_INSTALL=false

for arg in "$@"; do
    case "$arg" in
        --all)  DO_ALL=true;  ANY_FLAG=true ;;
        --zsh)  DO_ZSH=true;  ANY_FLAG=true ;;
        --wezterm) DO_WEZTERM=true; ANY_FLAG=true ;;
        --agents)  DO_AGENTS=true;  ANY_FLAG=true ;;
        # Modifier, not a section — on its own it still shows the menu.
        --no-install) NO_INSTALL=true ;;
        -h|--help)
            grep -E '^#( |$)' "$0" | sed -E 's/^# ?//'
            exit 0 ;;
        *)
            say "$C_RED" "Unknown option: $arg"
            exit 2 ;;
    esac
done

say "$C_MAGENTA" "=== Linux Configuration Restore ==="

if $DO_ALL; then
    DO_ZSH=true
    DO_WEZTERM=true
    DO_AGENTS=true
elif ! $ANY_FLAG; then
    say "$C_YELLOW" $'\nSelect what to restore:'
    echo "  1) zsh setup (config, plugins, starship, dependency check)"
    echo "  2) wezterm setup (wezterm.lua, dependency check)"
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

$DO_ZSH && restore_zsh
$DO_WEZTERM && restore_wezterm
$DO_AGENTS && restore_agents

say "$C_MAGENTA" $'\n=== Configuration Restore Complete ==='
say "$C_CYAN" "Restored from: $CONFIG_ROOT"
say "$C_YELLOW" "Open a new shell or run 'source ~/.zshrc' to pick up changes."
