#!/usr/bin/env bash

# Deletes local branches that are no longer needed, with a recoverable backup.
# A branch is a candidate when any of these is true:
#   merged      its tip is contained in <remote>/<default> or <upstream>/<default>
#   merged-pr   a merged PR (squash/rebase merges included) has this branch as head
#   remote-gone it tracked a remote branch that has since been deleted
#   pr-closed   its PR was closed without merging (GitHub cannot truly delete PRs)
# Before deleting, each tip is saved under refs/prune-backup/<timestamp>/<branch>
# (a ref is ~41 bytes and keeps the commits from being garbage collected).
# Backups are kept until removed with --purge-backups, and can be brought back
# with --restore. Use --dry-run first; see --help for all options.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: git-prune-branches [options]

Deletes merged / orphaned local branches after backing up their tips.
Nothing is deleted without confirmation unless --yes is given.

Options:
  --dry-run               Show what would be deleted, change nothing
  -y, --yes               Do not ask for confirmation
  --remote <name>         Your fork / main remote (default: origin)
  --upstream <name>       Upstream remote, used when it exists (default: upstream)
  --protect <pattern>     Extra branch name glob to never delete (repeatable)
  --no-fetch              Do not run 'git fetch --prune' first
  --no-pr                 Skip GitHub PR checks (git-only detection)
  --no-backup             Do not create backup refs (not recommended)
  --list-backups          List backed-up branches and exit
  --restore <branch>      Recreate <branch> from its most recent backup and exit
  --purge-backups         Permanently delete backup refs (all, or see --older-than)
  --older-than <days>     With --purge-backups: only backups at least this old
  --gc                    With --purge-backups: also run 'git gc --prune=now' so the
                          commits are physically removed (irreversible)
  -h, --help              Show this help

Always protected: the current branch, the default branch, branches checked out
in any worktree, and main, master, develop, dev, trunk, release/*.
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

# Defaults; each is overridden by its command line option below.
DRY_RUN=false
ASSUME_YES=false
FETCH=true
USE_PR=true
BACKUP=true
REMOTE="origin"
UPSTREAM="upstream"
RESTORE=""
PURGE=false
OLDER_THAN=""
RUN_GC=false
LIST_BACKUPS=false
PROTECT=(main master develop dev trunk 'release/*')

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    -y | --yes) ASSUME_YES=true ;;
    --no-fetch) FETCH=false ;;
    --no-pr) USE_PR=false ;;
    --no-backup) BACKUP=false ;;
    --list-backups) LIST_BACKUPS=true ;;
    --purge-backups) PURGE=true ;;
    --gc) RUN_GC=true ;;
    --remote | --upstream | --protect | --restore | --older-than)
      [ $# -ge 2 ] || die "$1 requires a value"
      case "$1" in
        --remote) REMOTE="$2" ;;
        --upstream) UPSTREAM="$2" ;;
        --protect) PROTECT+=("$2") ;;
        --restore) RESTORE="$2" ;;
        --older-than)
          case "$2" in '' | *[!0-9]*) die "--older-than expects a number of days" ;; esac
          OLDER_THAN="$2"
          ;;
      esac
      shift
      ;;
    -h | --help) usage; exit 0 ;;
    *) usage >&2; die "Unknown option: $1" ;;
  esac
  shift
done

command -v git >/dev/null 2>&1 || die "git is not installed. Run dotfiles setup first."
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "Not inside a git repository."

BACKUP_NS="refs/prune-backup"
LOG_FILE="$(git rev-parse --git-common-dir)/prune-branches.log"

# Most recent backup ref for a branch (timestamps sort lexically).
latest_backup() {
  git for-each-ref --format='%(refname)' "$BACKUP_NS/*/$1" | sort | tail -n 1
}

# Maintenance modes (list / purge / restore) run on their own and exit before any branch is judged.
if [ "$LIST_BACKUPS" = true ]; then
  git for-each-ref --sort=refname \
    --format='%(refname:lstrip=2)  %(objectname:short)' "$BACKUP_NS"
  exit 0
