# zsh setup — the Linux way

A clean, modern zsh config: ghost-text suggestions, syntax highlighting, fuzzy history search, smart `cd`, starship prompt. Aimed at someone coming from PowerShell who wants to learn how Linux folks actually use their shell.

## The mental shift from PowerShell

In Windows Terminal + pwsh, the shell tries to feel like a text editor: Shift+arrows select, Ctrl+A select all, Ctrl+C copy. **Linux terminals split those jobs:**

- **The terminal** handles selection and clipboard. In WezTerm: highlight with the mouse, middle-click to paste, **Ctrl+Shift+C / Ctrl+Shift+V** to copy/paste between terminal and other apps.
- **The shell** handles command-line *editing* — moving the cursor, killing words, recalling history. Selection inside the prompt isn't really a thing.
- **Ctrl+C is sacred**: it sends SIGINT to interrupt a running program. Don't try to remap it.

Once you internalize this split, the emacs-style key bindings below feel natural.

## Files

| File | What it is |
|------|------------|
| `~/.zshrc` | Main config |
| `~/.config/starship.toml` | Prompt config |
| `~/.local/share/zsh/plugins/` | Cloned plugin repos |
| `~/.zshrc.local` | Optional machine-specific overrides (auto-sourced if present) |
| `~/.zshrc.pre-revamp.YYYYMMDD` | Backup of your previous config |

## The line-editing keys (memorize these)

These work in zsh, bash, the Python REPL, psql, and anything else using GNU readline. Learn once, use everywhere.

| Key | Action |
|-----|--------|
| `Ctrl+A` | Jump to start of line |
| `Ctrl+E` | Jump to end of line |
| `Alt+B` / `Ctrl+←` | Back one word |
| `Alt+F` / `Ctrl+→` | Forward one word |
| `Ctrl+W` | Delete word or path component back |
| `Alt+D` / `Ctrl+Delete` | Delete word forward |
| `Ctrl+U` | Cut whole line |
| `Ctrl+K` | Cut from cursor to end of line |
| `Ctrl+Y` | Yank back what you just killed (paste-within-shell) |
| `Ctrl+X Ctrl+W` | Copy the line (or the active selection) to the system clipboard, without cutting |
| `Ctrl+L` | Clear screen |
| `Ctrl+R` | Fuzzy history search (fzf) |
| `↑` / `↓` | Prefix-search history — type `git `, then ↑ cycles only git commands |
| `Ctrl+X Ctrl+E` | Open the current command in `$EDITOR`. Save & quit → runs it. **Killer move for long commands.** |

## What the plugins give you

**zsh-autosuggestions** — As you type, faded ghost-text suggests how to complete the command from your history. Press `→` or `End` to accept, `Ctrl+→` to accept one word.

**fast-syntax-highlighting** — Commands turn green when valid, red when not. Strings, paths, and flags are colored as you type. Catches typos before Enter.

**zsh-shift-select** — Brings GUI-style text selection to the prompt: Shift+arrows / Shift+Home / Shift+End extend a selection, Delete or Backspace cuts it. `.zshrc` layers three Windows-muscle-memory bindings on top — `Ctrl+X Ctrl+A` select-all, `Ctrl+V` paste from the kill-ring, `Ctrl+Z` undo. This is the one plugin that contradicts the "terminal owns selection" split above; it's deliberate.

**System clipboard** — ZLE's kill-ring is internal to the shell, so a cut is normally invisible to the rest of the desktop. `.zshrc` wraps the kill widgets to mirror `$CUTBUFFER` into the real clipboard via `wl-copy` (Wayland; `xclip` fallback on X11). So `Ctrl+U`, `Ctrl+K`, `Ctrl+W`, `Ctrl+Delete`, `Ctrl+Backspace` and cutting a shift-select region all land in the system clipboard, pasteable anywhere with `Ctrl+V`. `Ctrl+X Ctrl+W` copies without cutting (`Ctrl+W` alone while a selection is active). Copy is *not* on `Ctrl+C` — that's the tty's `intr` character and raises SIGINT before ZLE sees the key, so it can't be bound.

**fzf** (`Ctrl+R`, `Ctrl+T`, `Alt+C`)
- `Ctrl+R` — fuzzy history (way better than ↑↑↑)
- `Ctrl+T` — fuzzy file picker; the path is inserted at the cursor
- `Alt+C` — fuzzy directory picker; `cd`s into the choice
- Type partial letters; `Tab` multi-selects; `Enter` confirms; `Esc` cancels

**zoxide** (`z`) — Tracks dirs you visit. After `cd ~/projects/foo` once, `z foo` jumps there from anywhere. `zi foo` opens an interactive picker.

**Yazi** (`yazi` / `yy`) — Terminal file manager. Use `yy` when you want the shell to change to Yazi's directory after quitting.

**starship** — Two-line prompt with git status, last command duration (only shown if >2s), current time. Cross-shell: same prompt works in pwsh, bash, fish.

## Useful zsh-specific tricks

