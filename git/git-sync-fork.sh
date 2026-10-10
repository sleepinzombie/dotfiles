#!/usr/bin/env bash

# Syncs the fork in the current directory with its upstream repository.
# Fast-forward only: it never rewrites history or discards local work.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: git-sync-fork [options]

Syncs the GitHub fork of the repository in the current directory with its upstream.

Options:
  --pull            After syncing, update the local branch from the fork remote
  --checkout        Switch to the default branch first (implies --pull)
  --branch <name>   Sync this branch instead of the default branch
  --remote <name>   Git remote that points to your fork (default: origin)
  --dry-run         Print what would be done without changing anything
  -h, --help        Show this help
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

DO_PULL=false
DO_CHECKOUT=false
DRY_RUN=false
BRANCH=""
REMOTE="origin"

while [ $# -gt 0 ]; do
  case "$1" in
    --pull) DO_PULL=true ;;
    --checkout) DO_CHECKOUT=true; DO_PULL=true ;;
    --branch)
      [ $# -ge 2 ] || die "--branch requires a value"
      BRANCH="$2"
      shift
      ;;
    --remote)
      [ $# -ge 2 ] || die "--remote requires a value"
      REMOTE="$2"
      shift
      ;;
    --dry-run) DRY_RUN=true ;;
    -h | --help) usage; exit 0 ;;
    *) usage >&2; die "Unknown option: $1" ;;
  esac
  shift
done

# Runs a command, or only prints it when --dry-run is set.
run() {
  if [ "$DRY_RUN" = true ]; then
    printf '[dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

# Preconditions: tools present, signed in, and inside a git repo.
# The repository is taken from the current directory, which is what
# restricts the sync to the fork you are standing in.
command -v git >/dev/null 2>&1 || die "git is not installed. Run dotfiles setup first."
command -v gh >/dev/null 2>&1 || die "GitHub CLI (gh) is not installed. Run dotfiles setup first."
gh auth status >/dev/null 2>&1 || die "gh is not authenticated. Run: gh auth login"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "Not inside a git repository."

# Resolve the fork from the chosen remote rather than letting gh guess: with
# both origin and upstream configured, gh prefers upstream, which is not a fork.
remote_url="$(git remote get-url "$REMOTE" 2>/dev/null)" \
  || die "Remote '$REMOTE' does not exist. Use --remote <name> to pick your fork's remote."
# Handles git@host:owner/repo.git, ssh://git@host/owner/repo.git and https://host/owner/repo.git
repo="$(printf '%s' "$remote_url" | sed -E 's#^(.*[:/])([^/:]+/[^/]+)$#\2#; s#\.git$##')"
case "$repo" in
  */*) ;;
  *) die "Could not parse a GitHub owner/repo from remote URL: $remote_url" ;;
esac

# Resolve the fork's details, its upstream and the default branch from GitHub.
is_fork="$(gh repo view "$repo" --json isFork --jq '.isFork')" \
  || die "Could not look up $repo on GitHub."
[ "$is_fork" = "true" ] || die "$repo is not a fork."

upstream="$(gh repo view "$repo" --json parent --jq '.parent.owner.login + "/" + .parent.name')"
default_branch="$(gh repo view "$repo" --json defaultBranchRef --jq '.defaultBranchRef.name')"
target="${BRANCH:-$default_branch}"

echo "Fork:     $repo"
echo "Upstream: $upstream"
echo "Branch:   $target"

# Checking out with uncommitted changes could fail midway or clobber work,
# so fail early, before touching GitHub. Untracked files do not block a checkout.
if [ "$DO_CHECKOUT" = true ]; then
  if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
    die "Working tree has uncommitted changes. Commit or stash them before using --checkout."
  fi
fi

# Step 1: update the fork on GitHub (fast-forward only; fails if diverged).
echo "Syncing $repo/$target with $upstream..."
run gh repo sync "$repo" --branch "$target"

# Step 2 (optional): bring the result down to the local clone.
if [ "$DO_PULL" = true ]; then
  current="$(git branch --show-current)"

  if [ "$DO_CHECKOUT" = true ] && [ "$current" != "$target" ]; then
    run git checkout "$target"
    current="$target"
  fi

  # On the target branch: a plain fast-forward pull. Otherwise fetch straight
  # into the local branch ref, leaving the current branch and work untouched.
  if [ "$current" = "$target" ]; then
    run git pull --ff-only "$REMOTE" "$target"
  else
    run git fetch "$REMOTE" "$target:$target"
  fi
fi

echo "Done."
