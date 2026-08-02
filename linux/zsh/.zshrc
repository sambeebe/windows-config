# =====================================================================
#  ~/.zshrc — see ~/.config/zsh/README.md
# =====================================================================

# ---- PATH -----------------------------------------------------------
typeset -U path PATH                           # auto-dedupe
path=(
    $HOME/.local/bin
    $HOME/.cargo/bin
    $HOME/.opencode/bin
    $path
)
export PATH

# ---- Editor / pager defaults ---------------------------------------
export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export LESS='-R --mouse --wheel-lines=3'

# ---- History --------------------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY            # all shells see new entries immediately
setopt HIST_IGNORE_ALL_DUPS     # remove older dupes when a newer copy arrives
setopt HIST_IGNORE_SPACE        # entries starting with space aren't recorded
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY              # !! expansion: confirm before running
setopt EXTENDED_HISTORY         # save timestamps

# ---- Directory navigation ------------------------------------------
setopt AUTO_CD                  # `foo/` instead of `cd foo/`
setopt AUTO_PUSHD               # `cd` pushes onto dir stack
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt EXTENDED_GLOB            # **, ~, ^, etc. — see `man zshexpn`

# Match the PowerShell profile's smart cd behavior for a single path:
# files open their parent, and missing paths fall back to an existing parent.
cd() {
    if (( $# != 1 )) || [[ $1 == -* || $1 == +<-> ]]; then
        builtin cd "$@"
        return
    fi

    local target=$1 parent
    if [[ -d $target ]]; then
        builtin cd -- "$target"
    elif [[ -e $target ]]; then
        builtin cd -- "${target:A:h}"
    elif [[ $target == */* ]]; then
        parent=${target:h}
        if [[ -d $parent ]]; then
            builtin cd -- "$parent"
        else
            print -u2 "cd: cannot find path '$target' or its parent directory"
            return 1
        fi
    else
        print -u2 "cd: cannot find path '$target' or its parent directory"
        return 1
    fi
}

# ---- Completion -----------------------------------------------------
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive
zstyle ':completion:*' menu select                          # arrow-key picker
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '[%d]'
setopt COMPLETE_IN_WORD         # complete from cursor, not end of word
setopt ALWAYS_TO_END            # but move cursor to end after completing

# ---- Keymap (emacs-style — the standard) ---------------------------
bindkey -e

# Treat each path component as a word while preserving filenames containing
# dots, hyphens, and underscores.
WORDCHARS=${WORDCHARS//\//}

# Up/Down: prefix-search history (type "git " then ↑ → cycle git commands)
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# Word-wise movement / deletion via Ctrl+arrows and Ctrl+Backspace/Delete
bindkey '^[[1;5D' backward-word        # Ctrl+Left
bindkey '^[[1;5C' forward-word         # Ctrl+Right
bindkey '^[[3;5~' kill-word            # Ctrl+Delete
bindkey '^H'      backward-kill-word   # Ctrl+Backspace
bindkey '^[[3~'   delete-char          # Delete

# Home/End across terminals
bindkey '^[[H'    beginning-of-line
bindkey '^[[F'    end-of-line
bindkey '^[[1~'   beginning-of-line
bindkey '^[[4~'   end-of-line

# Edit current command in $EDITOR — the killer feature for long commands
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# =====================================================================
#  Plugins (install commands in README)
# =====================================================================
ZSH_PLUGINS=$HOME/.local/share/zsh/plugins

# Ghost-text suggestions from history. → or End accepts.
if [[ -r $ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source $ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
fi

# --- Shift-selection: select command-line text like a GUI editor -----
# Engine: jirutka/zsh-shift-select — pure zsh, no binaries.
if [[ -r $ZSH_PLUGINS/zsh-shift-select/zsh-shift-select.plugin.zsh ]]; then
    # Shift+Arrows / Shift+Home / Shift+End / Shift+Ctrl+Arrows = extend the
    # selection. Delete or Backspace (while selecting) = cut. None of these
    # overwrite defaults — zsh leaves the shifted keys unbound.
    source $ZSH_PLUGINS/zsh-shift-select/zsh-shift-select.plugin.zsh

    # Select-all on Ctrl+X Ctrl+A. zsh-shift-select's wrapper invokes the
    # unprefixed widget name, so both widgets must exist.
    select-all() {
        MARK=0
        REGION_ACTIVE=1
        zle end-of-buffer -w
        zle -K shift-select
    }
    zle -N select-all
    zle -N shift-select::select-all shift-select::select-and-invoke
    bindkey -M emacs '^X^A' shift-select::select-all

    # Cut on Ctrl+X while a selection is active (same as Delete/Backspace).
    # Bound only inside the transient shift-select keymap, so the global ^X
    # prefix (your ^X^E = edit-command-line) is left untouched.
    bindkey -M shift-select '^X' shift-select::kill-region

    # Paste from zsh's kill-ring. Ctrl+Y is the stock zsh/Emacs binding; Ctrl+V
    # intentionally overrides zsh's quoted-insert to match Windows paste muscle
    # memory in the command line.
    bindkey -M emacs '^V' yank

    # Undo on Ctrl+Z via zsh's built-in `undo` widget. ZLE leaves ^Z unbound,
    # and job-suspend is unaffected (it only fires while a command is running).
    bindkey -M emacs '^Z' undo
    # Built-in redo is available too — uncomment to put it on Alt+Z:
    # bindkey -M emacs '^[z' redo
fi

# --- System clipboard ------------------------------------------------
# ZLE's kill-ring lives inside the shell — Ctrl+U/Ctrl+X cuts are invisible
# to the desktop. Mirror every kill into the real clipboard so the text can
# be pasted into any other app. wl-copy forks a daemon and returns at once.
# Fired with &! (background + disown): wl-copy takes ~170ms to hand the
# selection to the compositor, which is a visible stall if the widget waits
# for it. Backgrounded it costs ~4ms. Trade-off: holding a kill key on
# autorepeat can let the copies land out of order, so the clipboard ends up
# with one of the last few kills rather than strictly the last. Harmless at
# human speed; not worth a lock.
if (( $+commands[wl-copy] )); then          # Wayland
    _clip_put() { print -rn -- "$1" | wl-copy 2>/dev/null &! }
elif (( $+commands[xclip] )); then          # X11 fallback
    _clip_put() { print -rn -- "$1" | xclip -selection clipboard 2>/dev/null &! }
fi

if (( $+functions[_clip_put] )); then
    # Wrap the kill widgets: run the builtin (.name), then export $CUTBUFFER.
    for _w in kill-whole-line kill-line backward-kill-word kill-word kill-region; do
        eval "clip-$_w() { zle .$_w; _clip_put \"\$CUTBUFFER\" }"
        zle -N clip-$_w
    done
    unset _w
    bindkey -M emacs '^U'      clip-kill-whole-line     # cut whole line
    bindkey -M emacs '^K'      clip-kill-line           # cut to end of line
    bindkey -M emacs '^W'      clip-backward-kill-word
    bindkey -M emacs '^[[3;5~' clip-kill-word           # Ctrl+Delete
    bindkey -M emacs '^H'      clip-backward-kill-word  # Ctrl+Backspace

    # Cutting a shift-select region (Ctrl+X, Delete, Backspace) — redefining
    # the plugin's function is enough, the widget already points at it.
    if (( $+widgets[shift-select::kill-region] )); then
        function shift-select::kill-region() {
            zle kill-region -w
            _clip_put "$CUTBUFFER"
            zle -K main
        }
    fi

    # Copy without cutting: whole line, or the selection if one is active.
    # On ^X^W / ^W, not ^C — ^C is the tty's intr char and raises SIGINT
    # before ZLE ever sees it, so it can't be bound.
    clip-copy-line() {
        if (( REGION_ACTIVE )); then
            zle .copy-region-as-kill
            _clip_put "$CUTBUFFER"
            zle -K main
        else
            _clip_put "$BUFFER"
        fi
    }
    zle -N clip-copy-line
    bindkey -M emacs        '^X^W' clip-copy-line
    bindkey -M shift-select '^W'   clip-copy-line
fi

# Syntax highlighting — must be sourced LAST among plugins.
if [[ -r $ZSH_PLUGINS/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh ]]; then
    source $ZSH_PLUGINS/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
fi

# =====================================================================
#  Tool integrations
# =====================================================================

# fzf: Ctrl+R = fuzzy history, Ctrl+T = fuzzy file insert, Alt+C = fuzzy cd
if command -v fzf >/dev/null 2>&1; then
    if [[ -r /usr/share/fzf/shell/key-bindings.zsh ]]; then
        source /usr/share/fzf/shell/key-bindings.zsh
        [[ -r /usr/share/fzf/shell/completion.zsh ]] && source /usr/share/fzf/shell/completion.zsh
    else
        eval "$(fzf --zsh)" 2>/dev/null
    fi
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
    command -v fd >/dev/null 2>&1 && export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
fi

# zoxide: smart cd. `z foo` jumps to a recently/frequently-used dir.
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# yazi: `yy` changes this shell to Yazi's directory when it exits.
yy() {
    local cwd_file cwd yazi_status
    cwd_file=$(mktemp -t yazi-cwd.XXXXXX) || return 1

    command yazi "$@" --cwd-file="$cwd_file"
    yazi_status=$?

    if cwd=$(<"$cwd_file") && [[ -n $cwd && $cwd != $PWD ]]; then
        builtin cd -- "$cwd"
    fi
    command rm -f -- "$cwd_file"

    return $yazi_status
}

# starship prompt
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# =====================================================================
#  Aliases
# =====================================================================
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --group-directories-first'
    alias ll='eza -lh --group-directories-first --git'
    alias la='eza -lah --group-directories-first --git'
    alias lt='eza --tree --level=2 --group-directories-first'
else
    alias ls='ls --color=auto --group-directories-first'
    alias ll='ls -lh'
    alias la='ls -lah'
fi

command -v bat >/dev/null 2>&1 && alias cat='bat --paging=never --style=plain'

alias grep='grep --color=auto'
alias d='dir -a'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias g='git'
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'

alias nvcon='nvim ~/.config/nvim/init.lua'
alias nvzsh='nvim ~/.zshrc'
alias nvwez='nvim ~/.config/wezterm/wezterm.lua'
alias nvstar='nvim ~/.config/starship.toml'
alias sz='source ~/.zshrc'

alias yolo='claude --dangerously-skip-permissions'
alias kolo='opencode run --dangerously-skip-permissions'
alias codexyolo='codex --dangerously-bypass-approvals-and-sandbox'

serve() { python3 -m http.server 8000; }

# Sound of Sorting project helpers
# Usage: sosb <worktree>  (e.g. sosb kimi, sosb claude)
#        sosr <worktree>  (e.g. sosr kimi, sosr claude)
unfunction sosb 2>/dev/null
sosb() {
  local name="${1:-kimi}"
  local build="/home/squidleader/dev/sort-projects/sos-${name}/sos-mod/build"
  if [[ ! -d "$build" ]]; then
    echo "Build dir not found: $build" >&2
    return 1
  fi
  cd "$build" && make -j$(nproc)
}
unfunction sosr 2>/dev/null
sosr() {
  local name="${1:-kimi}"
  local bin="/home/squidleader/dev/sort-projects/sos-${name}/sos-mod/build/src/sound-of-sorting_artefacts/Sound of Sorting"
  echo "[sosr] running: $bin"
  if [[ ! -x "$bin" ]]; then
    echo "Binary not found: $bin" >&2
    echo "Run: sosb $name" >&2
    return 1
  fi
  "$bin"
}

finder() {
  local dir="${1:-.}"
  dir="$(cd "$dir" && pwd)"

  if pgrep -x nautilus > /dev/null && command -v xdotool > /dev/null; then
    xdotool search --class nautilus windowactivate
    xdotool key ctrl+t
    sleep 0.1
    xdotool type --delay 1 "$dir"
    xdotool key Return
  else
    nautilus "$dir" &> /dev/null &|
  fi
}

nemo-tab() {
  nemo -t . &> /dev/null &|
}

dolphin-tab() {
  dolphin . &> /dev/null &|
}

mspeed() { gsettings set org.gnome.desktop.peripherals.mouse speed "$1"; }
restoggle() { gdisplay res toggle; }
zoom() { gdisplay scale "$1"; }

ggx() { git log --oneline -n "${1:-10}"; }

# c: copy the absolute path of a file/dir (or cwd if no arg) to the clipboard.
# Mirrors the Windows `c` alias (cpath). Uses wl-copy (Wayland), then xclip/xsel (X11).
c() {
  local target="${1:-.}" full
  if ! full="$(realpath -e -- "$target" 2>/dev/null)"; then
    echo "c: no such path: $target" >&2
    return 1
  fi
  if command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$full" | wl-copy
  elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "$full" | xclip -selection clipboard
  elif command -v xsel >/dev/null 2>&1; then
    printf '%s' "$full" | xsel --clipboard --input
  else
    echo "c: no clipboard tool found (install wl-clipboard, xclip, or xsel)" >&2
    return 1
  fi
  echo "Copied: $full"
}

# Local overrides (optional, machine-specific)
[[ -r ~/.zshrc.local ]] && source ~/.zshrc.local
