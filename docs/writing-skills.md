# 如何编写一个 skill

本指南帮助你写出一个 AI 真正能用得上的 skill。

## 概念回顾

一个 skill 是一个目录，至少包含一个 `SKILL.md`，可选包含脚本、参考资料等：

```
skills/my-skill/
├── SKILL.md          ← 必须，AI 入口文件
├── README.md         ← 给用户看的说明
├── scripts/          ← 可选，确定性脚本
└── references/       ← 可选，长文档 / 数据
```

## SKILL.md 协议

遵循 [Anthropic Agent Skills 协议](https://docs.claude.com/en/docs/agents-and-tools/agent-skills)：

```markdown
---
name: my-skill
description: 一句话讲清楚何时触发、能做什么
license: MIT
---

# Skill 标题

## 何时使用
...

## 工作流程
...
```

### frontmatter 字段

| 字段          | 必填 | 说明                                                         |
|---------------|------|--------------------------------------------------------------|
| `name`        | ✅   | 与目录名一致，kebab-case，仅小写字母、数字、`-`              |
| `description` | ✅   | ≤ 1024 字符（协议上限），一句话讲清楚触发场景。AI 据此判断是否加载本 skill |
| `license`     | ❌   | 默认 MIT                                                     |

### description 写作要点

AI 是根据 `description` 决定要不要加载 skill 的，写不好就永远不会被触发。

❌ 不好：
```
description: 处理 git 相关操作
```

✅ 好：
```
description: 当用户需要生成 conventional commits 风格的提交信息、查看变更摘要、或快速理清当前分支状态时使用
```

写法：
- 用"当用户……时使用"开头列触发条件
- 列出关键动词和名词（commit / pr / 分支 / 摘要）
- 不要写实现细节

## Progressive Disclosure（按需展开）

SKILL.md 本身要**精简**。只放：
- 触发判定（何时使用）
- 总体工作流程
- 关键产出格式

长内容（schema、示例、prompt 片段、参考文档）应放到 `references/` 下，让 AI 在需要时显式读取：

```markdown
## 参考资料

- `references/api-schema.json` — 完整 API schema，必要时读取
- `references/prompt-examples.md` — 提示词样例
```

## 脚本（可选）

如果某些步骤需要**确定性**结果（如格式化 JSON、调用 git），用脚本代替让 AI 现场写：

- 仅依赖标准库
- 参数用 `argparse`（Python）或 `getopts`（Bash）
- 输出可被 AI 解析（JSON 优先）

放在 `scripts/` 目录，在 SKILL.md 中引用：

```markdown
## 执行步骤

1. 调用 `scripts/smart_commit.py --json` 获取变更摘要
2. ...
```

## 校验

提交前本地跑一次：

```bash
python3 scripts/validate-skills.py
```

校验内容：
- `SKILL.md` 存在
- frontmatter 合法（必填字段、`name` 匹配目录）
- `description` 长度合理
- `README.md` 存在

## 调试技巧

1. 安装到本地后，用 Claude Code 启动会话
2. 问："你能列出可用的 skill 吗？" 确认它被识别
3. 用接近真实的提示词触发，观察是否加载
4. 如果没触发，调整 `description` 中的关键词

## 🔐 安全约定（强制）

- **绝不**把 API key / token / 密码 / 私有 URL 写进 SKILL.md、README、脚本
- 示例值必须是明显占位符：`sk-xxxxxxxx`、`<your-token>`、`example.com`
- 密钥读取统一从：env → `~/.aidle/config.env` → 工具兼容路径
- 报错日志不能 echo 出 key 的值
- 新增敏感文件类型时同步更新仓库根的 `.gitignore`

详见 [docs/security.md](./security.md)。CI 会用 gitleaks 自动扫描，命中即拒绝合并。

## Checklist

提交 PR 前确认：

- [ ] `SKILL.md` 的 `name` 与目录名一致
- [ ] `description` 清晰、有触发关键词
- [ ] 主体内容精简，长内容已挪到 `references/`
- [ ] 脚本只依赖标准库
- [ ] `python3 scripts/validate-skills.py` 通过
- [ ] `README.md` 解释了使用场景和示例
- [ ] **没有任何真实密钥 / token / 私有 URL**，示例用 `sk-xxxxxxxx` 等占位符
