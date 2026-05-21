# aidle — Skill 管家

> 一个 **meta-skill**：让你在 Claude Code 或 Codex 里用自然语言安装 / 卸载 / 更新其他 aidle-skills。

## 为什么需要它

装完 `aidle` skill 一次之后，你就**不必再回到命令行**敲 `install.sh` 了。直接对 AI 说：

> 帮我装一下 image-gen
>
> 卸载 git-helper
>
> 看看 aidle 里有哪些 skill
>
> 更新一下 aidle-skills

AI 会自动识别意图、调用对应脚本、把结果反馈给你。

## 安装

第一次仍然要走命令行（鸡生蛋问题）：

```bash
git clone https://github.com/OPEN-IDLE/aidle-skills.git
cd aidle-skills
./install/install.sh --skill aidle
```

安装过程会：

1. 把 `aidle` skill 复制到 `~/.claude/skills/aidle/` 和 `~/.codex/skills/aidle/`
2. 在 `~/.aidle/repo` 中记录仓库的绝对路径（`aidle` skill 用它找到 install/uninstall 脚本）

之后所有 skill 都可以通过 AI 安装。

## 使用示例

启动 Claude Code 或 Codex 之后：

```
你：装一下 image-gen
AI：好的，正在执行 install.sh --skill image-gen ...
    ✅ 已安装到 ~/.claude/skills/image-gen 和 ~/.codex/skills/image-gen
```

```
你：列出可用的 skill
AI：image-gen — 通过 AiPai 中转调用 gpt-image-2 ...
    aidle      — Meta-skill for managing aidle-skills ...
```

```
你：把 image-gen 只装到 Codex
AI：好的，执行 install.sh --skill image-gen --target codex ...
```

```
你：更新一下 aidle-skills
AI：在 <repo> 执行 git pull --ff-only ...
    更新完成，建议重新装一下你正在用的 skill。
```

## 工作原理

`aidle` skill 不包含任何脚本，它的"能力"完全来自 `SKILL.md` 里给 AI 的工作流指引：

1. 从 `~/.aidle/repo` 读取仓库绝对路径
2. 根据用户意图选择 `install.sh` / `uninstall.sh` / `--list` / `git pull`
3. 通过 Bash 工具执行并反馈

因此它对 AI 工具的要求是：**支持 Bash 调用**。Claude Code 与 Codex 都满足。

## 注意事项

- `~/.aidle/repo` 是关键定位文件。如果你移动了仓库目录，请重新跑一次 `./install/install.sh --skill aidle` 让它更新指向。
- AI 调用 install.sh 时不会自动 `git pull`。需要更新源码请显式说「更新 aidle-skills」。
- 涉及破坏性操作（如 `uninstall --all`）时，AI 默认会先与你确认。
