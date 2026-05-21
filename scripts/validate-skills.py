#!/usr/bin/env python3
"""校验 skills/ 下所有 skill 的格式。

退出码：
    0 - 全部通过
    1 - 存在错误

校验项：
- 每个 skill 目录必须有 SKILL.md
- SKILL.md 顶部必须有 YAML frontmatter
- frontmatter 必填字段: name, description
- name 必须与目录名一致，且为 kebab-case
- description 长度 <= 200
- 建议存在 README.md（仅 warning）

仅使用标准库。
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = REPO_ROOT / "skills"

NAME_PATTERN = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
DESCRIPTION_MAX_LEN = 1024  # Anthropic Agent Skills 协议上限


class Issue:
    def __init__(self, skill: str, level: str, message: str) -> None:
        self.skill = skill
        self.level = level  # error | warning
        self.message = message

    def __str__(self) -> str:
        tag = "ERROR" if self.level == "error" else "WARN "
        return f"[{tag}] {self.skill}: {self.message}"


def parse_frontmatter(text: str) -> dict[str, str] | None:
    """简易 YAML frontmatter 解析（仅支持顶层 `key: value`）。"""
    if not text.startswith("---"):
        return None
    end = text.find("\n---", 3)
    if end == -1:
        return None
    block = text[3:end].strip("\n")
    result: dict[str, str] = {}
    for raw_line in block.splitlines():
        line = raw_line.rstrip()
        if not line or line.lstrip().startswith("#"):
            continue
        if ":" not in line:
            continue
        key, _, value = line.partition(":")
        result[key.strip()] = value.strip().strip('"').strip("'")
    return result


def validate_skill(skill_dir: Path) -> list[Issue]:
    name = skill_dir.name
    issues: list[Issue] = []

    if name.startswith("_"):
        # 模板等内部目录跳过严格校验，但仍要求结构基本完整
        skill_md = skill_dir / "SKILL.md"
        if not skill_md.exists():
            issues.append(Issue(name, "error", "缺少 SKILL.md"))
        return issues

    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        issues.append(Issue(name, "error", "缺少 SKILL.md"))
        return issues

    text = skill_md.read_text(encoding="utf-8")
    fm = parse_frontmatter(text)
    if fm is None:
        issues.append(Issue(name, "error", "SKILL.md 缺少有效的 YAML frontmatter"))
        return issues

    if "name" not in fm:
        issues.append(Issue(name, "error", "frontmatter 缺少必填字段: name"))
    elif fm["name"] != name:
        issues.append(Issue(name, "error", f"frontmatter.name ({fm['name']!r}) 与目录名 ({name!r}) 不一致"))
    elif not NAME_PATTERN.match(fm["name"]):
        issues.append(Issue(name, "error", f"name 必须是 kebab-case: {fm['name']!r}"))

    if "description" not in fm:
        issues.append(Issue(name, "error", "frontmatter 缺少必填字段: description"))
    else:
        desc = fm["description"]
        if not desc:
            issues.append(Issue(name, "error", "description 不能为空"))
        elif len(desc) > DESCRIPTION_MAX_LEN:
            issues.append(
                Issue(name, "error", f"description 过长 ({len(desc)} > {DESCRIPTION_MAX_LEN})")
            )

    readme = skill_dir / "README.md"
    if not readme.exists():
        issues.append(Issue(name, "warning", "建议添加 README.md"))

    return issues


def main() -> int:
    if not SKILLS_DIR.exists():
        print(f"[ERROR] skills 目录不存在: {SKILLS_DIR}", file=sys.stderr)
        return 1

    skill_dirs = sorted(p for p in SKILLS_DIR.iterdir() if p.is_dir())
    if not skill_dirs:
        print("[INFO] 暂无 skill 目录。")
        return 0

    all_issues: list[Issue] = []
    for d in skill_dirs:
        all_issues.extend(validate_skill(d))

    errors = [i for i in all_issues if i.level == "error"]
    warnings = [i for i in all_issues if i.level == "warning"]

    for issue in all_issues:
        print(str(issue))

    print()
    print(f"扫描 {len(skill_dirs)} 个 skill，错误 {len(errors)} 条，警告 {len(warnings)} 条。")

    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
