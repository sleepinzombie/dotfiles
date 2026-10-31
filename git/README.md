# Git set up & configurations

This directory contains all settings and configurations that are related to the whole Git process.

## Table of Contents

- [Git Configurations Setup](#git-configurations-setup)
- [Usage](#usage)
- [Sync a Fork with its Upstream](#sync-a-fork-with-its-upstream)

## Git Configurations Setup

To establish specific configurations such as name, email, and other Git-related parameters on a per-repository basis, without utilizing the `--global` flag, it is essential to recognize that this process can be cumbersome. Neglecting to undertake this configuration procedure may lead to Git prompting the user to amend the most recent commit subsequent to modifying their credentials.

To obviate such occurrences, a script named `git-setup.sh` has been devised to streamline this process automatically.

### `git-setup.sh` Script Details

The `git-setup.sh` script has been enhanced to:

- Conditionally Include Configurations: The script now dynamically includes configurations for `SIGNINGKEY` and `GPG_COMMIT` only if their respective environment variables are set in the `gitconfig.env` file.
- Remove Empty Lines: After processing, the script removes empty lines to ensure a clean and readable output.

## Usage

#### 1. Clone the Repository

Make sure that you cloned the `dotfiles` repo. If not, use the below commands for cloning. If yes, you can skip to [step 2](#2-configure-git-credentials) directly.

```
git clone https://github.com/sleepinzombie/dotfiles.git
cd dotfiles/git
```

#### 2. Configure Git Credentials

Copy the `gitconfig.env.example` file and create your own `gitconfig.env` file:

```
cp gitconfig.env.example gitconfig.env
```

Edit the `gitconfig.env` file with your Git credentials using a text editor of your choice:

```
nano gitconfig.env
```

Update the following keys with your details:

```
USERNAME="Your Name"
EMAIL="your.email@example.com"
SIGNINGKEY="Your signing key"  # Optional: Include if you use a signing key
GPG_COMMIT="true"  # Optional: Set to true or false if you want to enable/disable commit signing
```

Save and close the file.

#### 3. Run the Copy Script

The copy script is used to copy the git-setup.sh file to the home directory with the predefined variables you provided. This copied setup file can then be used in any repository on your local machine to set up Git credentials.

Ensure the script is executable and run it:

```
chmod +x copy-script.sh
./copy-script.sh
```

Note: On Windows, make sure you have [Git Bash](https://gitforwindows.org/) installed to execute the scripts.

#### 4. Set Up Git Credentials

Finally, run the git-setup.sh script in the home directory to set up your Git credentials. You can use this script in any repository on your local machine:

```
~/git-setup.sh
```

Once this setup is completed, you can simply run `git-setup.sh` from any repository to configure Git credentials quickly.

## Sync a Fork with its Upstream

`git-sync-fork.sh` syncs the fork of the repository **in your current directory** with its upstream, so only that repository is affected. It is installed as `git-sync-fork` (also usable as `git sync-fork`) by the root `setup.sh` / `setup.ps1`, which also install the required `gh` CLI.

```
git-sync-fork [--pull] [--checkout] [--branch <name>] [--remote <name>] [--dry-run]
```

| Option | Effect |
| --- | --- |
| _(none)_ | Sync the fork's default branch on GitHub |
| `--pull` | Then update the local branch from the fork remote |
| `--checkout` | Switch to the branch first (implies `--pull`); refuses if the working tree is dirty |
| `--branch <name>` | Sync this branch instead of the default |
| `--remote <name>` | Remote that points to your fork (default: `origin`). The upstream is discovered from GitHub, so an extra `upstream` remote is not needed or used |
| `--dry-run` | Print the commands without running them |

Syncing is fast-forward only. It never force-updates or discards local work, and fails if the fork has diverged from upstream. It exits with an error if the repository is not a fork.

## Prune Stale Local Branches

`git-prune-branches` reviews and optionally deletes stale local branches in the **current repository**. It is installed as `git-prune-branches` (also usable as `git prune-branches`) by the root `setup.sh` / `setup.ps1`.

```
git-prune-branches [--dry-run] [-y | --yes] [--remote <name>] [--upstream <name>]
                   [--protect <pattern>] [--no-fetch] [--no-pr] [--no-backup]
git-prune-branches --list-backups
git-prune-branches --restore <branch>
git-prune-branches --purge-backups [--older-than <days>] [--gc]
```

| Option | Effect |
| --- | --- |
| `--dry-run` | Show candidates without changing anything |
| `-y`, `--yes` | Delete without prompting; otherwise deletion requires an interactive confirmation |
| `--remote <name>` | Fork or primary remote (default: `origin`) |
| `--upstream <name>` | Upstream remote to check in addition to the primary remote when it exists (default: `upstream`) |
| `--protect <pattern>` | Add a shell-style branch-name pattern to the protected branches; repeatable |
| `--no-fetch` | Skip `git fetch --prune`; remote-tracking data may be stale, so deleted remote branches might not be detected |
| `--no-pr` | Skip GitHub PR checks; squash/rebase merges and closed PRs may not be detected |
| `--no-backup` | Do not create backup refs before deleting branches (not recommended) |
| `--list-backups` | List saved branch tips and exit |
| `--restore <branch>` | Recreate the branch from its most recent backup and exit; fails if the local branch already exists |
| `--purge-backups` | Delete backup refs after confirmation (or with `--yes`); combine with `--older-than` to select older backups |
| `--older-than <days>` | With `--purge-backups`, only select backups at least this many days old |
| `--gc` | With `--purge-backups`, immediately prune unreachable Git objects; irreversible and may also remove other unreachable objects |

```
git-prune-branches --dry-run
git-prune-branches --yes
```

Branches are candidates when their tip is contained in the default branch of the primary or upstream remote (`merged`), a merged PR covers the local tip (`merged-pr`), the tracked remote branch is gone (`remote-gone`), or a PR was closed without merging and covers the local tip (`pr-closed`). GitHub PR checks require an authenticated `gh` CLI; if unavailable or unauthenticated, the script warns and skips those checks. By default, it fetches with pruning first and refuses to continue if fetching fails.

The current branch, the default branch, branches checked out in any worktree, `main`, `master`, `develop`, `dev`, `trunk`, and `release/*` are always protected. Branches with an open PR are kept, as are branches whose commits are newer than their closed or merged PR. Review the candidates with `--dry-run` before deletion.

Before deleting a candidate, the script saves its tip under `refs/prune-backup/<timestamp>/<branch>` (the ref itself uses about 41 bytes and keeps the commit objects from garbage collection). Backups remain in the local repository's `.git` directory until purged; deletion details are appended to `.git/prune-branches.log`.

For example, list and restore a backup:

```
git-prune-branches --list-backups
git-prune-branches --restore feature/my-branch
```

Purge previews and removes backups as follows:

```
git-prune-branches --purge-backups --dry-run
git-prune-branches --purge-backups --older-than 30
git-prune-branches --purge-backups --gc
```

Without `--gc`, purging removes the refs but the commits remain recoverable with `git fsck --unreachable` until normal garbage collection prunes them. With `--gc`, the script runs `git reflog expire --expire-unreachable=now --all` and `git gc --prune=now`; this is irreversible and can also remove any other unreachable objects in the repository.