fi

# Deleting the backup refs is the permanent step; --gc additionally removes the objects.
if [ "$PURGE" = true ]; then
  cutoff=""
  if [ -n "$OLDER_THAN" ]; then
    # BSD (macOS) and GNU date take different flags.
    cutoff="$(date -v-"${OLDER_THAN}"d +%Y%m%dT%H%M%S 2>/dev/null || date -d "$OLDER_THAN days ago" +%Y%m%dT%H%M%S)"
  fi
  purge_refs=()
  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    stamp_part="${ref#"$BACKUP_NS"/}"; stamp_part="${stamp_part%%/*}"
    # Timestamps sort lexically, so "<=" cutoff means old enough.
    if [ -z "$cutoff" ] || [ "$stamp_part" \< "$cutoff" ] || [ "$stamp_part" = "$cutoff" ]; then
      purge_refs+=("$ref")
    fi
  done < <(git for-each-ref --format='%(refname)' "$BACKUP_NS")
  [ ${#purge_refs[@]} -gt 0 ] || { echo "No matching backups."; exit 0; }
  printf 'Backups to permanently delete (%d):\n' "${#purge_refs[@]}"
  printf '  %s\n' "${purge_refs[@]#"$BACKUP_NS"/}"
  if [ "$DRY_RUN" = true ]; then echo "[dry-run] No changes made."; exit 0; fi
  if [ "$ASSUME_YES" = false ]; then
    [ -r /dev/tty ] || die "Not interactive; re-run with --yes or --dry-run."
    printf 'This cannot be undone. Continue? [y/N] '
    read -r answer </dev/tty
    case "$answer" in y | Y | yes | YES) ;; *) echo "Aborted."; exit 1 ;; esac
  fi
  for ref in "${purge_refs[@]}"; do git update-ref -d "$ref"; done
  echo "Deleted ${#purge_refs[@]} backup ref(s)."
  if [ "$RUN_GC" = true ]; then
    git reflog expire --expire-unreachable=now --all
    git gc --prune=now --quiet
    echo "Unreachable commits removed."
  else
    echo "Commits stay recoverable via 'git fsck --unreachable' until gc prunes them (default ~2 weeks). Use --gc to remove now."
  fi
  exit 0
fi

if [ -n "$RESTORE" ]; then
  ref="$(latest_backup "$RESTORE")"
  [ -n "$ref" ] || die "No backup found for '$RESTORE'. See --list-backups."
  if git show-ref --verify --quiet "refs/heads/$RESTORE"; then
    die "Local branch '$RESTORE' already exists."
  fi
  git branch -- "$RESTORE" "$(git rev-parse "$ref")"
  echo "Restored $RESTORE from $ref"
  exit 0
fi

# From here on, the remotes and default branch are needed to judge branches.
git remote get-url "$REMOTE" >/dev/null 2>&1 || die "Remote '$REMOTE' does not exist. Use --remote <name>."
HAS_UPSTREAM=false
git remote get-url "$UPSTREAM" >/dev/null 2>&1 && HAS_UPSTREAM=true

# Pulls owner/repo out of git@host:owner/repo.git, ssh:// and https:// URLs.
remote_repo() {
  git remote get-url "$1" | sed -E 's#^(.*[:/])([^/:]+/[^/]+)$#\2#; s#\.git$##'
}

if [ "$FETCH" = true ]; then
  # --prune is what makes deleted remote branches show up as [gone].
  # It only touches remote-tracking refs, never local branches.
  git fetch --prune --quiet "$REMOTE" || die "Fetching '$REMOTE' failed; refusing to judge on stale data (use --no-fetch to override)."
  [ "$HAS_UPSTREAM" = true ] && { git fetch --prune --quiet "$UPSTREAM" || die "Fetching '$UPSTREAM' failed."; }
fi

