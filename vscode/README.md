<div align="center">

# 🧩 VS Code

**My editor settings, fonts and extensions, ready to bring to a new machine.**

[Overview](#-overview) · [Quick start](#-quick-start) · [Sync extensions](#-sync-extensions) · [Fonts](#-fonts)

</div>

---

## 📋 Overview

| File | Purpose |
| --- | --- |
| [`settings.json`](settings.json) | Editor, terminal and theme settings |
| [`extensions.txt`](extensions.txt) | The installed extensions, one ID per line (generated, don't edit by hand) |
| [`sync-extensions.sh`](sync-extensions.sh) | Keeps `extensions.txt` in sync with VS Code, and installs from it |

> [!IMPORTANT]
> Install the extensions and [fonts](#-fonts) before using `settings.json`, otherwise the themes and fonts it references won't be found.

## ⚡ Quick start

On a new machine, after running the root `setup.sh` / `setup.ps1`:

```
vscode-sync-extensions --install --dry-run   # preview what would be installed
vscode-sync-extensions --install
```

Then copy [`settings.json`](settings.json) into your VS Code user settings.

## 🔄 Sync Extensions

[`extensions.txt`](extensions.txt) keeps track of the extensions installed in VS Code, so they can be brought to a new device. Don't edit it by hand: `vscode-sync-extensions` generates it from your machine and can install from it again.

The root `setup.sh` / `setup.ps1` installs it as `vscode-sync-extensions`, so it can be run from any directory. The installed command is a small wrapper that runs `vscode/sync-extensions.sh` from your dotfiles checkout, so it always updates the tracked `extensions.txt`. If you move the checkout, rerun setup.

> [!NOTE]
> It needs the `code` command in your `PATH`. In VS Code, open the Command Palette and run "Shell Command: Install 'code' command in PATH".

```
vscode-sync-extensions [--check | --install] [--dry-run] [--profile <name>] [--file <path>]
```

| Option | Effect |
| --- | --- |
| _(none)_ | Overwrite `extensions.txt` with the installed extensions, then show the diff stat |
| `--check` | Change nothing; exit 1 and print the differences if `extensions.txt` is out of date |
| `--install` | Install the extensions from `extensions.txt` that are missing (for a new device) |
| `--dry-run` | Show what would be written or installed without changing anything |
| `--profile <name>` | Use this VS Code profile instead of the default one |
| `--file <path>` | Use a different extensions file, for example one file per profile |

Set `CODE_BIN` to use another VS Code build, for example `CODE_BIN=code-insiders vscode-sync-extensions`.

For example, update the file after installing or removing extensions, and preview before installing on a new device:

```
vscode-sync-extensions --dry-run
vscode-sync-extensions
vscode-sync-extensions --install --dry-run
vscode-sync-extensions --install
```

IDs are stored lowercase and sorted, one per line, so diffs only show real changes. Syncing overwrites the file, so extensions you uninstalled disappear from it; git history keeps the previous list. Versions are not pinned, so a new device gets the latest release.

> [!TIP]
> Always preview with `--dry-run` first. Review the diff before committing; the script never commits.

Installing only adds missing extensions and never removes any. It continues past failures and exits with an error listing how many failed. The script refuses to run if VS Code reports no extensions, so an empty list can't overwrite the file.

## 🔤 Fonts

`settings.json` references these fonts, so install them first:

| Font | Used for |
| --- | --- |
| [Cascadia Code](https://github.com/microsoft/cascadia-code) | Editor |
| [Fira Code](https://github.com/tonsky/FiraCode) | Editor fallback and integrated terminal |
| [MesloLGS NF](https://github.com/romkatv/powerlevel10k-media) | Integrated terminal fallback (Nerd Font glyphs) |
