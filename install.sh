#!/usr/bin/env bash
set -euo pipefail

PROGRAM_NAME="claude-fusion"
DEFAULT_INSTALL_DIR="$HOME/.claude-fusion"
DEFAULT_BIN_DIR="$HOME/.local/bin"
DEFAULT_REPO_NAME="claude-code-haha"

VERSION="latest"
INSTALL_DIR="$DEFAULT_INSTALL_DIR"
BIN_DIR="$DEFAULT_BIN_DIR"
REPO_NAME="$DEFAULT_REPO_NAME"
UPGRADE=0

usage() {
  cat <<'EOF'
Usage: release/install.sh [options]

Options:
  --help                 Show this help
  --version <tag>        Install a specific release tag (default: latest)
  --upgrade              Upgrade an existing install
  --install-dir <path>   Override install dir (default: ~/.claude-fusion)
  --bin-dir <path>       Override wrapper dir (default: ~/.local/bin)
  --repo-name <name>     Override package base name (default: claude-code-haha)
EOF
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  [[ -n "${TMP_DIR:-}" && -d "${TMP_DIR:-}" ]] && rm -rf "$TMP_DIR"
}
trap cleanup EXIT INT TERM

WRAPPER_BACKUP_PATH=""

need() {
  command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"
}

download_file() {
  local url="$1"
  local out="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fL "$url" -o "$out"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "$out" "$url"
  else
    die "need curl or wget to download release artifacts"
  fi
}

resolve_bun() {
  if command -v bun >/dev/null 2>&1; then
    command -v bun
  elif [[ -x "$HOME/.bun/bin/bun" ]]; then
    printf '%s\n' "$HOME/.bun/bin/bun"
  else
    die "bun not available"
  fi
}

bootstrap_bun() {
  printf 'bun not found; bootstrapping...\n' >&2
  command -v curl >/dev/null 2>&1 || die "curl required to bootstrap bun"
  curl -fsSL https://bun.sh/install | bash
}

restore_backup() {
  rm -f "$BIN_DIR/$PROGRAM_NAME"
  if [[ -n "$WRAPPER_BACKUP_PATH" && -f "$WRAPPER_BACKUP_PATH" ]]; then
    mkdir -p "$BIN_DIR"
    cp "$WRAPPER_BACKUP_PATH" "$BIN_DIR/$PROGRAM_NAME"
    chmod +x "$BIN_DIR/$PROGRAM_NAME"
  fi
  rm -rf "$INSTALL_DIR"
  if [[ -d "$BACKUP_DIR" ]]; then
    mv "$BACKUP_DIR" "$INSTALL_DIR"
  fi
}

write_install_meta() {
  cat >"$INSTALL_DIR/install-meta.json" <<EOF
{
  "program": "$PROGRAM_NAME",
  "version": "$VERSION",
  "install_dir": "$INSTALL_DIR",
  "bin_dir": "$BIN_DIR",
  "repo_name": "$REPO_NAME"
}
EOF
}

check_path_hint() {
  case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
      printf '\nPATH hint:\n' >&2
      printf '  Add this to your shell profile:\n' >&2
      printf '  export PATH="%s:$PATH"\n' "$BIN_DIR" >&2
      ;;
  esac
}

verify_checksum() {
  local tarball="$1"
  local checksum_file="$2"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 -c "$checksum_file" >/dev/null 2>&1 || die "checksum verification failed"
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum -c "$checksum_file" >/dev/null 2>&1 || die "checksum verification failed"
  else
    die "need shasum or sha256sum to verify release artifact"
  fi
}

