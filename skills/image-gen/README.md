# image-gen

> 通过 AiPai 中转调用 `gpt-image-2` 进行图像生成与编辑的 skill。

## 这个 skill 能做什么

- 📝 **文生图**：根据提示词生成新图片
- 🖼️ **以图改图**：传入 1～N 张参考图，做风格 / 主体 / 身份保留的编辑
- 🎯 **局部重绘 (Inpainting)**：提供 mask PNG，仅对透明区域重绘
- 📐 **分辨率档位**：`1k` / `2k` / `4k` 一键切换；也支持任意 `WxH`（如 `1024x1536` 竖图、`1536x1024` 横图）
- 🔢 **批量出图**：一次生成多个变体
- 💾 **自动保存**：输出到 `~/Downloads/img_<时间戳>.png`，macOS 会自动用预览打开

## 安装

```bash
# 仓库根目录
./install/install.sh --skill image-gen              # 同时装到 Claude Code 与 Codex
./install/install.sh --skill image-gen --target claude
./install/install.sh --skill image-gen --target codex
```

安装后脚本位于：

| 平台 | 脚本 |
| --- | --- |
| macOS / Linux | `~/.claude/skills/image-gen/scripts/generate.sh` 或 `~/.codex/skills/image-gen/scripts/generate.sh` |
| Windows (PowerShell 7+) | `~/.claude/skills/image-gen/scripts/generate.ps1` 或 `~/.codex/skills/image-gen/scripts/generate.ps1` |

## 系统依赖

- **macOS / Linux**：`bash`、`curl`、`python3`（macOS 自带，Linux 大多自带）
- **Windows**：[PowerShell 7+](https://github.com/PowerShell/PowerShell/releases)（multipart/form-data 支持依赖 PS 7 的 `Invoke-RestMethod -Form`）

## 触发示例

直接对 AI 助手说：

- 「画一张赛博朋克风格的猫」
- 「以这张图为参考做一张海报」(同时附图)
- 「把图中天空换成烟花」(同时附图 + mask)
- 「生成 4 个 logo 变体」
- 「Generate a cinematic landscape, 1536x1024」

AI 会识别意图并自动调用 `generate.sh`。

## 直接命令行使用

### macOS / Linux

```bash
# 文生图（默认 1k）
bash ~/.claude/skills/image-gen/scripts/generate.sh "cyberpunk cat, neon lights"

# 2k 方图
IMG_SIZE=2k bash ~/.claude/skills/image-gen/scripts/generate.sh "cyberpunk cat, neon lights"

# 4k 壁纸
IMG_SIZE=4k bash ~/.claude/skills/image-gen/scripts/generate.sh "cinematic mountain sunrise"

# 以图改图
bash ~/.claude/skills/image-gen/scripts/generate.sh "make it look like an oil painting" ~/Pictures/cat.png

# 局部重绘
IMG_MASK=~/Pictures/mask.png \
  bash ~/.claude/skills/image-gen/scripts/generate.sh "fireworks in the sky" ~/Pictures/skyline.png

# 批量生成 4 张
IMG_N=4 bash ~/.claude/skills/image-gen/scripts/generate.sh "minimalist coffee shop logo"
```

### Windows (PowerShell 7+)

```powershell
# 文生图（默认 1k）
pwsh ~/.claude/skills/image-gen/scripts/generate.ps1 "cyberpunk cat, neon lights"

# 2k 方图
$env:IMG_SIZE = "2k"
pwsh ~/.claude/skills/image-gen/scripts/generate.ps1 "cyberpunk cat, neon lights"

# 以图改图
pwsh ~/.claude/skills/image-gen/scripts/generate.ps1 "make it look like an oil painting" C:\Pictures\cat.png

# 局部重绘
$env:IMG_MASK = "C:\Pictures\mask.png"
pwsh ~/.claude/skills/image-gen/scripts/generate.ps1 "fireworks in the sky" C:\Pictures\skyline.png

# 批量生成 4 张
$env:IMG_N = "4"
pwsh ~/.claude/skills/image-gen/scripts/generate.ps1 "minimalist coffee shop logo"
```

## 配置项

支持通过环境变量调整，常用项：

| 变量 | 说明 |
| --- | --- |
| `IMG_SIZE` | `1k`（默认，1024×1024）、`2k`（2048×2048）、`4k`（4096×4096）；或显式 `WxH`，如 `1024x1536`（竖）、`1536x1024`（横） |
| `IMG_QUALITY` | `low` / `medium` / `high` / `auto` |
| `IMG_N` | 一次生成几张（默认 1） |
| `IMG_OUT` | 自定义输出路径（仅 `IMG_N=1` 时） |
| `IMG_MASK` | inpainting 用的 mask PNG 路径 |
| `AIPAI_API_KEY` | 覆盖默认 API key |
| `AIPAI_BASE_URL` | 覆盖 relay URL，默认 `https://aipai.vip/v1` |

完整配置见 [SKILL.md](./SKILL.md)。

## 配置 API Key

脚本按以下顺序查找 key：

1. 当前进程环境变量 `AIPAI_API_KEY`
2. 配置文件 `~/.aidle/config.env`（推荐）
3. `~/.codex/auth.json`（Codex CLI 兼容，向后兼容旧用户）

### 推荐方式：`~/.aidle/config.env`

```bash
mkdir -p ~/.aidle
cat >> ~/.aidle/config.env <<'EOF'
AIPAI_API_KEY=sk-...
AIPAI_BASE_URL=https://aipai.vip/v1
# 可选：覆盖默认值
# IMG_MODEL=gpt-image-2
# IMG_QUALITY=high
EOF
chmod 600 ~/.aidle/config.env
```

格式：`KEY=VALUE` 每行一项，支持 `#` 注释。进程环境变量（如 `IMG_SIZE=2k bash generate.sh ...`）优先级最高，会覆盖配置文件。

### 临时覆盖

```bash
export AIPAI_API_KEY=sk-...
```

## 注意事项

- 默认 relay 为 `https://aipai.vip/v1`，不是 OpenAI 官方。如需切换请设置 `AIPAI_BASE_URL`
- 参考图与 mask 必须是真实文件，脚本会校验存在性
- 生成的图默认保存到 `~/Downloads/`，定期清理避免占用磁盘
- 多图编辑时第一张参考用 `image`，多张用 `image[]`（遵循 gpt-image-2 约定）
