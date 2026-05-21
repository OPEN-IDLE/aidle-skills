#!/usr/bin/env python3
"""示例脚本：演示 skill 的脚本应当如何组织。

约定：
- 仅依赖标准库（无外部依赖）
- 通过 argparse 暴露参数
- 输出结构化结果（JSON / 纯文本），便于 AI 解析
"""

from __future__ import annotations

import argparse
import json
import sys


def run(name: str) -> dict[str, str]:
    return {"greeting": f"hello, {name}"}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Example script for skill template.")
    parser.add_argument("--name", default="world", help="名字")
    parser.add_argument("--json", action="store_true", help="以 JSON 输出")
    args = parser.parse_args(argv)

    result = run(args.name)
    if args.json:
        print(json.dumps(result, ensure_ascii=False))
    else:
        print(result["greeting"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
