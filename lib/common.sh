#!/usr/bin/env bash

# Shared helpers for the dotfiles scripts. Meant to be sourced, not executed.

log_info() { printf '\033[34m[info]\033[0m %s\n' "$*"; }
log_ok() { printf '\033[32m[ ok ]\033[0m %s\n' "$*"; }
log_warn() { printf '\033[33m[warn]\033[0m %s\n' "$*" >&2; }
log_error() { printf '\033[31m[fail]\033[0m %s\n' "$*" >&2; }

has_cmd() { command -v "$1" >/dev/null 2>&1; }

# Prints one of: macos, linux, windows, unknown
detect_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux) echo "linux" ;;
    MINGW* | MSYS* | CYGWIN*) echo "windows" ;;
    *) echo "unknown" ;;
  esac
}

# Prints one of: brew, apt, dnf, pacman, winget, unknown
detect_package_manager() {
  case "$(detect_os)" in
    macos) has_cmd brew && echo "brew" || echo "unknown" ;;
    windows) has_cmd winget && echo "winget" || echo "unknown" ;;
    linux)
      if has_cmd apt-get; then echo "apt"
      elif has_cmd dnf; then echo "dnf"
      elif has_cmd pacman; then echo "pacman"
      else echo "unknown"
      fi
      ;;
    *) echo "unknown" ;;
  esac
}
