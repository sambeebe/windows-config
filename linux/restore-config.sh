#!/usr/bin/env bash
#
# Restore Linux configuration files from this repo to their system locations
#
# Reverse of sync-config.sh: copies config from this repo back out to their live
# system locations. Mirror of the Windows windows/restore-config.ps1. Linux-only
# config lives under linux/; config shared with Windows (nvim, mpv, opencode,
# packages.tsv) lives at the repo root.
#
# Existing files are backed up to <file>.bak.YYYYMMDDHHMMSS before being
# overwritten, unless the content is already identical.
#
# The packages section installs everything in packages.tsv that has a Linux
# package or installer, using dnf (Fedora, RHEL + EPEL) or apt (Ubuntu, Debian).
# It asks for your sudo password once; tools not in the distro repos are
# installed per-user under ~/.local without sudo.
#
# By default shows an interactive menu to pick which sections to restore. Use
# --all to restore everything non-interactively, or pass any combination of
# section flags (e.g. --zsh) to restore specific sections.
#
# Usage:
#   ./restore-config.sh
#   ./restore-config.sh --all
#   ./restore-config.sh --packages
#   ./restore-config.sh --zsh
#   ./restore-config.sh --wezterm
#   ./restore-config.sh --nvim
#   ./restore-config.sh --mpv
#   ./restore-config.sh --fonts
#   ./restore-config.sh --opencode
#   ./restore-config.sh --zsh --no-install   # copy config only, skip installs

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

# ---- copy helper: repo -> live (with backup) -----------------------
# copy_out <repo_source> <live_target>
copy_out() {
    local src="$1" dst="$2"
    if [[ ! -e "$src" ]]; then
        say "$C_RED" "  warning: not in repo: ${src#$REPO_ROOT/}"
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
    say "$C_GREEN" "  restored: ${src#$REPO_ROOT/} -> ${dst/#$HOME/\~}"
}

# copy_tree_out <repo_dir> <live_dir> — copy_out every file under repo_dir.
# Files only present locally are left alone; restore never deletes.
copy_tree_out() {
    local src="$1" dst="$2" f
    if [[ ! -d "$src" ]]; then
        say "$C_RED" "  warning: not in repo: ${src#$REPO_ROOT/}/"
        return
    fi
    while IFS= read -r f; do
        copy_out "$src/$f" "$dst/$f"
    done < <(cd "$src" && find . -type f ! -name '*.bak.*' | sed 's|^\./||' | sort)
}

have() { command -v "$1" >/dev/null 2>&1; }

# ---- section: packages ----------------------------------------------
# Rows come from packages.tsv, shared with windows/restore-config.ps1.

PKG_MGR=""      # dnf | apt
DISTRO_RHEL=false

detect_distro() {
    local id="" id_like=""
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        id="$(. /etc/os-release; echo "${ID:-}")"
        id_like="$(. /etc/os-release; echo "${ID_LIKE:-}")"
    fi
    case " $id $id_like " in
        *" fedora "*) PKG_MGR=dnf ;;
        *" rhel "*|*" centos "*) PKG_MGR=dnf; DISTRO_RHEL=true ;;
        *" ubuntu "*|*" debian "*) PKG_MGR=apt ;;
    esac
    # Fedora's ID_LIKE is empty, but RHEL-likes list "fedora" too — RHEL wins.
    [[ " $id $id_like " == *" rhel "* ]] && DISTRO_RHEL=true
    if [[ -z "$PKG_MGR" ]]; then
        have dnf && PKG_MGR=dnf
        have apt-get && PKG_MGR=apt
    fi
    say "$C_CYAN" "  distro: ${id:-unknown} (${PKG_MGR:-no supported package manager}$($DISTRO_RHEL && echo ', RHEL family'))"
}

# Tools the zsh config expects under these names; Ubuntu ships them renamed.
link_debian_renames() {
    local pair from to
    for pair in "fdfind:fd" "batcat:bat"; do
        from="${pair%%:*}"; to="${pair#*:}"
        if have "$from" && ! have "$to"; then
            mkdir -p "$HOME/.local/bin"
            ln -sf "$(command -v "$from")" "$HOME/.local/bin/$to"
            say "$C_GREEN" "  linked: ~/.local/bin/$to -> $from"
        fi
    done
}

