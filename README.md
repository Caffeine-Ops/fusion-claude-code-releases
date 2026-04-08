# fusion-claude-code-releases

Release repository for **Fusion Claude Code** install assets and packaged source distributions.

This repository is **not** the main source repository.
It exists to host:

- `install.sh`
- `uninstall.sh`
- packaged release tarballs
- checksums
- the latest version pointer

## Source repository

Main source code lives in:

- `git@github.com:Caffeine-Ops/fusion-claude-code.git`

## Quick install

Install the latest version:

```bash
curl -fsSL https://raw.githubusercontent.com/Caffeine-Ops/fusion-claude-code-releases/main/install.sh | bash
```

After installation, run:

```bash
claude-fusion
```

## Install a specific version

```bash
curl -fsSL https://raw.githubusercontent.com/Caffeine-Ops/fusion-claude-code-releases/main/install.sh | bash -s -- --version v0.1.0
```

## Upgrade

```bash
curl -fsSL https://raw.githubusercontent.com/Caffeine-Ops/fusion-claude-code-releases/main/install.sh | bash -s -- --upgrade
```

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/Caffeine-Ops/fusion-claude-code-releases/main/uninstall.sh | bash
```

## Install layout

Program files are installed to:

```bash
~/.claude-fusion
```

Global command wrapper is installed to:

```bash
~/.local/bin/claude-fusion
```

Runtime environment file is stored at:

```bash
~/.claude-fusion/.env
```

## User config vs program install

This installer keeps program files and user Claude config separate.

### Program install directory

```bash
~/.claude-fusion
```

### User-level Claude config

```bash
~/.claude
```

The installer does **not** overwrite or delete `~/.claude`.

Project-level config is still read from the working repository, including:

- `.claude/settings.json`
- `.claude/settings.local.json`
- `CLAUDE.md`
- `.claude/rules/*`

## Release structure

Typical repository layout:

```text
install.sh
uninstall.sh
checksums.txt
latest/
  VERSION
releases/
  claude-code-haha-v0.1.0.tar.gz
  claude-code-haha-v0.1.0.tar.gz.sha256
```

## Verify downloaded artifacts

If you download a tarball manually, verify it with:

### macOS

```bash
shasum -a 256 -c releases/claude-code-haha-v0.1.0.tar.gz.sha256
```

### Linux

```bash
sha256sum -c releases/claude-code-haha-v0.1.0.tar.gz.sha256
```

## Maintainer flow

From the source repository:

### 1. Package a release

```bash
./release/package-release.sh v0.1.0
```

### 2. Sync assets into this release repo

```bash
./release/sync-release-repo.sh v0.1.0 --release-repo-dir ~/code/fusion-claude-code-releases --commit
```

### 3. Review and push manually

```bash
cd ~/code/fusion-claude-code-releases
git status
git push
```

## Notes

- This release system currently distributes a source-based Bun app, not a single compiled binary.
- The installer bootstraps Bun if needed.
- `install.sh` preserves existing installs on failure using rollback logic.
- `sync-release-repo.sh` validates the target repo before copying release assets.
