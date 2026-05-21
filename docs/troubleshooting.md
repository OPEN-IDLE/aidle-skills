# 常见问题

## 安装

### `Permission denied: ./install/install.sh`

给脚本加执行权限：

```bash
chmod +x install/install.sh install/uninstall.sh
```

### `command not found: bash`（Windows）

在 Windows 上请使用 PowerShell 脚本：

```powershell
./install/install.ps1
```

### `--target` 参数报错

合法值仅有 `all` / `claude` / `codex`。

### skill 装到了错误的目录

通过环境变量明确指定：

```bash
CLAUDE_SKILLS_DIR=$HOME/.claude/skills CODEX_SKILLS_DIR=$HOME/.codex/skills \
  ./install/install.sh --all
```

## 运行时

### Claude Code 看不到我安装的 skill

依次检查：

1. `ls ~/.claude/skills/` 确认目录存在且包含 SKILL.md
2. 重启 Claude Code 会话
3. 在会话里直接问："请列出当前可用的 skill"
4. 检查 SKILL.md frontmatter 是否合法（运行 `python3 scripts/validate-skills.py`）

### skill 安装了但 AI 不调用

最常见原因：`description` 没有覆盖用户真实表达。

修改 `SKILL.md` 的 `description`，把用户可能用到的关键词写进去。详见 [writing-skills.md](./writing-skills.md#description-写作要点)。

### Codex 不能正确解析 SKILL.md

Codex 的原生 skill 支持仍在演进。如果遇到问题：

1. 在 issue 中描述具体表现（贴出 Codex 报错或日志）
2. 临时方案：把 skill 内容贴到 Codex 的 `AGENTS.md` 中

## 贡献相关

### `validate-skills.py` 失败

报错会指出具体问题（缺字段 / name 不匹配 / description 过长等），按提示修复即可。

### 我想本地测试一个尚未提交的 skill

直接把 `skills/<name>/` 软链到目标目录：

```bash
ln -s "$(pwd)/skills/my-skill" "$HOME/.claude/skills/my-skill"
```

迭代时无需重复安装。
