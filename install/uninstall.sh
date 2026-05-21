#!/usr/bin/env bash
# aidle-skills 卸载脚本（macOS / Linux）
#
# 用法:
#   ./install/uninstall.sh --skill git-helper             # 从所有 target 卸载
#   ./install/uninstall.sh --skill git-helper --target claude
#   ./install/uninstall.sh --all                          # 卸载本仓库所有 skill
#   ./install/uninstall.sh --list                         # 列出可卸载的 skill
#   ./install/uninstall.sh --dry-run                      # 仅打印将执行的操作

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

SKILL=""
TARGET="all"
UNINSTALL_ALL=false
LIST_ONLY=false
DRY_RUN=false

usage() {
    sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skill)    SKILL="$2"; shift 2 ;;
        --target)   TARGET="$2"; shift 2 ;;
        --all)      UNINSTALL_ALL=true; shift ;;
        --list)     LIST_ONLY=true; shift ;;
        --dry-run)  DRY_RUN=true; shift ;;
        -h|--help)  usage; exit 0 ;;
        *)          err "未知参数: $1"; usage; exit 1 ;;
    esac
done

CLAUDE_DIR="${CLAUDE_SKILLS_DIR:-${HOME}/.claude/skills}"
CODEX_DIR="${CODEX_SKILLS_DIR:-${HOME}/.codex/skills}"

if [[ "${LIST_ONLY}" == "true" ]]; then
    list_skills "${REPO_ROOT}/skills"
    exit 0
fi

case "${TARGET}" in
    all|claude|codex) ;;
    *) err "--target 必须是 all / claude / codex，收到: ${TARGET}"; exit 1 ;;
esac

declare -a SKILLS_TO_REMOVE
if [[ -n "${SKILL}" ]]; then
    SKILLS_TO_REMOVE=("${SKILL}")
elif [[ "${UNINSTALL_ALL}" == "true" ]]; then
    while IFS= read -r s; do SKILLS_TO_REMOVE+=("$s"); done < <(list_skills "${REPO_ROOT}/skills")
else
    err "请使用 --skill <name> 或 --all"
    usage
    exit 1
fi

declare -a TARGETS
case "${TARGET}" in
    all)    TARGETS=("claude" "codex") ;;
    claude) TARGETS=("claude") ;;
    codex)  TARGETS=("codex") ;;
esac

for skill in "${SKILLS_TO_REMOVE[@]}"; do
    [[ "${skill}" == "_template" ]] && continue
    for t in "${TARGETS[@]}"; do
        case "${t}" in
            claude) dest_root="${CLAUDE_DIR}" ;;
            codex)  dest_root="${CODEX_DIR}" ;;
        esac
        dest="${dest_root}/${skill}"
        if [[ -d "${dest}" ]]; then
            if [[ "${DRY_RUN}" == "true" ]]; then
                info "[dry-run] 将删除: ${dest}"
            else
                rm -rf "${dest}"
                ok "[${t}] 已卸载 ${skill}"
            fi
        else
            warn "[${t}] ${skill} 未安装，跳过"
        fi
    done
done

ok "卸载完成。"
