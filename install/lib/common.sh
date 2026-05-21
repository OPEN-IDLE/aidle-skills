#!/usr/bin/env bash
# aidle-skills 安装脚本共享工具函数

# 颜色（终端支持时才启用）
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
    C_RED="$(tput setaf 1)"
    C_GREEN="$(tput setaf 2)"
    C_YELLOW="$(tput setaf 3)"
    C_BLUE="$(tput setaf 4)"
    C_RESET="$(tput sgr0)"
else
    C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_RESET=""
fi

info() { printf '%s[INFO]%s  %s\n'  "${C_BLUE}"   "${C_RESET}" "$*"; }
ok()   { printf '%s[OK]%s    %s\n'  "${C_GREEN}"  "${C_RESET}" "$*"; }
warn() { printf '%s[WARN]%s  %s\n'  "${C_YELLOW}" "${C_RESET}" "$*" >&2; }
err()  { printf '%s[ERR]%s   %s\n'  "${C_RED}"    "${C_RESET}" "$*" >&2; }

# 列出 skills 目录下的所有 skill（排除以 _ 开头的目录，如 _template）
list_skills() {
    local skills_dir="$1"
    if [[ ! -d "${skills_dir}" ]]; then
        return 0
    fi
    find "${skills_dir}" -mindepth 1 -maxdepth 1 -type d \
        -not -name '_*' \
        -exec basename {} \; | sort
}

# 从 SKILL.md frontmatter 提取 description（单行；多行 yaml 取折叠后的首行）
skill_description() {
    local md="$1/SKILL.md"
    [[ -f "$md" ]] || return 0
    head -30 "$md" | awk '
        /^description:/ {
            sub(/^description:[[:space:]]*/, "")
            gsub(/^"|"$/, "")
            gsub(/^'\''|'\''$/, "")
            print
            exit
        }
    '
}

# 依赖检查
# 用法: require_commands curl python3 ...
require_commands() {
    local missing=()
    for cmd in "$@"; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        err "缺少必需依赖: ${missing[*]}"
        err "请先安装上述命令再重试。"
        exit 1
    fi
}

# 截断字符串到指定长度，超出加 …
truncate_str() {
    local s="$1" max="${2:-100}"
    if [[ ${#s} -le $max ]]; then
        printf '%s\n' "$s"
    else
        printf '%s…\n' "${s:0:$((max-1))}"
    fi
}

# 复制 skill 到目标位置
# 用法: install_skill <src> <dest> <dry_run>
install_skill() {
    local src="$1"
    local dest="$2"
    local dry_run="${3:-false}"

    if [[ "${dry_run}" == "true" ]]; then
        info "[dry-run] mkdir -p $(dirname "${dest}") && cp -R ${src} ${dest}"
        return 0
    fi

    mkdir -p "$(dirname "${dest}")"
    # 已存在则覆盖
    if [[ -d "${dest}" ]]; then
        rm -rf "${dest}"
    fi
    cp -R "${src}" "${dest}"
}
