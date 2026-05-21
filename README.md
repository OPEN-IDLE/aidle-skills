<div align="center">

# aidle-skills

**为 Claude Code 和 Codex 打造的开箱即用 Skill 集合**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Validate](https://github.com/OPEN-IDLE/aidle-skills/actions/workflows/validate.yml/badge.svg)](https://github.com/OPEN-IDLE/aidle-skills/actions/workflows/validate.yml)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](./CONTRIBUTING.md)

[快速开始](#快速开始) · [Skill 列表](#skill-列表) · [文档](./docs) · [贡献指南](./CONTRIBUTING.md)

</div>

---

## 这是什么

`aidle-skills` 是一个面向 **Claude Code** 和 **Codex** 的 Skill 仓库。所有 skill 遵循 [Anthropic Agent Skills 协议](https://docs.claude.com/en/docs/agents-and-tools/agent-skills)（YAML frontmatter + Markdown），可以一键安装到本地，让 AI 助手在合适的时机自动调用对应能力。

- **协议标准**：每个 skill 包含 `SKILL.md`，AI 按需加载
- **跨工具支持**：同一份 skill 同时支持 Claude Code 与 Codex
- **按需安装**：可一次性全部安装，也可只挑某一个
- **可扩展**：自带模板、校验脚本和 CI，便于贡献新 skill

## 🚀 5 分钟跑通 image-gen

完整端到端示例，从零到生成第一张图：

```bash
# ① 克隆仓库
git clone https://github.com/OPEN-IDLE/aidle-skills.git
cd aidle-skills

# ② 装上 aidle meta-skill（之后用自然语言管理其他 skill）
./install/install.sh --skill aidle

# ③ 配置 API key（仅首次需要）
mkdir -p ~/.aidle
cp examples/aidle-config.env.example ~/.aidle/config.env
chmod 600 ~/.aidle/config.env
$EDITOR ~/.aidle/config.env           # 填入 AIPAI_API_KEY=sk-真实值

# ④ 启动 Claude Code 或 Codex，对 AI 说：
#    > 装一下 image-gen
#    > 画一只赛博朋克风格的猫，1k 方图
#
# AI 会自动调用 aidle 安装 image-gen，再调用 image-gen 完成生图。
```

Windows 用户把 `./install/install.sh` 换成 `./install/install.ps1`（需要 PowerShell 5+；image-gen 自身需要 PowerShell 7+）。

## 安装命令一览

```bash
./install/install.sh                                # 交互式
./install/install.sh --list                         # 列出可用 skill（含描述）
./install/install.sh --all                          # 安装全部 skill 到 Claude + Codex
./install/install.sh --skill image-gen              # 单个 skill 装到两端
./install/install.sh --skill image-gen --target claude  # 仅 Claude Code
./install/install.sh --skill image-gen --target codex   # 仅 Codex
./install/install.sh --dry-run                      # 不写盘，仅打印
./install/uninstall.sh --skill image-gen            # 卸载
./install/uninstall.sh --all                        # 全部卸载
```

### 🪄 装完 `aidle` 后，用自然语言管理

```
你：装一下 image-gen
你：把 image-gen 只装到 Codex
你：列出可用的 skill
你：卸载 image-gen
你：更新 aidle-skills
```

详见 [`skills/aidle/`](./skills/aidle/)、[Claude Code 配置指南](./docs/claude-setup.md)、[Codex 配置指南](./docs/codex-setup.md)。

## Skill 列表

> 下方列表由 `scripts/generate-readme.py` 自动生成，请勿手动修改两个 SKILLS 标记之间的内容。

<!-- SKILLS:BEGIN -->

| Skill | 描述 |
| --- | --- |
| [`aidle`](./skills/aidle/) | Meta-skill for managing aidle-skills installations. Trigger this skill whenever the user wants to install, uninstall, list, or update skills from the aidle-skills repo using natural language. Examples include "装一下 image-gen", "安装 aidle 里的 xxx skill", "卸载 image-gen", "列出可用 skill / 看看有哪些 skill", "更新 aidle-skills / 拉一下最新", "install image-gen", "uninstall xxx", "list aidle skills", "update aidle". Resolves the aidle-skills repo via ~/.aidle/repo, invokes the install/uninstall scripts, and reports the result. |
| [`image-gen`](./skills/image-gen/) | Generate or edit images using gpt-image-2 via AiPai relay. Use this skill whenever the user asks to create, generate, draw, paint, make, 修改、P图、以某人为参考、用这张图 or otherwise produce/modify an image, illustration, photo, logo, poster, or visual artwork. Supports text-to-image, single/multi-image reference editing, inpainting with mask, 1k/2k/4k resolutions (or explicit WxH like 1024x1536), quality levels, and batch generation. Saves output to ~/Downloads with a timestamp. |

<!-- SKILLS:END -->

## 项目结构

```
aidle-skills/
├── skills/              核心 skill 集合
│   └── _template/       新 skill 模板（复制后改名即可）
├── install/             安装 / 卸载脚本
├── docs/                配置和编写指南
├── examples/            提示词触发样例
├── scripts/             仓库维护脚本（校验、生成 README）
└── .github/             CI、Issue / PR 模板
```

## 自己写一个 skill

1. 复制模板：`cp -r skills/_template skills/my-skill`
2. 修改 `SKILL.md` 的 frontmatter（`name`、`description`）
3. 编写 skill 主体说明、脚本、参考资料
4. 本地校验：`python3 scripts/validate-skills.py`
5. 提交 PR（参见 [贡献指南](./CONTRIBUTING.md)）

完整指南见 [docs/writing-skills.md](./docs/writing-skills.md)。

## 文档

- [Claude Code 配置指南](./docs/claude-setup.md)
- [Codex 配置指南](./docs/codex-setup.md)
- [如何编写 skill](./docs/writing-skills.md)
- [🔐 安全与隐私规约](./docs/security.md)
- [常见问题](./docs/troubleshooting.md)
- [示例提示词](./examples/sample-prompts.md)
- [配置文件模板](./examples/aidle-config.env.example)

## 贡献

欢迎 PR、Issue、新 skill 建议。开始之前请阅读 [CONTRIBUTING.md](./CONTRIBUTING.md)。

## License

[MIT](./LICENSE) © OPEN-IDLE