# Most of fzf/zoxide/ripgrep/bat/fd/neovim are only in EPEL on RHEL.
ensure_epel() {
    if rpm -q epel-release >/dev/null 2>&1; then
        say "$C_CYAN" "  present: EPEL"
        return
    fi
    local major
    major="$(rpm -E %rhel)"
    say "$C_CYAN" "  enabling EPEL $major"
    sudo dnf install -y "https://dl.fedoraproject.org/pub/epel/epel-release-latest-$major.noarch.rpm" \
        && say "$C_GREEN" "  installed: epel-release" \
        || say "$C_RED" "  failed: epel-release (EPEL-only packages below will fail too)"
}

# One package (or space-separated group) per call, so a name missing from
# this distro's repos fails on its own instead of aborting the whole batch.
install_system_pkgs() {
    local group
    for group in "$@"; do
        # shellcheck disable=SC2086
        if [[ "$PKG_MGR" == dnf ]]; then
            sudo dnf install -y $group >/dev/null 2>&1
        else
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y $group >/dev/null 2>&1
        fi && say "$C_GREEN" "  installed: $group" \
           || say "$C_RED" "  failed: $group (not in this distro's enabled repos?)"
    done
}

linux_arch() {
    case "$(uname -m)" in
        x86_64)        echo x86_64 ;;
        aarch64|arm64) echo arm64 ;;
        *)             uname -m ;;
    esac
}

# Exact version from GitHub releases into ~/.local/opt, linked into ~/.local/bin.
install_nvim_release() {
    local version="$1" arch tmp dest
    arch="$(linux_arch)"
    dest="$HOME/.local/opt/nvim-$version"
    tmp="$(mktemp -d)"
    if curl -fsSL "https://github.com/neovim/neovim/releases/download/v$version/nvim-linux-$arch.tar.gz" \
            | tar -xz -C "$tmp"; then
        rm -rf "$dest"
        mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
        mv "$tmp/nvim-linux-$arch" "$dest"
        ln -sfn "$dest/bin/nvim" "$HOME/.local/bin/nvim"
        say "$C_GREEN" "  installed: Neovim $version -> ${dest/#$HOME/\~}"
    else
        say "$C_RED" "  failed: Neovim $version download"
    fi
    rm -rf "$tmp"
}

install_awscli_zip() {
    local arch tmp
    arch="$(uname -m)"   # AWS names them x86_64 / aarch64
    tmp="$(mktemp -d)"
    if curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-$arch.zip" -o "$tmp/awscli.zip" \
            && unzip -q "$tmp/awscli.zip" -d "$tmp" \
            && "$tmp/aws/install" -i "$HOME/.local/aws-cli" -b "$HOME/.local/bin" --update >/dev/null; then
        say "$C_GREEN" "  installed: AWS CLI -> ~/.local/bin/aws"
    else
        say "$C_RED" "  failed: AWS CLI (needs curl and unzip)"
    fi
    rm -rf "$tmp"
}

# run_custom_installer <key> <name> <version>
run_custom_installer() {
    local key="$1" name="$2" version="$3"
    local url
    case "$key" in
        nvim-release) install_nvim_release "$version"; return ;;
        awscli-zip)   install_awscli_zip; return ;;
        # Official installers; both put the binary under ~ (already on PATH in .zshrc).
        opencode-script) url=https://opencode.ai/install ;;
        claude-script)   url=https://claude.ai/install.sh ;;
        *) say "$C_RED" "  unknown installer '$key' for $name in packages.tsv"; return ;;
    esac
    if curl -fsSL "$url" | bash >/dev/null 2>&1; then
        say "$C_GREEN" "  installed: $name"
    else
        say "$C_RED" "  failed: $name ($url)"
    fi
}

