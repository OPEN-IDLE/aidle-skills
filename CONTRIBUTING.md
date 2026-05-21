# 贡献指南

感谢你对 `aidle-skills` 感兴趣！本文档说明如何参与贡献。

## 你可以做什么

- 🐛 报告 Bug
- 💡 提议新 skill
- ✍️ 编写并提交新 skill
- 📝 改进文档
- 🔧 优化安装脚本 / CI

## 提交新 skill 的流程

### 1. 复制模板

```bash
cp -r skills/_template skills/my-skill
```

### 2. 修改 `SKILL.md`

按 [Anthropic Agent Skills 协议](https://docs.claude.com/en/docs/agents-and-tools/agent-skills) 编写：

```markdown
---
name: my-skill
description: 一句话讲清楚这个 skill 何时触发、能做什么
---

# My Skill

## 何时使用
...

## 工作流程
...
```

要点：
- `name` 必须与目录名一致，使用 kebab-case
- `description` 一句话说清楚 **何时用 + 能做什么**，AI 根据它判断是否加载
- 主体内容遵循 progressive disclosure：先精简，必要细节放进 `references/` 子目录

详见 [docs/writing-skills.md](./docs/writing-skills.md)。

### 3. 本地校验

```bash
python3 scripts/validate-skills.py
```

校验项：
- `SKILL.md` 是否存在
- frontmatter 是否合法（必填字段、字段长度）
- `name` 是否与目录名匹配
- `README.md` 是否存在

### 4. 更新 README

```bash
python3 scripts/generate-readme.py
```

会自动刷新 README.md 中的 skill 列表。

### 5. 提交 PR

- 标题：`feat(skill): add <skill-name>`
- 在 PR 描述中说明触发场景和价值
- CI 会自动跑 `validate.yml`

## 代码规范

- Shell 脚本：尽量 POSIX 兼容；使用 `shellcheck` 检查
- Python 脚本：标准库优先，不引入额外依赖
- Markdown：行宽不强制，但段落之间留空行

## 提 Issue

- Bug：使用 `bug_report.md` 模板，附上复现步骤、环境
- 新 skill 建议：使用 `new_skill.md` 模板
- 功能请求：使用 `feature_request.md` 模板

## 🔐 安全规约（必读）

**任何密钥、token、密码、私有 URL 都不能进入 git 仓库。**

要点：

- 真实 key 只放在 `~/.aidle/config.env`（已被 `.gitignore` 排除）
- 文档与脚本里的示例值必须用明显占位符（`sk-xxxxxxxx` / `<your-token>`）
- 不要硬编码 BASE_URL、内网地址等敏感信息
- CI 已启用 gitleaks 自动扫描，命中即拒绝合并

完整规约见 [docs/security.md](./docs/security.md)。

## License

提交即表示你同意将贡献以 [MIT License](./LICENSE) 发布。
