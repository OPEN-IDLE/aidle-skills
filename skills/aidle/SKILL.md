---
name: aidle
description: Meta-skill for managing aidle-skills installations. Trigger this skill whenever the user wants to install, uninstall, list, or update skills from the aidle-skills repo using natural language. Examples include "装一下 image-gen", "安装 aidle 里的 xxx skill", "卸载 image-gen", "列出可用 skill / 看看有哪些 skill", "更新 aidle-skills / 拉一下最新", "install image-gen", "uninstall xxx", "list aidle skills", "update aidle". Resolves the aidle-skills repo via ~/.aidle/repo, invokes the install/uninstall scripts, and reports the result.
license: MIT
---

# aidle — Skill Manager

This meta-skill lets the user manage the [aidle-skills](https://github.com/OPEN-IDLE/aidle-skills)
repo through natural language inside Claude Code / Codex.

## When to use

Trigger this skill when the user expresses any of these intents:

- **Install**: "装一下 image-gen", "安装 X skill", "install image-gen", "把 aidle 里的 X 装上"
- **Uninstall**: "卸载 image-gen", "移除 X skill", "uninstall X"
- **List**: "列出可用的 skill", "看看 aidle 里有哪些 skill", "list aidle skills"
- **Update**: "更新 aidle-skills", "拉一下最新的 skill", "update aidle"
- **Re-install / fix**: "重装 image-gen", "image-gen 坏了"

If a request only relates to running an already-installed skill (e.g. "画一张猫"),
do **not** trigger this skill — let the target skill handle it directly.

## Required context

The repo root is recorded at `~/.aidle/repo` by `install/install.sh` on first run.
Use it like this:

```bash
REPO="$(cat ~/.aidle/repo)"
```

If the file does not exist, tell the user:

> 还没初始化 aidle-skills。请先 `git clone https://github.com/OPEN-IDLE/aidle-skills.git`，
> 然后在仓库目录运行 `./install/install.sh --skill aidle`。

## Workflow

### 1. Install a skill

```bash
REPO="$(cat ~/.aidle/repo)"
bash "$REPO/install/install.sh" --skill <name>             # both targets
bash "$REPO/install/install.sh" --skill <name> --target claude
bash "$REPO/install/install.sh" --skill <name> --target codex
bash "$REPO/install/install.sh" --all                       # install everything
```

Default target is **both** Claude Code and Codex. Only narrow it down when the
user explicitly says "只装 Claude" / "only Claude" / "just for Codex" etc.

### 2. Uninstall a skill

```bash
REPO="$(cat ~/.aidle/repo)"
bash "$REPO/install/uninstall.sh" --skill <name>
bash "$REPO/install/uninstall.sh" --skill <name> --target claude
bash "$REPO/install/uninstall.sh" --all
```

### 3. List available skills

```bash
REPO="$(cat ~/.aidle/repo)"
bash "$REPO/install/install.sh" --list
```

Show the output as-is (it includes name + description per line).

### 4. Update aidle-skills

```bash
REPO="$(cat ~/.aidle/repo)"
git -C "$REPO" pull --ff-only
```

After updating, ask the user if they want to re-install the skills they had
before (since SKILL.md or scripts may have changed).

## Reporting

After any action, briefly tell the user:

- What was done (e.g. "已把 image-gen 装到 Claude Code 和 Codex")
- Where it landed (`~/.claude/skills/<name>/`, `~/.codex/skills/<name>/`)
- Any next step (e.g. "重启 Claude Code 会话以加载新 skill")

## Edge cases

- **Skill not found**: run `--list` and show the user available names.
- **Target dir not writable**: report the path and suggest `chmod` or different `$HOME`.
- **No `~/.aidle/repo`**: print the bootstrap instructions above.
- **Permission denied on scripts**: `chmod +x` the relevant `install/*.sh` and retry.
- **Network failure during `git pull`**: report the error verbatim; do not retry silently.

## Safety

- Never run destructive commands (`rm -rf` outside the skill's install dir) without confirming.
- Never modify files **inside** `$REPO` from this skill — that's developer territory.
- Honor `--dry-run` if the user asks "看看会发生什么 / dry run".
