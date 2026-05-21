#!/usr/bin/env bash
# aidle-skills 安装脚本（macOS / Linux）
#
# 用法:
#   ./install/install.sh                          # 交互式
#   ./install/install.sh --all                    # 安装全部 skill 到所有 target
#   ./install/install.sh --skill git-helper       # 仅安装某一个 skill
#   ./install/install.sh --target claude          # 仅装到 Claude Code
#   ./install/install.sh --target codex           # 仅装到 Codex
#   ./install/install.sh --skill git-helper --target claude
#   ./install/install.sh --list                   # 列出可用 skill
#   ./install/install.sh --dry-run                # 仅打印将执行的操作
#
# 环境变量:
#   CLAUDE_SKILLS_DIR   覆盖 Claude Code skill 目录（默认 ~/.claude/skills）
#   CODEX_SKILLS_DIR    覆盖 Codex skill 目录（默认 ~/.codex/skills）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# 依赖检查（install 本身只需要这些；具体 skill 的依赖在各自脚本中校验）
require_commands find cp mkdir

# 记录仓库路径，供 aidle meta-skill 等定位使用
mkdir -p "${HOME}/.aidle"
printf '%s\n' "${REPO_ROOT}" > "${HOME}/.aidle/repo"

SKILL=""
TARGET="all"      # all | claude | codex
INSTALL_ALL=false
LIST_ONLY=false
DRY_RUN=false

usage() {
    sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skill)    SKILL="$2"; shift 2 ;;
        --target)   TARGET="$2"; shift 2 ;;
        --all)      INSTALL_ALL=true; shift ;;
        --list)     LIST_ONLY=true; shift ;;
        --dry-run)  DRY_RUN=true; shift ;;
        -h|--help)  usage; exit 0 ;;
        *)          err "未知参数: $1"; usage; exit 1 ;;
    esac
done

if [[ "${LIST_ONLY}" == "true" ]]; then
    info "可用 skill (来自 ${REPO_ROOT}/skills):"
    while IFS= read -r s; do
        desc="$(skill_description "${REPO_ROOT}/skills/${s}")"
        desc="$(truncate_str "${desc}" 90)"
        printf "  ${C_GREEN}%-15s${C_RESET} %s\n" "${s}" "${desc}"
    done < <(list_skills "${REPO_ROOT}/skills")
    exit 0
fi

# 校验 target
case "${TARGET}" in
    all|claude|codex) ;;
    *) err "--target 必须是 all / claude / codex，收到: ${TARGET}"; exit 1 ;;
esac

# 决定要安装的 skill 列表
declare -a SKILLS_TO_INSTALL
if [[ -n "${SKILL}" ]]; then
    SKILLS_TO_INSTALL=("${SKILL}")
elif [[ "${INSTALL_ALL}" == "true" ]]; then
    while IFS= read -r s; do SKILLS_TO_INSTALL+=("$s"); done < <(list_skills "${REPO_ROOT}/skills")
else
    # 交互式选择
    info "可用 skill:"
    list_skills "${REPO_ROOT}/skills" | nl -ba
    echo
    read -rp "请输入 skill 名（多个用空格分隔，留空安装全部）: " input
    if [[ -z "${input}" ]]; then
        while IFS= read -r s; do SKILLS_TO_INSTALL+=("$s"); done < <(list_skills "${REPO_ROOT}/skills")
    else
        # shellcheck disable=SC2206
        SKILLS_TO_INSTALL=(${input})
    fi
fi

if [[ ${#SKILLS_TO_INSTALL[@]} -eq 0 ]]; then
    warn "没有要安装的 skill，退出。"
    exit 0
fi

# 决定目标目录
declare -a TARGETS
case "${TARGET}" in
    all)    TARGETS=("claude" "codex") ;;
    claude) TARGETS=("claude") ;;
    codex)  TARGETS=("codex") ;;
esac

CLAUDE_DIR="${CLAUDE_SKILLS_DIR:-${HOME}/.claude/skills}"
CODEX_DIR="${CODEX_SKILLS_DIR:-${HOME}/.codex/skills}"

# 执行安装
for skill in "${SKILLS_TO_INSTALL[@]}"; do
    src="${REPO_ROOT}/skills/${skill}"
    if [[ "${skill}" == "_template" ]]; then
        warn "跳过模板: ${skill}"
        continue
    fi
    if [[ ! -d "${src}" ]]; then
        err "skill 不存在: ${skill}"
        continue
    fi
    if [[ ! -f "${src}/SKILL.md" ]]; then
        err "skill 缺少 SKILL.md: ${skill}"
        continue
    fi

    for t in "${TARGETS[@]}"; do
        case "${t}" in
            claude) dest_root="${CLAUDE_DIR}" ;;
            codex)  dest_root="${CODEX_DIR}" ;;
        esac
        dest="${dest_root}/${skill}"
        install_skill "${src}" "${dest}" "${DRY_RUN}"
        ok "[${t}] ${skill} -> ${dest}"
    done
done

ok "安装完成。"
