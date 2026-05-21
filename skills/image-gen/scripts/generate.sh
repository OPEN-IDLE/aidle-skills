#!/bin/bash
# Image generation & editing via AiPai relay (gpt-image-2)
# Modes:
#   Text-to-image: generate.sh "prompt"
#   Image edit:    generate.sh "prompt" ref1.png [ref2.png ...]
#   Inpainting:    IMG_MASK=mask.png generate.sh "prompt" ref.png
set -e

if [ -z "$1" ]; then
  cat <<'EOF'
Usage:
  generate.sh "prompt"                          # text-to-image
  generate.sh "prompt" ref.png [ref2.png ...]   # edit with reference image(s)

Env vars:
  IMG_SIZE     1k (default, 1024x1024) | 2k (2048x2048) | 4k (4096x4096)
               also accepts explicit WxH like 1024x1536 / 1536x1024
  IMG_MODEL    gpt-image-2 (default)
  IMG_QUALITY  low | medium | high | auto
  IMG_N        number of images to generate, default 1
  IMG_MASK     path to mask PNG (transparent area = edit region), edit mode only
  IMG_OUT      custom output path (only used when IMG_N=1)
  AIPAI_API_KEY, AIPAI_BASE_URL

Config file (~/.aidle/config.env):
  Persistent defaults for AIPAI_API_KEY / AIPAI_BASE_URL / IMG_MODEL ...
  Format: KEY=VALUE per line. Process env vars take precedence.
EOF
  exit 1
fi

# Sanity check: required commands
for _cmd in curl python3; do
  if ! command -v "$_cmd" >/dev/null 2>&1; then
    echo "❌ Required command not found: $_cmd" >&2
    echo "   Install it first (e.g. macOS: brew install $_cmd  /  Debian: sudo apt install $_cmd)" >&2
    exit 1
  fi
done
unset _cmd

# Load defaults from ~/.aidle/config.env (does NOT override already-set env vars)
load_aidle_config() {
  local file="$HOME/.aidle/config.env"
  [ -f "$file" ] || return 0
  local line key val cur
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue
    [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]*(.*)$ ]] || continue
    key="${BASH_REMATCH[1]}"
    val="${BASH_REMATCH[2]}"
    val="${val#\"}"; val="${val%\"}"
    val="${val#\'}"; val="${val%\'}"
    cur="${!key}"
    if [ -z "$cur" ]; then
      export "$key=$val"
    fi
  done < "$file"
}
load_aidle_config

PROMPT="$1"
shift
REFS=("$@")

SIZE="${IMG_SIZE:-1k}"
MODEL="${IMG_MODEL:-gpt-image-2}"

# Normalize size shortcuts (1k / 2k / 4k -> WxH)
case "$SIZE" in
  1k|1K) SIZE="1024x1024" ;;
  2k|2K) SIZE="2048x2048" ;;
  4k|4K) SIZE="4096x4096" ;;
esac
QUALITY="${IMG_QUALITY:-}"
N="${IMG_N:-1}"
BASE_URL="${AIPAI_BASE_URL:-https://aipai.vip/v1}"
AUTH_FILE="$HOME/.codex/auth.json"
TS="$(date +%Y%m%d_%H%M%S)"
DEFAULT_OUT="$HOME/Downloads/img_${TS}.png"

# Resolve API key: env var first, then auth.json
KEY="$AIPAI_API_KEY"
if [ -z "$KEY" ] && [ -f "$AUTH_FILE" ]; then
  KEY=$(AUTH_FILE="$AUTH_FILE" python3 <<'PYEOF'
import json, os, sys
try:
    with open(os.environ['AUTH_FILE']) as f:
        d = json.load(f)
    for k in ('OPENAI_API_KEY', 'api_key', 'apiKey', 'key'):
        if d.get(k):
            print(d[k]); sys.exit(0)
    for nested in ('tokens', 'openai', 'auth'):
        if isinstance(d.get(nested), dict):
            for k in ('OPENAI_API_KEY', 'api_key', 'apiKey', 'key', 'access_token'):
                if d[nested].get(k):
                    print(d[nested][k]); sys.exit(0)
except Exception as e:
    sys.stderr.write(f'auth.json parse error: {e}\n')
PYEOF
)
fi

if [ -z "$KEY" ]; then
  cat >&2 <<EOF
