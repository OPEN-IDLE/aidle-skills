# Claude Code 配置指南

本指南介绍如何在 Claude Code 中使用 `aidle-skills`。

## 前置要求

- 已安装 [Claude Code](https://docs.claude.com/en/docs/claude-code/overview)
- 终端可执行 `bash`（macOS / Linux）或 `PowerShell`（Windows）

## 安装 skill

### 安装全部

```bash
./install/install.sh --all --target claude
```

### 仅安装某一个

```bash
./install/install.sh --skill <skill-name> --target claude
```

### 自定义安装目录

默认目录为 `~/.claude/skills/`。可以通过环境变量覆盖：

```bash
CLAUDE_SKILLS_DIR=/path/to/skills ./install/install.sh --all --target claude
```

## 验证安装

安装完成后查看目录：

```bash
ls ~/.claude/skills/
```

每个 skill 应该是一个独立子目录，包含 `SKILL.md`。

启动 Claude Code 后，可以让它列出已加载的 skill：

```
请列出当前可用的 skill。
```

## 工作机制

Claude Code 启动时会扫描 `~/.claude/skills/` 下的所有 `SKILL.md`，仅读取其中的 frontmatter（`name` + `description`）。当你的提示词与某个 skill 的 `description` 匹配时，Claude 会按需加载完整的 SKILL.md 和相关脚本。

这种 progressive disclosure 设计的好处：
- 上下文窗口不会被未使用的 skill 占用
- 可以同时安装大量 skill 而不影响性能

## 卸载

```bash
./install/uninstall.sh --skill <skill-name> --target claude
./install/uninstall.sh --all --target claude
```

## 常见问题

见 [troubleshooting.md](./troubleshooting.md)。