resolve_version() {
  local base_raw_url="$1"
  if [[ "$VERSION" != "latest" ]]; then
    printf '%s\n' "$VERSION"
    return
  fi
  local version_file="$TMP_DIR/VERSION"
  download_file "$base_raw_url/latest/VERSION" "$version_file"
  local resolved
  resolved="$(tr -d '[:space:]' < "$version_file")"
  [[ -n "$resolved" ]] || die "failed to resolve latest version"
  printf '%s\n' "$resolved"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --version)
      [[ $# -ge 2 ]] || die "--version requires a value"
      VERSION="$2"
      shift 2
      ;;
    --upgrade)
      UPGRADE=1
      shift
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
    --repo-name)
      [[ $# -ge 2 ]] || die "--repo-name requires a value"
      REPO_NAME="$2"
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

need tar
need mktemp

if ! command -v bun >/dev/null 2>&1; then
  bootstrap_bun
fi
BUN_BIN="$(resolve_bun)"

TMP_DIR="$(mktemp -d)"
STAGE_DIR="$TMP_DIR/stage"
BACKUP_DIR="$TMP_DIR/backup"
mkdir -p "$STAGE_DIR"

BASE_RAW_URL="${RELEASE_BASE_URL:-https://raw.githubusercontent.com/Caffeine-Ops/fusion-claude-code-releases/main}"
RESOLVED_VERSION="$(resolve_version "$BASE_RAW_URL")"
TARBALL_NAME="${REPO_NAME}-${RESOLVED_VERSION}.tar.gz"
TARBALL_URL="$BASE_RAW_URL/releases/$TARBALL_NAME"
CHECKSUM_URL="$BASE_RAW_URL/releases/$TARBALL_NAME.sha256"
TARBALL_FILE="$TMP_DIR/$TARBALL_NAME"
CHECKSUM_FILE="$TMP_DIR/$TARBALL_NAME.sha256"

printf 'Installing %s %s\n' "$PROGRAM_NAME" "$RESOLVED_VERSION" >&2
printf 'Source: %s\n' "$TARBALL_URL" >&2

if [[ -d "$INSTALL_DIR" ]]; then
  mv "$INSTALL_DIR" "$BACKUP_DIR"
fi

if [[ -f "$BIN_DIR/$PROGRAM_NAME" ]]; then
  WRAPPER_BACKUP_PATH="$TMP_DIR/${PROGRAM_NAME}.wrapper.bak"
  cp "$BIN_DIR/$PROGRAM_NAME" "$WRAPPER_BACKUP_PATH"
fi

mkdir -p "$INSTALL_DIR"

download_file "$TARBALL_URL" "$TARBALL_FILE" || { restore_backup; die "download failed"; }
download_file "$CHECKSUM_URL" "$CHECKSUM_FILE" || { restore_backup; die "checksum download failed"; }

(
  cd "$TMP_DIR"
  verify_checksum "$TARBALL_NAME" "$TARBALL_NAME.sha256"
) || { restore_backup; die "checksum verification failed"; }

tar -xzf "$TARBALL_FILE" -C "$STAGE_DIR" || { restore_backup; die "extract failed"; }

EXTRACTED_ROOT="$STAGE_DIR/${REPO_NAME}-${RESOLVED_VERSION}"
[[ -d "$EXTRACTED_ROOT" ]] || { restore_backup; die "unexpected archive layout: missing $REPO_NAME-$RESOLVED_VERSION root"; }

cp -R "$EXTRACTED_ROOT"/. "$INSTALL_DIR"/ || { restore_backup; die "install copy failed"; }

if [[ -f "$BACKUP_DIR/.env" ]]; then
  cp "$BACKUP_DIR/.env" "$INSTALL_DIR/.env"
elif [[ ! -f "$INSTALL_DIR/.env" ]]; then
  [[ -f "$INSTALL_DIR/release/env.template" ]] || { restore_backup; die "missing release/env.template"; }
  cp "$INSTALL_DIR/release/env.template" "$INSTALL_DIR/.env"
  chmod 600 "$INSTALL_DIR/.env"
fi

[[ -f "$INSTALL_DIR/release/wrapper.sh.template" ]] || { restore_backup; die "missing release/wrapper.sh.template"; }

(cd "$INSTALL_DIR" && "$BUN_BIN" install) || { restore_backup; die "bun install failed"; }

mkdir -p "$BIN_DIR"
sed \
  -e "s|__INSTALL_DIR__|$INSTALL_DIR|g" \
  -e "s|__PROGRAM_NAME__|$PROGRAM_NAME|g" \
  "$INSTALL_DIR/release/wrapper.sh.template" > "$BIN_DIR/$PROGRAM_NAME"
chmod +x "$BIN_DIR/$PROGRAM_NAME"

VERSION="$RESOLVED_VERSION"
write_install_meta
rm -rf "$BACKUP_DIR" 2>/dev/null || true

printf '\nInstall complete.\n' >&2
printf 'Program dir: %s\n' "$INSTALL_DIR" >&2
printf 'Command:     %s/%s\n' "$BIN_DIR" "$PROGRAM_NAME" >&2
printf 'Env file:    %s/.env\n' "$INSTALL_DIR" >&2
printf 'User config: ~/.claude (preserved, untouched)\n' >&2
printf 'Project cfg: .claude/ + CLAUDE.md in working repos\n' >&2
check_path_hint
printf '\nNext steps:\n' >&2
printf '  1. Edit %s/.env\n' "$INSTALL_DIR" >&2
printf '  2. Run: %s\n' "$PROGRAM_NAME" >&2

[[ "$UPGRADE" -eq 1 ]] && printf '\nUpgrade complete.\n' >&2
