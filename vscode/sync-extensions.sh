#!/usr/bin/env bash

# Keeps vscode/extensions.txt in sync with the extensions installed in VS Code,
# so the same set can be brought to a new device.
#   (default)  overwrite extensions.txt with the installed extensions
#   --check    change nothing; exit 1 if extensions.txt is out of date
#   --install  install extensions listed in extensions.txt that are missing
# IDs are stored lowercase and sorted, one per line, and versions are not pinned.
# Installing never removes extensions, and nothing is ever committed.
# Use --dry-run first to preview; see --help for all options.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: sync-extensions.sh [options]

Syncs the installed VS Code extensions with vscode/extensions.txt.
With no mode option, extensions.txt is overwritten with the installed list,
so extensions you uninstalled are dropped from it (git history keeps them).

Options:
  --check            Exit 1 if extensions.txt differs from the installed list
  --install          Install extensions from extensions.txt that are missing
  --profile <name>   Use this VS Code profile (default: the default profile)
  --file <path>      Use a different extensions file
  --dry-run          Show what would change without writing or installing anything
  -h, --help         Show this help

Environment:
  CODE_BIN           VS Code CLI to use (default: code), e.g. code-insiders

Run from any directory; the default file is extensions.txt next to this script.
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

# Defaults; each is overridden by its command line option or environment below.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILE="$SCRIPT_DIR/extensions.txt"
CODE_BIN="${CODE_BIN:-code}"
MODE="sync"
PROFILE=""
DRY_RUN=false

while [ $# -gt 0 ]; do
  case "$1" in
    --check) MODE="check" ;;
    --install) MODE="install" ;;
    --profile)
      [ $# -ge 2 ] || die "--profile requires a value"
      PROFILE="$2"
      shift
      ;;
    --file)
      [ $# -ge 2 ] || die "--file requires a value"
      FILE="$2"
      shift
      ;;
    --dry-run) DRY_RUN=true ;;
    -h | --help) usage; exit 0 ;;
    *) usage >&2; die "Unknown option: $1" ;;
  esac
  shift
done

command -v "$CODE_BIN" >/dev/null 2>&1 || die "'$CODE_BIN' not found in PATH (install the shell command from VS Code)"

# An empty array expands to an unbound variable on older bash (macOS ships 3.2),
# hence the ${arr[@]+...} guard where it is used.
PROFILE_ARGS=()
[ -n "$PROFILE" ] && PROFILE_ARGS=(--profile "$PROFILE")

# Lowercased and sorted so the file diffs cleanly; extension IDs are case-insensitive.
list_installed() {
  "$CODE_BIN" ${PROFILE_ARGS[@]+"${PROFILE_ARGS[@]}"} --list-extensions \
    | tr '[:upper:]' '[:lower:]' | LC_ALL=C sort -u
}

list_file() {
  [ -f "$FILE" ] || return 0
  tr -d '\r' <"$FILE" | sed '/^[[:space:]]*$/d' | tr '[:upper:]' '[:lower:]' | LC_ALL=C sort -u
}

# Normalized so both lists compare cleanly. The empty-list guard stops a broken
# CLI call or wrong profile from wiping extensions.txt.
INSTALLED="$(list_installed)"
[ -n "$INSTALLED" ] || die "No extensions reported by '$CODE_BIN'; refusing to continue"

case "$MODE" in
  sync)
    if [ "$DRY_RUN" = true ]; then
      echo "[dry-run] would update $FILE (< file, > installed):"
      diff <(list_file) <(printf '%s\n' "$INSTALLED") || true
      exit 0
    fi
    printf '%s\n' "$INSTALLED" >"$FILE"
    printf 'Wrote %s extensions to %s\n' "$(printf '%s\n' "$INSTALLED" | wc -l | tr -d ' ')" "$FILE"
    if command -v git >/dev/null 2>&1 && git -C "$SCRIPT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
      git -C "$SCRIPT_DIR" --no-pager diff --stat -- "$FILE" || true
    fi
    ;;
  check)
    if diff <(list_file) <(printf '%s\n' "$INSTALLED") >/dev/null; then
      echo "extensions.txt is up to date"
    else
      echo "extensions.txt is out of date (< file, > installed):" >&2
      diff <(list_file) <(printf '%s\n' "$INSTALLED") >&2 || true
      exit 1
    fi
    ;;
  install)
    [ -f "$FILE" ] || die "$FILE not found"
    # Only add what is missing; extensions not in the file are left alone.
    missing="$(comm -13 <(printf '%s\n' "$INSTALLED") <(list_file))"
    if [ -z "$missing" ]; then
      echo "All extensions from $FILE are already installed"
      exit 0
    fi
    if [ "$DRY_RUN" = true ]; then
      printf '[dry-run] would install:\n%s\n' "$missing"
      exit 0
    fi
    # Keep going past a failed extension so one bad ID does not block the rest.
    failed=0
    while IFS= read -r ext; do
      "$CODE_BIN" ${PROFILE_ARGS[@]+"${PROFILE_ARGS[@]}"} --install-extension "$ext" || failed=$((failed + 1))
    done <<<"$missing"
    [ "$failed" -eq 0 ] || die "$failed extension(s) failed to install"
    ;;
esac
