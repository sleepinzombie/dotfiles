#!/usr/bin/env bash

# Bootstraps a machine: installs git and the GitHub CLI, makes sure gh is
# authenticated, and installs the dotfiles commands into ~/.local/bin.
# Works on macOS, Linux (apt/dnf/pacman) and Windows via Git Bash (winget).
# Safe to run multiple times.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$ROOT_DIR/lib/common.sh"

BIN_DIR="$HOME/.local/bin"
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    -h | --help)
      echo "Usage: ./setup.sh [--dry-run]"
      exit 0
      ;;
    *)
      log_error "Unknown option: $arg"
      exit 1
      ;;
  esac
done

# Runs a command, or only prints it when --dry-run is set.
run() {
  if [ "$DRY_RUN" = true ]; then
    printf '[dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

PKG_MANAGER="$(detect_package_manager)"
OS="$(detect_os)"
log_info "Detected OS: $OS, package manager: $PKG_MANAGER"

if [ "$OS" = "macos" ] && [ "$PKG_MANAGER" = "unknown" ]; then
  log_error "Homebrew is required on macOS. Install it from https://brew.sh and re-run."
  exit 1
fi

# The default Debian/Ubuntu repos ship an outdated gh, so add GitHub's official
# apt repository first (https://github.com/cli/cli/blob/trunk/docs/install_linux.md).
install_gh_apt() {
  run sudo mkdir -p -m 755 /etc/apt/keyrings
  if [ "$DRY_RUN" = true ]; then
    echo "[dry-run] add GitHub CLI apt repository"
  else
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  fi
  run sudo apt-get update
  run sudo apt-get install -y gh
}

# Installs a package only when its command is missing, using whichever package
# manager was detected. Arguments are the per-manager package names:
# install_package <command> <brew> <apt> <dnf> <pacman> <winget-id>
install_package() {
  local cmd="$1" brew_pkg="$2" apt_pkg="$3" dnf_pkg="$4" pacman_pkg="$5" winget_id="$6"

  if has_cmd "$cmd"; then
    log_ok "$cmd already installed"
    return 0
  fi

  log_info "Installing $cmd..."
  case "$PKG_MANAGER" in
    brew) run brew install "$brew_pkg" ;;
    apt)
      if [ "$cmd" = "gh" ]; then
        install_gh_apt
      else
        run sudo apt-get install -y "$apt_pkg"
      fi
      ;;
    dnf) run sudo dnf install -y "$dnf_pkg" ;;
    pacman) run sudo pacman -S --noconfirm "$pacman_pkg" ;;
    winget)
      run winget install --id "$winget_id" -e --accept-source-agreements --accept-package-agreements
      ;;
    *)
      log_error "No supported package manager found. Install $cmd manually."
      return 1
      ;;
  esac
}

install_package git git git git git Git.Git
install_package gh gh gh gh github-cli GitHub.cli

# Authentication is skipped on dry runs because gh auth login is interactive.
if [ "$DRY_RUN" = false ] && has_cmd gh; then
  if gh auth status >/dev/null 2>&1; then
    log_ok "gh is authenticated"
  else
    log_info "gh is not authenticated, starting login..."
    gh auth login
  fi
fi

# Installed without the .sh extension so it can be run as `git-sync-fork`,
# and as `git sync-fork` since git treats git-* executables on PATH as subcommands.
log_info "Installing commands into $BIN_DIR"
run mkdir -p "$BIN_DIR"
run cp "$ROOT_DIR/git/git-sync-fork.sh" "$BIN_DIR/git-sync-fork"
run chmod +x "$BIN_DIR/git-sync-fork"
log_ok "Installed git-sync-fork (also available as: git sync-fork)"
run cp "$ROOT_DIR/git/git-prune-branches.sh" "$BIN_DIR/git-prune-branches"
run chmod +x "$BIN_DIR/git-prune-branches"
log_ok "Installed git-prune-branches (also available as: git prune-branches)"

# Only warn: editing shell profiles automatically varies too much per shell.
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) log_warn "$BIN_DIR is not on your PATH. Add: export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

log_ok "Setup complete"