❌ No API key found. Configure one of:
   1) export AIPAI_API_KEY=sk-...
   2) echo 'AIPAI_API_KEY=sk-...' >> ~/.aidle/config.env
   3) ensure ~/.codex/auth.json contains OPENAI_API_KEY
EOF
  exit 1
fi

TMP_RESP=$(mktemp)
trap 'rm -f "$TMP_RESP"' EXIT

if [ ${#REFS[@]} -eq 0 ]; then
  # -------- Text-to-image: /images/generations --------
  echo "🎨 Generating ($MODEL, $SIZE, n=$N) ..."
  BODY=$(PROMPT="$PROMPT" MODEL="$MODEL" SIZE="$SIZE" QUALITY="$QUALITY" N="$N" python3 <<'PYEOF'
import json, os
body = {
    'model': os.environ['MODEL'],
    'prompt': os.environ['PROMPT'],
    'n': int(os.environ['N']),
    'size': os.environ['SIZE'],
}
if os.environ.get('QUALITY'):
    body['quality'] = os.environ['QUALITY']
print(json.dumps(body))
PYEOF
)
  curl -s "$BASE_URL/images/generations" \
    -H "Authorization: Bearer $KEY" \
    -H "Content-Type: application/json" \
    -d "$BODY" \
    -o "$TMP_RESP"
else
  # -------- Image edit: /images/edits --------
  echo "🎨 Editing with ${#REFS[@]} reference(s) ($MODEL, $SIZE, n=$N) ..."
  for ref in "${REFS[@]}"; do
    if [ ! -f "$ref" ]; then
      echo "❌ Reference file not found: $ref"
      exit 1
    fi
  done

  CURL_ARGS=(-s "$BASE_URL/images/edits"
    -H "Authorization: Bearer $KEY"
    -F "model=$MODEL"
    -F "prompt=$PROMPT"
    -F "size=$SIZE"
    -F "n=$N")

  if [ -n "$QUALITY" ]; then
    CURL_ARGS+=(-F "quality=$QUALITY")
  fi

  # Single image uses `image`, multiple uses `image[]` (gpt-image-2 convention)
  if [ ${#REFS[@]} -eq 1 ]; then
    CURL_ARGS+=(-F "image=@${REFS[0]}")
  else
    for ref in "${REFS[@]}"; do
      CURL_ARGS+=(-F "image[]=@$ref")
    done
  fi

  if [ -n "$IMG_MASK" ]; then
    if [ ! -f "$IMG_MASK" ]; then
      echo "❌ Mask file not found: $IMG_MASK"
      exit 1
    fi
    CURL_ARGS+=(-F "mask=@$IMG_MASK")
  fi

  CURL_ARGS+=(-o "$TMP_RESP")
  curl "${CURL_ARGS[@]}"
fi

# -------- Parse response & save all images --------
RESP_FILE="$TMP_RESP" DEFAULT_OUT="$DEFAULT_OUT" IMG_OUT="${IMG_OUT:-}" TS="$TS" python3 <<'PYEOF'
import sys, json, base64, os, subprocess, urllib.request

with open(os.environ['RESP_FILE']) as f:
    resp_text = f.read()

try:
    data = json.loads(resp_text)
except json.JSONDecodeError:
    print("❌ Invalid JSON response:")
    print(resp_text[:800])
    sys.exit(1)

if 'data' not in data or not data['data']:
    print("❌ Unexpected response:")
    print(json.dumps(data, ensure_ascii=False, indent=2)[:800])
    sys.exit(1)

items = data['data']
custom_out = os.environ.get('IMG_OUT') or ''
default_out = os.environ['DEFAULT_OUT']
ts = os.environ['TS']
saved = []

for i, item in enumerate(items):
    if len(items) == 1 and custom_out:
        out = custom_out
    elif len(items) == 1:
        out = default_out
    else:
        base = custom_out or default_out
        root, ext = os.path.splitext(base)
        out = f"{root}_{i+1}{ext or '.png'}"

    if item.get('b64_json'):
        with open(out, 'wb') as f:
            f.write(base64.b64decode(item['b64_json']))
    elif item.get('url'):
        urllib.request.urlretrieve(item['url'], out)
    else:
        print(f"❌ No image data in item {i}")
        continue

    saved.append(out)
    print(f"✅ Saved: {out}")
    if item.get('revised_prompt'):
        print(f"📝 Revised prompt: {item['revised_prompt']}")

if saved and sys.platform == 'darwin':
    subprocess.run(['open', saved[0]], check=False)
PYEOF
