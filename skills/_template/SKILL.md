---
name: _template
description: Skill 模板，复制本目录后修改 name/description 即可作为新 skill 的起点。不要直接安装本模板。
license: MIT
---

# Skill 模板

> 这是一个示例模板。复制 `skills/_template/` 到 `skills/<your-skill-name>/`，然后修改本文件。

## 何时使用

在这里清晰描述触发场景。AI 会根据 frontmatter 中的 `description` 判断是否加载本 skill，然后读取本节内容进入工作流。

写作建议：
- 用「当用户……时」开头列出触发条件
- 列出明确**不**适用的反例，避免误触发

## 工作流程

按顺序描述 AI 应执行的步骤：

1. 收集上下文（哪些文件 / 哪些参数）
2. 调用脚本或执行操作
3. 输出结果（格式、保存位置）

## 使用示例

````
用户：帮我做 X
AI：（触发本 skill，执行 ...）
````

## 资源

- `scripts/example.py` — 示例脚本，说明它做什么
- `references/` — 可选，放参考资料 / 长文档 / 数据，AI 按需读取

## 注意事项

- 保持 SKILL.md 精简；细节请放进 `references/` 子目录
- 不要把敏感信息（API Key 等）写进 skill 文件
