#!/usr/bin/env bash

# Backs up the VS Code user settings.json into vscode/settings.json as a
# reference copy. VS Code's own Settings Sync (GitHub / Microsoft account) stays
# the real sync; this is a manual, outward-only backup kept in git.
#   (default)  copy the VS Code settings.json into the repo
#   --check    change nothing; exit 1 if the repo copy is out of date
# Direction: VS Code -> repo only. Nothing is ever written back into VS Code,
# and nothing is ever committed or pushed; review the diff yourself first.
# Copy: byte for byte. settings.json is JSONC (comments, trailing commas), so it
# is never parsed or reformatted.
# Comparison: formatting is ignored (trailing commas, trailing whitespace, blank
# lines, CRs), so a formatter such as Prettier on the repo copy does not make it
# look out of date; only real setting changes do. See normalize() for the rules.
# Location: the VS Code "User" directory is detected per platform (macOS, Linux,
# and Windows through Git Bash); set VSCODE_USER_DIR to override it.
# Profiles: --profile <name> reads that profile's settings (found through
# User/globalStorage/storage.json) and writes settings.<name>.json by default.
# Use --dry-run first to preview; see --help for all options.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: sync-settings.sh [options]

Copies your VS Code user settings.json into vscode/settings.json.
The repo copy is overwritten, so review the diff (it may contain machine
specific paths or sensitive values) before committing. Nothing is committed.

Options:
  --check            Exit 1 if the repo copy differs from your VS Code settings
  --profile <name>   Use this VS Code profile (default: the default profile);
                     the default file becomes settings.<name>.json
  --file <path>      Use a different file in the repo
  --dry-run          Show what would change without writing anything
  -h, --help         Show this help

Environment:
  VSCODE_USER_DIR    VS Code "User" directory (default: detected per platform)

Run from any directory; the default file is settings.json next to this script.
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

# Defaults; each is overridden by its command line option or environment below.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILE=""
MODE="sync"
PROFILE=""
DRY_RUN=false

while [ $# -gt 0 ]; do
  case "$1" in
    --check) MODE="check" ;;
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

# The repo file defaults to settings.json next to this script. A profile gets its
# own file, with the name made filesystem safe.
if [ -z "$FILE" ]; then
  if [ -n "$PROFILE" ]; then
    FILE="$SCRIPT_DIR/settings.$(printf '%s' "$PROFILE" | tr -c 'A-Za-z0-9._-' '_').json"
  else
    FILE="$SCRIPT_DIR/settings.json"
  fi
fi

# Git Bash on Windows reports MINGW*/MSYS*; its VS Code lives under %APPDATA%.
detect_user_dir() {
  case "$(uname -s)" in
    Darwin) echo "$HOME/Library/Application Support/Code/User" ;;
    MINGW* | MSYS* | CYGWIN*)
      [ -n "${APPDATA:-}" ] || die "APPDATA is not set; set VSCODE_USER_DIR instead"
      echo "$APPDATA/Code/User"
      ;;
    *) echo "${XDG_CONFIG_HOME:-$HOME/.config}/Code/User" ;;
  esac
}

USER_DIR="${VSCODE_USER_DIR:-$(detect_user_dir)}"
[ -d "$USER_DIR" ] || die "VS Code user directory not found: $USER_DIR"

# Profiles are stored under User/profiles/<location>, where the location for a
# profile name is listed in globalStorage/storage.json. That file is JSON without
# a parser available, so the userDataProfiles array is flattened and each
# {...} entry is matched on its name; the lookup assumes the usual
# "name": "<profile>" spacing VS Code writes.
find_profile_settings() {
  local storage="$USER_DIR/globalStorage/storage.json" location
  [ -f "$storage" ] || die "Cannot look up profile '$PROFILE': $storage not found"
  location="$(tr -d '\r\n' <"$storage" \
    | grep -o '"userDataProfiles"[^]]*]' \
    | grep -o '{[^{}]*}' \
    | grep -F "\"name\": \"$PROFILE\"" \
    | sed -n 's/.*"location": *"\([^"]*\)".*/\1/p' \
    | head -n 1 || true)"
  [ -n "$location" ] || die "VS Code profile not found: $PROFILE"
  echo "$USER_DIR/profiles/$location/settings.json"
}

if [ -n "$PROFILE" ]; then
  SOURCE="$(find_profile_settings)"
else
  SOURCE="$USER_DIR/settings.json"
fi
[ -f "$SOURCE" ] || die "VS Code settings not found: $SOURCE"

# Drops CRs, trailing whitespace, blank lines and commas before a closing } or ].
# The first sed joins the file into one pattern space so a comma and the bracket
# on a later line can be matched; newlines are kept, so diffs stay line based.
# A heuristic: it also touches such a sequence inside a string, on both sides alike.
normalize() {
  tr -d '\r' <"$1" \
    | sed -e ':a' -e 'N' -e '$!ba' -e 's/,\([[:space:]]*[]}]\)/\1/g' \
    | sed -e 's/[[:space:]]*$//' -e '/^$/d'
}

# Diff of the normalized repo copy (<) against the normalized VS Code file (>).
differences() {
  diff <(normalize "$FILE") <(normalize "$SOURCE")
}

# A missing repo file is never up to date, so it gets created.
up_to_date() {
  [ -f "$FILE" ] && differences >/dev/null
}

# sync copies the raw VS Code file only when something really differs, so a
# formatter-only difference never causes a rewrite. check never writes.
case "$MODE" in
  sync)
    if up_to_date; then
      echo "$FILE is already up to date"
      exit 0
    fi
    if [ "$DRY_RUN" = true ]; then
      if [ -f "$FILE" ]; then
        echo "[dry-run] would update $FILE (formatting ignored; < repo, > VS Code):"
        differences || true
      else
        echo "[dry-run] would create $FILE"
      fi
      exit 0
    fi
    cp "$SOURCE" "$FILE"
    echo "Copied $SOURCE to $FILE"
    if command -v git >/dev/null 2>&1 && git -C "$SCRIPT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
      git -C "$SCRIPT_DIR" --no-pager diff --stat -- "$FILE" || true
    fi
    ;;
  check)
    if up_to_date; then
      echo "$FILE is up to date"
    else
      echo "$FILE is out of date (formatting ignored; < repo, > VS Code):" >&2
      if [ -f "$FILE" ]; then differences >&2 || true; else echo "(file does not exist)" >&2; fi
      exit 1
    fi
    ;;
esac
