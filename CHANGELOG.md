# Changelog

本项目所有重要变更将记录在此文件。

格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### Added
- 项目基础骨架（目录结构、安装脚本、模板、文档、CI）
- Skill 模板 `skills/_template/`
- 安装脚本：`install/install.sh`、`install/install.ps1`、`install/uninstall.sh`
- 校验脚本 `scripts/validate-skills.py`
- README 自动生成脚本 `scripts/generate-readme.py`
- Issue / PR 模板与 GitHub Actions 工作流
- `skills/image-gen/`：通过 AiPai 中转调用 `gpt-image-2` 的图像生成与编辑 skill，支持文生图、参考图编辑、inpainting、批量出图；`IMG_SIZE` 支持 `1k`/`2k`/`4k` 简写或显式 `WxH`
- `skills/aidle/`：meta-skill，安装后可在 Claude Code / Codex 中用自然语言安装 / 卸载 / 列出 / 更新其他 skill
- `~/.aidle/config.env` 通用配置文件：image-gen 等 skill 优先从此处读取 `AIPAI_API_KEY` / `AIPAI_BASE_URL`，env 变量优先级最高
- `install.sh` / `install.ps1` 首次运行时把仓库绝对路径写入 `~/.aidle/repo`，供 aidle meta-skill 定位

### Changed
- 校验脚本 `description` 长度上限由 200 调整为 1024（与 Anthropic Agent Skills 协议一致）
- image-gen 默认模型保持 `gpt-image-2`；API key 来源由"仅 Codex auth.json"扩展为"env > `~/.aidle/config.env` > Codex auth.json"

### Improved
- `image-gen` 新增 Windows 实现 `scripts/generate.ps1`（PowerShell 7+），与 `generate.sh` 功能对等
- `generate.sh` 启动时增加 `curl` / `python3` 依赖检查，缺失时给出明确指引
- `install.sh --list` / `install.ps1 -List` 同时输出 skill 名与描述
- `install.sh` 启动时检查必需依赖（find / cp / mkdir），缺失即报错
- `install.ps1` 启动时检查 PowerShell 5+
- README 重写"快速开始"为「5 分钟跑通 image-gen」端到端流程
- 新增 `.gitleaks.toml` 占位符与示例字符串白名单，避免 CI 误报

### Security
- `.gitignore` 加入完整的密钥 / 凭证 / 证书 / SSH 密钥 / 云厂商配置黑名单
- 新增 `docs/security.md` 安全规约文档，明确"任何密钥永不入库"的核心原则
- 新增 `.github/workflows/secret-scan.yml` 启用 gitleaks 在 PR / push 时自动扫密钥
- 新增 `examples/aidle-config.env.example` 用户配置模板（仅占位符，无真实值）
- CONTRIBUTING / writing-skills / PR 模板加入安全约定与强制 checklist

[Unreleased]: https://github.com/OPEN-IDLE/aidle-skills/compare/HEAD...HEAD
