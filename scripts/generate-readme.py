#!/usr/bin/env python3
"""根据 skills/ 下的 skill 自动刷新 README.md 中的 skill 列表。

只替换 `<!-- SKILLS:BEGIN -->` 与 `<!-- SKILLS:END -->` 之间的内容，
其他区域保持原样。仅使用标准库。
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = REPO_ROOT / "skills"
README_PATH = REPO_ROOT / "README.md"

BEGIN = "<!-- SKILLS:BEGIN -->"
END = "<!-- SKILLS:END -->"


def parse_frontmatter(text: str) -> dict[str, str]:
    if not text.startswith("---"):
        return {}
    end = text.find("\n---", 3)
    if end == -1:
        return {}
    block = text[3:end].strip("\n")
    out: dict[str, str] = {}
    for raw in block.splitlines():
        line = raw.rstrip()
        if not line or line.lstrip().startswith("#") or ":" not in line:
            continue
        key, _, value = line.partition(":")
        out[key.strip()] = value.strip().strip('"').strip("'")
    return out


def collect_skills() -> list[tuple[str, str]]:
    items: list[tuple[str, str]] = []
    if not SKILLS_DIR.exists():
        return items
    for skill_dir in sorted(SKILLS_DIR.iterdir()):
        if not skill_dir.is_dir() or skill_dir.name.startswith("_"):
            continue
        skill_md = skill_dir / "SKILL.md"
        if not skill_md.exists():
            continue
        fm = parse_frontmatter(skill_md.read_text(encoding="utf-8"))
        name = fm.get("name", skill_dir.name)
        desc = fm.get("description", "")
        items.append((name, desc))
    return items


def render(items: list[tuple[str, str]]) -> str:
    if not items:
        return "_暂无 skill。运行 `./install/install.sh` 之前请先添加 skill 到 `skills/` 目录。_"

    lines = ["| Skill | 描述 |", "| --- | --- |"]
    for name, desc in items:
        link = f"[`{name}`](./skills/{name}/)"
        safe_desc = desc.replace("|", "\\|") if desc else "_(无描述)_"
        lines.append(f"| {link} | {safe_desc} |")
    return "\n".join(lines)


def main() -> int:
    if not README_PATH.exists():
        print(f"[ERROR] README.md 不存在: {README_PATH}", file=sys.stderr)
        return 1

    original = README_PATH.read_text(encoding="utf-8")
    block = render(collect_skills())
    replacement = f"{BEGIN}\n\n{block}\n\n{END}"

    pattern = re.compile(
        re.escape(BEGIN) + r".*?" + re.escape(END),
        re.DOTALL,
    )
    if not pattern.search(original):
        print(
            f"[ERROR] README.md 中找不到 {BEGIN} / {END} 占位符",
            file=sys.stderr,
        )
        return 1

    updated = pattern.sub(replacement, original)
    if updated == original:
        print("[INFO] README.md 无需更新。")
        return 0

    README_PATH.write_text(updated, encoding="utf-8")
    print("[OK] README.md 已更新。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
