# Codex 配置指南

本指南介绍如何在 Codex 中使用 `aidle-skills`。

## 前置要求

- 已安装 [Codex CLI](https://github.com/openai/codex)
- 终端可执行 `bash`（macOS / Linux）或 `PowerShell`（Windows）

## 安装 skill

### 安装全部

```bash
./install/install.sh --all --target codex
```

### 仅安装某一个

```bash
./install/install.sh --skill <skill-name> --target codex
```

### 自定义安装目录

默认目录为 `~/.codex/skills/`。可通过环境变量覆盖：

```bash
CODEX_SKILLS_DIR=/path/to/skills ./install/install.sh --all --target codex
```

## 验证安装

```bash
ls ~/.codex/skills/
```

每个 skill 应该是一个独立子目录，包含 `SKILL.md`。

## 工作机制

`aidle-skills` 使用与 Anthropic Agent Skills 一致的 SKILL.md 协议（YAML frontmatter + Markdown）。在 Codex 中，这些 skill 会作为可调用的指令片段被代理识别。

> ⚠️ Codex 对 skill 的原生支持仍在演进。如果某个 skill 在 Codex 中表现异常，欢迎在 issue 中反馈。

## 卸载

```bash
./install/uninstall.sh --skill <skill-name> --target codex
./install/uninstall.sh --all --target codex
```

## 常见问题

见 [troubleshooting.md](./troubleshooting.md)。
