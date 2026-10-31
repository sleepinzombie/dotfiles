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

`git-prune-branches` (installed by `setup.sh` / `setup.ps1`, also usable as `git prune-branches`) deletes local branches in the **current repository** that are no longer needed:

| Reason | Meaning |
| --- | --- |
| `merged` | Tip is contained in `<remote>/<default>` or `upstream/<default>` |
| `merged-pr` | A merged PR (squash/rebase included) has the branch as head, and the local tip is covered by it |
| `remote-gone` | The tracked remote branch was deleted |
| `pr-closed` | The branch's PR was closed unmerged (GitHub cannot truly delete PRs) |

Safety: run with `--dry-run` first; deletion asks for confirmation unless `--yes`. It never touches the current branch, the default branch, branches checked out in a worktree, `main/master/develop/dev/trunk/release/*` (add more with `--protect`), branches with an open PR, or branches with commits newer than their closed/merged PR. Each tip is backed up under `refs/prune-backup/<timestamp>/<branch>` first (about 41 bytes per branch; it keeps the commits from garbage collection), and deletions are logged to `.git/prune-branches.log`.

```
git-prune-branches --dry-run
git-prune-branches --list-backups
git-prune-branches --restore <branch>
```

Backups are kept until you purge them:

```
git-prune-branches --purge-backups --dry-run          # preview
git-prune-branches --purge-backups --older-than 30    # only backups 30+ days old
git-prune-branches --purge-backups --gc               # all, and physically remove the commits now
```

Without `--gc`, the commits remain recoverable with `git fsck --unreachable` until git's normal garbage collection prunes them. `--gc` runs `git reflog expire --expire-unreachable=now --all` and `git gc --prune=now`, which also discards any other unreachable objects in the repo, so it is irreversible.
