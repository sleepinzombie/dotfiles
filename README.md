# Divesh's Development Settings

This repository contains settings and configurations for various development tools and environments, tailored to suit personal preferences and workflow optimizations. The configurations provided here are primarily aimed at enhancing the development experience.

## Table of Contents

- [Introduction](#introduction)
- [Included Settings](#included-settings)
- [Usage](#usage)

## Introduction

As developers, we often find ourselves customizing our development environments to suit our workflow, coding style, and preferences. This repository serves as a central location to store and manage these settings, ensuring consistency across different machines and environments.

## Included Settings

- [VS Code Extensions](vscode/README.md)
- [Git Settings & Configurations](git/README.md)

## Usage

### 1. Bootstrap the machine

Installs `git` and the GitHub CLI (`gh`), signs you in to `gh` if needed, and installs the `git-sync-fork` and `git-prune-branches` commands into `~/.local/bin`. It is safe to re-run.

| Platform | Command |
| --- | --- |
| macOS / Linux / Git Bash | `./setup.sh` |
| Windows (PowerShell) | `./setup.ps1` |

Pass `--dry-run` (`-DryRun` for PowerShell) to preview without changing anything. Supported package managers: Homebrew, apt, dnf, pacman and winget.

### 2. Sync a fork

From inside any cloned fork:

```
git-sync-fork              # sync the fork on GitHub with its upstream
git-sync-fork --pull       # ...then update the local default branch
git-sync-fork --checkout   # ...switch to the default branch first (implies --pull)
```

See [Git Settings & Configurations](git/README.md#sync-a-fork-with-its-upstream) for details.

### 3. Prune stale local branches

From inside any Git repository, preview branches that can be safely deleted:

```
git-prune-branches --dry-run
```

By default, the script asks for confirmation before deleting branches and backs up each branch tip locally. See [Git Settings & Configurations](git/README.md#prune-stale-local-branches) for detection rules, safety options, and backup recovery.
