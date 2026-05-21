# _template

> 这是一个 skill 模板，**不要直接安装**。

## 用途

为新 skill 提供起点结构，包含：

- `SKILL.md` — Skill 主文件（AI 读取）
- `README.md` — 给用户看的说明
- `scripts/example.py` — 脚本示例

## 如何使用模板

```bash
# 1. 复制模板
cp -r skills/_template skills/my-skill

# 2. 修改 SKILL.md 的 frontmatter 和正文
# 3. 修改本 README.md
# 4. 替换或删除 scripts/example.py
# 5. 校验
python3 scripts/validate-skills.py
```

详见 [docs/writing-skills.md](../../docs/writing-skills.md)。