# Default branch, from the remote's HEAD; falls back to main/master.
default_branch="$(git symbolic-ref --quiet --short "refs/remotes/$REMOTE/HEAD" 2>/dev/null | sed "s#^$REMOTE/##" || true)"
if [ -z "$default_branch" ]; then
  for b in main master; do
    if git show-ref --verify --quiet "refs/remotes/$REMOTE/$b"; then default_branch="$b"; break; fi
  done
fi
[ -n "$default_branch" ] || die "Could not determine the default branch of '$REMOTE'."

# Refs a branch must be contained in to count as merged.
base_refs=()
git show-ref --verify --quiet "refs/remotes/$REMOTE/$default_branch" && base_refs+=("refs/remotes/$REMOTE/$default_branch")
if [ "$HAS_UPSTREAM" = true ] && git show-ref --verify --quiet "refs/remotes/$UPSTREAM/$default_branch"; then
  base_refs+=("refs/remotes/$UPSTREAM/$default_branch")
fi
[ ${#base_refs[@]} -gt 0 ] || die "No remote-tracking ref for '$default_branch'."

# PR data: one gh call per repository (fork and upstream) rather than per branch.
pr_data=""
if [ "$USE_PR" = true ]; then
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    owner="$(remote_repo "$REMOTE" | cut -d/ -f1)"
    repos="$(remote_repo "$REMOTE")"
    [ "$HAS_UPSTREAM" = true ] && repos="$repos $(remote_repo "$UPSTREAM")"
    for repo in $(printf '%s\n' $repos | sort -u); do
      out="$(gh pr list --repo "$repo" --state all --limit 1000 \
        --json number,state,headRefName,headRefOid,headRepositoryOwner \
        --jq '.[] | [.headRefName, .state, .headRefOid, (.headRepositoryOwner.login // ""), .number] | @tsv')" \
        || die "Could not list PRs for $repo (use --no-pr to skip PR checks)."
      pr_data="$pr_data$out"$'\n'
    done
  else
    printf 'Warning: gh missing or not authenticated; PR checks skipped (squash merges will not be detected).\n' >&2
    owner=""
  fi
fi

current="$(git branch --show-current)"
# Branches checked out in any worktree cannot be deleted and must not be touched.
worktree_branches="$(git worktree list --porcelain | sed -n 's#^branch refs/heads/##p')"

# Names that must never be deleted, whatever their state.
is_protected() {
  local name="$1" pat
  [ "$name" = "$default_branch" ] && return 0
  [ "$name" = "$current" ] && return 0
  printf '%s\n' "$worktree_branches" | grep -Fxq -- "$name" && return 0
  for pat in "${PROTECT[@]}"; do
    # shellcheck disable=SC2254
    case "$name" in $pat) return 0 ;; esac
  done
  return 1
}

# True when the commit is already part of the default branch on the fork or upstream.
is_merged_into_base() {
  local sha="$1" ref
  for ref in "${base_refs[@]}"; do
    git merge-base --is-ancestor "$sha" "$ref" 2>/dev/null && return 0
  done
  return 1
}

# A PR only counts if the local tip is that PR's head or an ancestor of it,
# so commits made after the PR was closed/merged are never discarded.
tip_covered_by() {
  local sha="$1" head="$2"
  [ "$sha" = "$head" ] && return 0
  git cat-file -e "$head^{commit}" 2>/dev/null && git merge-base --is-ancestor "$sha" "$head" 2>/dev/null
}

# Step 1: classify every local branch. The first matching reason wins; anything
# unclear is kept, so mistakes err on the side of not deleting.
candidates=()   # "branch<TAB>sha<TAB>reason"
kept=0

while IFS=$'\t' read -r name sha track; do
  [ -n "$name" ] || continue
  is_protected "$name" && continue

  reason=""
  has_open=false
  merged_pr=false
  closed_pr=false
  if [ -n "$pr_data" ]; then
    while IFS=$'\t' read -r p_name p_state p_oid p_owner _; do
      [ "$p_name" = "$name" ] && [ "$p_owner" = "$owner" ] || continue
      case "$p_state" in
        OPEN) has_open=true ;;
        MERGED) tip_covered_by "$sha" "$p_oid" && merged_pr=true ;;
        CLOSED) tip_covered_by "$sha" "$p_oid" && closed_pr=true ;;
      esac
    done <<EOF