- **Smart `cd`** matches the PowerShell profile: `cd path/to/file` enters the file's parent, and `cd existing-dir/missing-file` enters `existing-dir`.
- **`cd -` cycles** the directory stack. `dirs -v` lists it; `cd -3` jumps to the 3rd entry.
- **`!!`** = previous command. `sudo !!` is the classic.
- **`!$`** = last argument of previous command. `mkdir foo && cd !$`
- **`**/*.py`** (with `EXTENDED_GLOB`) = recursive glob. No need for `find` for simple cases.
- **`take foo`** = `mkdir foo && cd foo` (built-in).
- **Tab on a partial path** completes it; if ambiguous, hit Tab again to enter the menu and arrow-key through options.
- **`alt+.`** inserts the last argument of the previous command. Repeat to walk further back.

## PowerShell → zsh translation

| pwsh | zsh |
|------|-----|
| `Get-ChildItem` / `ls` | `ls`, `ll`, `la` |
| `Get-Content` | `cat` (or `bat`) |
| `Where-Object` / `Select-String` | `grep` / `rg` (ripgrep) |
| `$PROFILE` | `~/.zshrc` (alias `nvzsh`) |
| `. $PROFILE` | `source ~/.zshrc` (alias `sz`) |
| PSReadLine prediction | zsh-autosuggestions |
| `Set-PSReadLineKeyHandler` | `bindkey` |
| `Push-Location` / `Pop-Location` | auto via `setopt AUTO_PUSHD`; `cd -` cycles |

## Optional: nicer `ls` and `cat`

```sh
sudo dnf install eza bat
```

Open a new shell. `ls`, `ll`, `la`, `lt` will use eza (icons + git status). `cat` will use bat (syntax-highlighted).

## Optional: nerd font for icons

starship and eza icons need a [Nerd Font](https://www.nerdfonts.com/font-downloads). Install one (e.g. `FiraCode Nerd Font`), then set in WezTerm:

```lua
config.font = wezterm.font 'FiraCode Nerd Font'
```

Without it you'll see boxes where icons should be.

## Reinstall on a new machine

From a clone of this repo:

```sh
./linux/restore-config.sh --zsh
```

That copies the config out, clones all three plugins, installs starship into `~/.local/bin`, and then reports anything it can't install itself — missing system packages (with the `dnf` line to paste) and whether your login shell still needs `chsh -s "$(command -v zsh)"`. Re-running it is safe: identical files are skipped, differing ones are backed up first, and already-cloned plugins are left alone.

Use `--no-install` to copy the config files only.

<details>
<summary>Equivalent manual steps</summary>

```sh
mkdir -p ~/.local/share/zsh/plugins ~/.local/bin
git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions \
  ~/.local/share/zsh/plugins/zsh-autosuggestions
git clone --depth 1 https://github.com/zdharma-continuum/fast-syntax-highlighting \
  ~/.local/share/zsh/plugins/fast-syntax-highlighting
git clone --depth 1 https://github.com/jirutka/zsh-shift-select \
  ~/.local/share/zsh/plugins/zsh-shift-select
curl -sS https://starship.rs/install.sh | sh -s -- -y -b ~/.local/bin
```

</details>

Update plugins later with `git -C <plugin-dir> pull`. The versions this config is known good against:

| Plugin | Commit |
|---|---|
| zsh-autosuggestions | `85919cd` |
| fast-syntax-highlighting | `3d574cc` |
| zsh-shift-select | `da46099` |

## Dependencies

Required for the headline features: `zsh`, `git`, `fzf`, `zoxide`, `neovim`.

Optional — every one is guarded by `command -v` in `.zshrc` and falls back cleanly if absent: `fd-find`, `yazi`, `eza`, `bat`, `ripgrep`, `wl-clipboard` / `xclip` / `xsel` (for the `c` copy-path function), `xdotool` (for `finder`).

The `restoggle` and `zoom` aliases call `gdisplay`, a personal script in `~/.local/bin` that isn't managed by this repo.

## Why no plugin manager?

`oh-my-zsh`, `zinit`, etc. are popular but add startup latency and abstraction. Two `git clone`s and three `source` lines do the same thing and are trivial to debug. If you outgrow this, `zinit` is the modern choice.

## Customizing

Edit `~/.zshrc.local` (auto-sourced if it exists). Keeps `~/.zshrc` clean so you can diff against this template later.

## Troubleshooting

- **No autosuggestions** — `ls ~/.local/share/zsh/plugins/zsh-autosuggestions`. If empty, re-run the clone. Then `sz`.
- **Starship icons are boxes** — install a Nerd Font (above).
- **`compinit` warns about insecure dirs** — run `compaudit`, then `chmod g-w` on the listed dirs.
- **Slow startup** — `time zsh -i -c exit`. Should be <200ms. If higher, the plugin block is the usual suspect.

## Restore previous config

```sh
mv ~/.zshrc.pre-revamp.* ~/.zshrc && exec zsh
```
