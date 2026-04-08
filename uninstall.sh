#!/usr/bin/env bash
set -euo pipefail

PROGRAM_NAME="claude-fusion"
DEFAULT_INSTALL_DIR="$HOME/.claude-fusion"
DEFAULT_BIN_DIR="$HOME/.local/bin"

INSTALL_DIR="$DEFAULT_INSTALL_DIR"
BIN_DIR="$DEFAULT_BIN_DIR"

usage() {
  cat <<'EOF'
Usage: release/uninstall.sh [options]

Options:
  --help                 Show this help
  --install-dir <path>   Override install dir
  --bin-dir <path>       Override wrapper dir
EOF
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --install-dir)
      [[ $# -ge 2 ]] || die "--install-dir requires a value"
      INSTALL_DIR="$2"
      shift 2
      ;;
    --bin-dir)
      [[ $# -ge 2 ]] || die "--bin-dir requires a value"
      BIN_DIR="$2"
      shift 2
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

case "$(uname -s)" in
  Darwin|Linux) ;;
  *) die "unsupported platform: $(uname -s)" ;;
esac

rm -f "$BIN_DIR/$PROGRAM_NAME"
rm -rf "$INSTALL_DIR"

printf 'Removed:\n' >&2
printf '  %s\n' "$INSTALL_DIR" >&2
printf '  %s/%s\n' "$BIN_DIR" "$PROGRAM_NAME" >&2
printf '\nPreserved:\n' >&2
printf '  ~/.claude\n' >&2
printf '  project .claude/ directories and CLAUDE.md files\n' >&2