$pr_data
EOF
  fi

  # A branch with an open PR is active work, whatever else is true of it.
  if [ "$has_open" = true ]; then
    kept=$((kept + 1)); continue
  fi

  if [ "$track" = "[gone]" ]; then
    reason="remote-gone"
  elif is_merged_into_base "$sha"; then
    # A branch sitting exactly on a base tip with no remote has no work of its own
    # (likely just created), so leave it alone.
    base_tip_match=false
    for ref in "${base_refs[@]}"; do [ "$(git rev-parse "$ref")" = "$sha" ] && base_tip_match=true; done
    if [ "$base_tip_match" = true ] && [ -z "$track" ] && ! git config --get "branch.$name.remote" >/dev/null; then
      kept=$((kept + 1)); continue
    fi
    reason="merged"
  elif [ "$merged_pr" = true ]; then
    reason="merged-pr"
  elif [ "$closed_pr" = true ]; then
    reason="pr-closed"
  fi

  if [ -n "$reason" ]; then
    candidates+=("$name"$'\t'"$sha"$'\t'"$reason")
  else
    kept=$((kept + 1))
  fi
done < <(git for-each-ref --format='%(refname:short)%09%(objectname)%09%(upstream:track)' refs/heads)

# Step 2: show the plan. --dry-run stops here.
echo "Default branch: $default_branch   Base: ${base_refs[*]#refs/remotes/}"
if [ ${#candidates[@]} -eq 0 ]; then
  echo "Nothing to delete ($kept branch(es) kept)."
  exit 0
fi

echo "Branches to delete:"
for c in "${candidates[@]}"; do
  IFS=$'\t' read -r name sha reason <<<"$c"
  printf '  %-12s %s  %s\n' "[$reason]" "${sha:0:8}" "$name"
done
echo "$kept branch(es) kept."

if [ "$DRY_RUN" = true ]; then
  echo "[dry-run] No changes made."
  [ "$BACKUP" = true ] && echo "[dry-run] Backups would go to $BACKUP_NS/<timestamp>/<branch>."
  exit 0
fi

if [ "$ASSUME_YES" = false ]; then
  [ -r /dev/tty ] || die "Not interactive; re-run with --yes or --dry-run."
  printf 'Delete %d branch(es)? [y/N] ' "${#candidates[@]}"
  read -r answer </dev/tty
  case "$answer" in y | Y | yes | YES) ;; *) echo "Aborted."; exit 1 ;; esac
fi

# Step 3: back up, then delete, one branch at a time.
stamp="$(date +%Y%m%dT%H%M%S)"
deleted=0
for c in "${candidates[@]}"; do
  IFS=$'\t' read -r name sha reason <<<"$c"

  # The backup must exist and match before the branch is removed.
  if [ "$BACKUP" = true ]; then
    ref="$BACKUP_NS/$stamp/$name"
    git update-ref -m "prune-branches: $reason" "$ref" "$sha"
    [ "$(git rev-parse "$ref")" = "$sha" ] || { printf 'Backup failed for %s; skipped.\n' "$name" >&2; continue; }
  fi

  # Delete only if the branch still points at the commit we judged.
  if git update-ref -d "refs/heads/$name" "$sha"; then
    git config --remove-section "branch.$name" 2>/dev/null || true
    printf '%s\t%s\t%s\t%s\n' "$(date -u +%FT%TZ)" "$name" "$sha" "$reason" >>"$LOG_FILE"
    printf 'Deleted %s (was %s)\n' "$name" "${sha:0:8}"
    deleted=$((deleted + 1))
  else
    printf 'Could not delete %s; skipped.\n' "$name" >&2
  fi
done

echo "Done. Deleted $deleted branch(es)."
[ "$BACKUP" = true ] && echo "Restore with: git-prune-branches --restore <branch>  (list: --list-backups)"
