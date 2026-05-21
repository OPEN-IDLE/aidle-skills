---
name: image-gen
description: Generate or edit images using gpt-image-2 via AiPai relay. Use this skill whenever the user asks to create, generate, draw, paint, make, 修改、P图、以某人为参考、用这张图 or otherwise produce/modify an image, illustration, photo, logo, poster, or visual artwork. Supports text-to-image, single/multi-image reference editing, inpainting with mask, 1k/2k/4k resolutions (or explicit WxH like 1024x1536), quality levels, and batch generation. Saves output to ~/Downloads with a timestamp.
license: MIT
---

# Image Generation & Editing Skill

Generates and edits images using `gpt-image-2` through the AiPai API relay.
Supports three modes: text-to-image, image edit with reference(s), and inpainting.

> **Script paths** — replace `<SKILL_ROOT>` below with the install location:
> - Claude Code: `~/.claude/skills/image-gen`
> - Codex: `~/.codex/skills/image-gen`
>
> **Platform** — pick the script that matches the host OS:
> - macOS / Linux: `<SKILL_ROOT>/scripts/generate.sh` (bash + curl + python3)
> - Windows (PowerShell 7+): `<SKILL_ROOT>/scripts/generate.ps1`
>
> All examples below use the bash form. On Windows, swap `bash <SKILL_ROOT>/scripts/generate.sh ...`
> for `pwsh <SKILL_ROOT>/scripts/generate.ps1 ...` and use `$env:VAR = "value"` for env vars.

## When to use

Trigger this skill whenever the user asks to:
- Text-to-image: "生成一张 ...", "画一张 ...", "做一张 ...", "Generate/Create an image of ..."
- Image edit / reference: "以这张图为参考 ...", "用我这张照片 ...", "让这个人 ...", "把背景换成 ...", "edit this image ..."
- Inpainting: "把这部分改成 ...", "replace the masked area with ..."
- Any deliverable that is a visual image file

If the user provides one or more input images along with the request, use **edit mode** (pass image paths as extra args). Otherwise use text-to-image mode.

## How to use

### 1. Text-to-image

```bash
bash <SKILL_ROOT>/scripts/generate.sh "your prompt here"
```

### 2. Image edit with reference(s)

Pass one or more reference image paths after the prompt. The model will use them as visual/identity references.

```bash
# Single reference (e.g. keep a person's face)
bash <SKILL_ROOT>/scripts/generate.sh "prompt" /path/to/ref.png

# Multiple references (e.g. person + product)
bash <SKILL_ROOT>/scripts/generate.sh "prompt" /path/to/person.png /path/to/product.png
```

### 3. Inpainting with a mask

Provide a mask PNG whose transparent area marks the region to edit.

```bash
IMG_MASK=/path/to/mask.png bash <SKILL_ROOT>/scripts/generate.sh "prompt" /path/to/ref.png
```

## Environment variables

| Var | Default | Options / Notes |
|-----|---------|-----------------|
| `IMG_SIZE` | `1k` | `1k` → `1024x1024`, `2k` → `2048x2048`, `4k` → `4096x4096`; or explicit `WxH` like `1024x1536` (portrait), `1536x1024` (landscape), `1792x1024`, `1024x1792` |
| `IMG_MODEL` | `gpt-image-2` | any model the relay supports |
| `IMG_QUALITY` | *(model default)* | `low` / `medium` / `high` / `auto` |
| `IMG_N` | `1` | number of variants to generate (each saved with `_N` suffix) |
| `IMG_MASK` | — | path to mask PNG for inpainting (edit mode only) |
| `IMG_OUT` | `~/Downloads/img_<timestamp>.png` | custom output path (when `IMG_N=1`) |
| `AIPAI_API_KEY` | from `~/.codex/auth.json` | override API key |
| `AIPAI_BASE_URL` | `https://aipai.vip/v1` | override relay URL |

## Examples

```bash
# 2k square (defaults to 1k if omitted)
IMG_SIZE=2k bash <SKILL_ROOT>/scripts/generate.sh "cyberpunk cat, neon lights"

# 4k cinematic wallpaper
IMG_SIZE=4k bash <SKILL_ROOT>/scripts/generate.sh "cinematic mountain sunrise"

# Cinematic landscape, explicit aspect ratio
IMG_SIZE=1536x1024 bash <SKILL_ROOT>/scripts/generate.sh "cinematic mountain sunrise"

# 4 variants of a logo
IMG_N=4 bash <SKILL_ROOT>/scripts/generate.sh "minimalist coffee shop logo, vector, flat"

# High-quality portrait poster using user's selfie as identity reference
IMG_SIZE=1024x1536 IMG_QUALITY=high bash <SKILL_ROOT>/scripts/generate.sh \
  "Chinese seasoning ad poster, warm lighting, slogan '正宗好味 厨房必备'" \
  ~/Pictures/selfie.png

# Inpaint: replace masked sky with fireworks
IMG_MASK=~/Pictures/sky_mask.png bash <SKILL_ROOT>/scripts/generate.sh \
  "night sky with colorful fireworks" ~/Pictures/skyline.png
```

## Output

```
🎨 Editing with 1 reference(s) (gpt-image-2, 1024x1536, n=1) ...
✅ Saved: /Users/you/Downloads/img_20260424_165133.png
📝 Revised prompt: ...
```

- macOS: first saved image auto-opens in Preview
- Windows: first saved image auto-opens via `Invoke-Item` (system default viewer)
- Linux: no auto-open (use `xdg-open` manually if desired)

## Configuration

The script resolves the API key in this order:

1. `$AIPAI_API_KEY` — current process environment
2. `~/.aidle/config.env` — persistent defaults (recommended)
3. `~/.codex/auth.json` — fallback to Codex CLI config

### Recommended: `~/.aidle/config.env`

```bash
mkdir -p ~/.aidle
cat >> ~/.aidle/config.env <<'EOF'
AIPAI_API_KEY=sk-...
AIPAI_BASE_URL=https://aipai.vip/v1
# Optional overrides
# IMG_MODEL=gpt-image-2
# IMG_QUALITY=high
EOF
chmod 600 ~/.aidle/config.env
```

Format: `KEY=VALUE` per line, `#` comments allowed. Process env vars
(e.g. `IMG_SIZE=2k bash generate.sh ...`) always take precedence over this file.
