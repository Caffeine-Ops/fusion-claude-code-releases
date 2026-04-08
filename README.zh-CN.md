# fusion-claude-code-releases

这个仓库用于存放 **Fusion Claude Code** 的发布产物与安装脚本。

它**不是源码仓库**，主要用于托管：

- `install.sh`
- `uninstall.sh`
- 发布版本 tar.gz 包
- checksum 校验文件
- 最新版本指针

## 源码仓库

主源码仓库在：

- `git@github.com:Caffeine-Ops/fusion-claude-code.git`

---

## 快速安装

安装最新版本：

```bash
curl -fsSL https://raw.githubusercontent.com/Caffeine-Ops/fusion-claude-code-releases/main/install.sh | bash
```

安装完成后运行：

```bash
claude-fusion
```

---

## 安装指定版本

```bash
curl -fsSL https://raw.githubusercontent.com/Caffeine-Ops/fusion-claude-code-releases/main/install.sh | bash -s -- --version v0.1.0
```

---

## 升级

```bash
curl -fsSL https://raw.githubusercontent.com/Caffeine-Ops/fusion-claude-code-releases/main/install.sh | bash -s -- --upgrade
```

---

## 卸载

```bash
curl -fsSL https://raw.githubusercontent.com/Caffeine-Ops/fusion-claude-code-releases/main/uninstall.sh | bash
```

---

## 安装后的目录结构

程序文件安装到：

```bash
~/.claude-fusion
```

全局命令安装到：

```bash
~/.local/bin/claude-fusion
```

运行时环境变量文件位于：

```bash
~/.claude-fusion/.env
```

---

## 用户配置与程序安装目录的区别

这个安装方案会把“程序文件”和“用户 Claude 配置”分开。

### 程序安装目录

```bash
~/.claude-fusion
```

### 用户级 Claude 配置目录

```bash
~/.claude
```

安装脚本**不会覆盖或删除** `~/.claude`。

项目级配置仍然会从当前工作仓库读取，例如：

- `.claude/settings.json`
- `.claude/settings.local.json`
- `CLAUDE.md`
- `.claude/rules/*`

---

## 发布仓库结构

典型目录结构如下：

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

---

## 校验下载文件

如果你是手动下载 tar.gz 包，可以这样校验：

### macOS

```bash
shasum -a 256 -c releases/claude-code-haha-v0.1.0.tar.gz.sha256
```

### Linux

```bash
sha256sum -c releases/claude-code-haha-v0.1.0.tar.gz.sha256
```

---

## 维护者发布流程

在源码仓库中执行：

### 1. 打包发布文件

```bash
./release/package-release.sh v0.1.0
```

### 2. 同步发布产物到这个 release 仓库

```bash
./release/sync-release-repo.sh v0.1.0 --release-repo-dir ~/code/fusion-claude-code-releases --commit
```

### 3. 手动检查并推送

```bash
cd ~/code/fusion-claude-code-releases
git status
git push
```

---

## 说明

- 当前发布的是一个 **基于 Bun 的源码运行版本**，不是单独编译好的单文件二进制。
- 如果系统没有 Bun，安装脚本会尝试自动安装 Bun。
- `install.sh` 在失败时会尽量回滚旧安装目录与 wrapper。
- `sync-release-repo.sh` 会在同步前校验目标仓库，避免把文件复制到错误的 git 仓库里。