restore_packages() {
    say "$C_YELLOW" $'\n--- Installing packages (packages.tsv) ---'
    local manifest="$REPO_ROOT/packages.tsv"
    if [[ ! -r "$manifest" ]]; then
        say "$C_RED" "  warning: not in repo: packages.tsv"
        return
    fi
    detect_distro
    if [[ -z "$PKG_MGR" ]]; then
        say "$C_RED" "  no dnf or apt found — only the per-user installers will run"
    fi

    local name check version winget dnf apt linux pkg cmd found have_ver
    local system_pkgs=() custom=() unavailable=()
    while IFS=$'\t' read -r name check version winget dnf apt linux; do
        [[ -z "$name" || "$name" == \#* || "$name" == name ]] && continue
        [[ "$PKG_MGR" == dnf ]] && pkg="$dnf" || pkg="$apt"
        # Windows-only rows.
        [[ "$dnf" == - && "$apt" == - && "$linux" == - ]] && continue

        found=""
        IFS=',' read -ra cmds <<< "$check"
        for cmd in "${cmds[@]}"; do
            if have "$cmd"; then found="$cmd"; break; fi
        done
        if [[ -n "$found" ]]; then
            if [[ "$version" != - ]]; then
                have_ver="$("$found" --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
                if [[ -n "$have_ver" && "$have_ver" != "$version" ]]; then
                    say "$C_YELLOW" "  $name $have_ver is installed, but $version is wanted. Uninstall it and re-run to get $version."
                    continue
                fi
            fi
            say "$C_CYAN" "  present: $name"
        elif [[ "$linux" != - ]]; then
            custom+=("$linux|$name|$version")
        elif [[ -n "$PKG_MGR" && "$pkg" != - ]]; then
            system_pkgs+=("$pkg")
        else
            unavailable+=("$name")
        fi
    done < "$manifest"

    if (( ${#system_pkgs[@]} )); then
        say "$C_YELLOW" "  installing with $PKG_MGR (sudo): ${system_pkgs[*]}"
        if sudo -v; then
            $DISTRO_RHEL && ensure_epel
            [[ "$PKG_MGR" == apt ]] && { sudo apt-get update >/dev/null 2>&1 || say "$C_RED" "  apt-get update failed"; }
            install_system_pkgs "${system_pkgs[@]}"
        else
            say "$C_RED" "  sudo refused — skipped: ${system_pkgs[*]}"
        fi
    fi
    [[ "$PKG_MGR" == apt ]] && link_debian_renames

    local entry
    for entry in "${custom[@]}"; do
        IFS='|' read -r linux name version <<< "$entry"
        say "$C_CYAN" "  installing: $name"
        run_custom_installer "$linux" "$name" "$version"
    done

    if (( ${#unavailable[@]} )); then
        say "$C_YELLOW" "  no $PKG_MGR package listed, install by hand: ${unavailable[*]}"
    fi
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

install_zsh_plugins() {
    local dir="$HOME/.local/share/zsh/plugins"
    if ! have git; then
        say "$C_RED" "  error: git not found — cannot install plugins (run --packages first)"
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
    if have starship; then
        say "$C_CYAN" "  present: $(starship --version | head -1)"
        return
    fi
    if ! have curl; then
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

check_login_shell() {
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
    copy_out "$src/starship.toml" "$XDG_CONFIG/starship.toml"
    copy_out "$src/README.md"     "$XDG_CONFIG/zsh/README.md"
    # Optional machine-specific overrides — only restore if present in the repo.
    [[ -e "$src/.zshrc.local" ]] && copy_out "$src/.zshrc.local" "$HOME/.zshrc.local"

    if $NO_INSTALL; then
        say "$C_CYAN" "  (--no-install: skipped plugins and starship)"
        return
    fi

    say "$C_YELLOW" $'\n--- zsh plugins ---'
    install_zsh_plugins
    say "$C_YELLOW" $'\n--- starship prompt ---'
    install_starship
    say "$C_YELLOW" $'\n--- login shell ---'
    check_login_shell
}

# ---- section: wezterm -----------------------------------------------

restore_wezterm() {
    say "$C_YELLOW" $'\n--- Restoring wezterm setup ---'
    copy_out "$CONFIG_ROOT/wezterm/wezterm.lua" "$XDG_CONFIG/wezterm/wezterm.lua"
    # The config pins default_prog to this path, so a missing zsh there means
    # every new window fails to spawn rather than falling back to $SHELL.
    if [[ ! -x /usr/bin/zsh ]]; then
        say "$C_YELLOW" "  /usr/bin/zsh not found — config's default_prog points at it"
    fi
}

# ---- section: nvim (shared with Windows) ----------------------------

restore_nvim() {
    say "$C_YELLOW" $'\n--- Restoring Neovim config ---'
    copy_out      "$REPO_ROOT/nvim/init.lua" "$XDG_CONFIG/nvim/init.lua"
    copy_tree_out "$REPO_ROOT/nvim/lua"      "$XDG_CONFIG/nvim/lua"
}

# ---- section: mpv (shared with Windows) -----------------------------

restore_mpv() {
    say "$C_YELLOW" $'\n--- Restoring mpv config ---'
    copy_out      "$REPO_ROOT/mpv/mpv.conf"   "$XDG_CONFIG/mpv/mpv.conf"
    copy_out      "$REPO_ROOT/mpv/input.conf" "$XDG_CONFIG/mpv/input.conf"
    copy_tree_out "$REPO_ROOT/mpv/scripts"    "$XDG_CONFIG/mpv/scripts"
}

# ---- section: fonts (same font as Windows) --------------------------

restore_fonts() {
    say "$C_YELLOW" $'\n--- Installing Nerd Fonts ---'
    local dir="$HOME/.local/share/fonts/CaskaydiaMono"
    if compgen -G "$dir/*.ttf" >/dev/null; then
        say "$C_CYAN" "  present: CaskaydiaMono Nerd Font"
        return
    fi
    if ! have curl || ! have unzip; then
        say "$C_RED" "  needs curl and unzip (run --packages first)"
        return
    fi
    local tmp
    tmp="$(mktemp -d)"
    if curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaMono.zip -o "$tmp/font.zip" \
            && mkdir -p "$dir" && unzip -qo "$tmp/font.zip" '*.ttf' -d "$dir"; then
        have fc-cache && fc-cache -f "$dir" >/dev/null 2>&1
        say "$C_GREEN" "  installed: CaskaydiaMono Nerd Font -> ${dir/#$HOME/\~}"
    else
        say "$C_RED" "  failed: CaskaydiaMono Nerd Font download"
    fi
    rm -rf "$tmp"
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

restore_opencode() {
    say "$C_YELLOW" $'\n--- Restoring opencode config ---'
    if [[ ! -d "$OPENCODE_REPO" ]]; then
        say "$C_RED" "  warning: not in repo: opencode/"
        return
    fi
    # Files only present locally are left alone; restore never deletes.
    local f
    while IFS= read -r f; do
        copy_out "$OPENCODE_REPO/$f" "$OPENCODE_LIVE/$f"
    done < <(opencode_files "$OPENCODE_REPO")

    have opencode || say "$C_YELLOW" "  opencode is not installed — run --packages"
}

# ---- argument / menu handling --------------------------------------
SECTIONS=(packages zsh wezterm nvim mpv fonts opencode)
declare -A DO=()
ANY_FLAG=false
NO_INSTALL=false

for arg in "$@"; do
    case "$arg" in
        --all) for s in "${SECTIONS[@]}"; do DO[$s]=true; done; ANY_FLAG=true ;;
        --packages|--zsh|--wezterm|--nvim|--mpv|--fonts|--opencode)
            DO[${arg#--}]=true; ANY_FLAG=true ;;
        # Modifier, not a section — on its own it still shows the menu.
        # Skips the sections whose job is installing software.
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

if ! $ANY_FLAG; then
    say "$C_YELLOW" $'\nSelect what to restore:'
    echo "  1) Packages (everything in packages.tsv for this distro; asks for sudo)"
    echo "  2) zsh setup (config, plugins, starship, login shell check)"
    echo "  3) wezterm config"
    echo "  4) Neovim config"
    echo "  5) mpv config"
    echo "  6) Fonts (CaskaydiaMono Nerd Font)"
    echo "  7) opencode config (~/.config/opencode)"
    echo "  A) All"
    echo "  Q) Quit"
    printf '%sEnter selection (e.g. '\''1,2'\'' or '\''A'\''): %s' "$C_CYAN" "$C_RESET"
    read -r choice
    choice="$(echo "${choice:-}" | tr '[:lower:]' '[:upper:]' | tr -d '[:space:]')"

    case "$choice" in
        Q|"") say "$C_YELLOW" "Cancelled."; exit 0 ;;
        A)    for s in "${SECTIONS[@]}"; do DO[$s]=true; done ;;
        *)
            IFS=',' read -ra parts <<< "$choice"
            for p in "${parts[@]}"; do
                if [[ "$p" =~ ^[1-7]$ ]]; then
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

if $NO_INSTALL; then
    [[ -n "${DO[packages]:-}" ]] && say "$C_CYAN" "(--no-install: skipped packages)"
    [[ -n "${DO[fonts]:-}" ]] && say "$C_CYAN" "(--no-install: skipped fonts)"
    unset 'DO[packages]' 'DO[fonts]'
fi

# Packages first, so later sections find git, curl, etc.
for s in "${SECTIONS[@]}"; do
    [[ -n "${DO[$s]:-}" ]] && "restore_$s"
done

say "$C_MAGENTA" $'\n=== Configuration Restore Complete ==='
say "$C_CYAN" "Restored from: $REPO_ROOT"
say "$C_YELLOW" "Open a new shell or run 'source ~/.zshrc' to pick up changes."
