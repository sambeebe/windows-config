# agents/

Configs for the CLI coding agents — Claude Code, Codex, opencode — kept in one
place and restorable on both Windows and Linux.

These tools put their config in the same place on both platforms (`~/.claude`,
`~/.codex`, `~/.config/opencode`), so unlike the rest of this repo this folder
is not split per-OS. Both platforms' scripts read the same
[`manifest.txt`](manifest.txt).

## Usage

Windows:

```powershell
.\sync-config.ps1 -Agents        # live config -> repo
.\restore-config.ps1 -Agents     # repo -> live config
```

Linux:

```bash
./linux/sync-config.sh --agents
./linux/restore-config.sh --agents
```

Both are also menu option and part of `-All` / `--all`.

## Adding a tool

Add a line to `manifest.txt`:

```
<tool>|<path under agents/>|<path relative to the home directory>
```

and re-run the sync script. Nothing else needs changing — the scripts have no
per-tool knowledge beyond the manifest. Entries whose source is missing are
skipped, so it is fine to list paths for a tool that is not installed
everywhere.

## What is deliberately not tracked

The manifest is an **allowlist**, not an ignore list, because this repo is
public. Never add:

- `~/.claude/.credentials.json`, `~/.codex/auth.json` — API/OAuth tokens
- `~/.claude.json` — mixes OAuth account data with per-project history
- `sessions/`, `projects/`, `history.jsonl`, `*.sqlite`, `log/`, `cache/`,
  `shell-snapshots/` — session state and transcripts, not config
- `plugins/`, `skills/.system/` — app-managed, re-downloaded on demand

`.gitignore` has a backstop for the credential filenames, but the manifest is
the real defence: nothing is copied unless it is listed.

One thing worth checking before a commit: Claude Code's `settings.json` can
hold an `env` block, and anything you put there ends up in the repo.

## Codex `config.toml`

Codex appends a `[projects.'<absolute path>']` block for every folder you mark
as trusted. That is machine state, not config: the paths are meaningless on
another box, they churn the diff on every sync, and they publish your local
directory names. The sync scripts strip those blocks, keeping the rest of the
file as-is.

The practical consequence: after restoring onto a machine that already had
Codex, its trusted-folder list is replaced by the repo's, so Codex asks about
folder trust again. The previous file is backed up next to it as
`config.toml.bak.<timestamp>`.

## Restores are backed up

Restoring overwrites the live file, backing up whatever was there first as
`<name>.bak.<timestamp>` in the same directory. Identical files are left alone.
