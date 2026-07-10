#!/bin/bash
# @layer: infra
# ============================================================
# TRIO 基础版 管理脚本 — mgmt.sh
# ============================================================
# 新增: sync — 自动从文件系统同步所有数据到 metrics/INDEX/llms/DAILY
# ============================================================

set -euo pipefail

# ============================================================
# 显式错误处理（§6.2）
# ============================================================
TRIO_ROOT="${TRIO_ROOT:-$(dirname "$(readlink -f "$0")")}"
ERROR_LOG="$TRIO_ROOT/state/errors.log"
mkdir -p "$(dirname "$ERROR_LOG")"
trap 'cmd_error "TRAP" "$?" "${BASH_COMMAND:-unknown}" "${FUNCNAME:-main}"' ERR

cmd_error() {
    local source="$1" code="$2" cmd="$3" func="$4"
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $source | code=$code | $func | $cmd"
    echo "$msg" >> "$ERROR_LOG"
    echo "😅 $func 出了点问题 (code=$code) → 详情在 state/errors.log" >&2
}

guard_error() {
    echo "📂 文件放错地方了——TRIO 目录里不该有项目文件。" >&2
    echo "  项目文件应该放在: ${TRIO_DB}/项目/{项目名}/" >&2
    echo "  跑 bash mgmt.sh classify scan 可以自动搬过去" >&2
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TRIO_ROOT="$SCRIPT_DIR"
CONFIG_DIR="$TRIO_ROOT/config/kb-refresh"
# @data-depends: topics.tsv TSV格式(7列: id path category last_refreshed interval_days priority description)
# @炸点: 列顺序改变或分隔符改变 → kb-refresh全部子命令失效
TOPICS_FILE="$CONFIG_DIR/topics.tsv"
HISTORY_FILE="$CONFIG_DIR/history.log"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

today() { date '+%Y-%m-%d'; }
days_since() {
    local d="$1"
    local d_sec=$(date -d "$d" '+%s' 2>/dev/null || echo 0)
    local t_sec=$(date '+%s')
    echo $(( (t_sec - d_sec) / 86400 ))
}
is_overdue() {
    local last_refreshed="$1" interval_days="$2"
    local elapsed; elapsed=$(days_since "$last_refreshed")
    [ "$elapsed" -ge "$interval_days" ]
}
log_history() {
    local id="$1" action="$2" result="$3"
    echo "$(date '+%Y-%m-%d %H:%M')	$id	$action	$result" >> "$HISTORY_FILE"
}

# ============================================================
# SYNC — 自动同步所有数据文件
# ============================================================

cmd_depth() {
    local load=0

    # 认知负载因子1: Kimi 未读产出（从知识库路径读取，无则跳过）
    local kimi_unread=0
    local kimi_dir="${TRIO_KB_DIR:+/$TRIO_KB_DIR/knowledge-benchmark/Kimi蒸馏产出}"
    if [ -d "$kimi_dir" ]; then
        kimi_unread=$(find "$kimi_dir" -name "*.md" -newer "$TRIO_ROOT/DAILY.md" 2>/dev/null | wc -l)
        kimi_unread=${kimi_unread// /}  # 去除wc -l可能产生的空格
    fi

    # 认知负载因子2: 今日run数
    # @data-depends: behavior-log.jsonl 格式({"ts":...,"event":...,"note":...})
    # @炸点: 字段改名 → depth计算runs_today=0 → 永远不触发降级
    local runs_today=0
    local behavior_log="$TRIO_ROOT/state/behavior-log.jsonl"
    if [ -f "$behavior_log" ]; then
        runs_today=$(grep -c "$(date +%Y-%m-%d)" "$behavior_log" 2>/dev/null || true)
        runs_today=${runs_today:-0}
    fi

    # 确保都是数字（防御性）
    kimi_unread=$((kimi_unread + 0))
    runs_today=$((runs_today + 0))
    load=$((kimi_unread + runs_today))

    if [ "$load" -gt 5 ]; then
        echo "📊 Level 1 — 认知负载高($load)。只出核心结论。"
        echo "1" > "$TRIO_ROOT/state/depth-level.txt"
    elif [ "$load" -gt 2 ]; then
        echo "📊 Level 2 — 标准输出。"
        echo "2" > "$TRIO_ROOT/state/depth-level.txt"
    else
        echo "📊 Level 2 — 标准输出（负载低，可深入）。"
        echo "2" > "$TRIO_ROOT/state/depth-level.txt"
    fi
    # 协议v1.1: 防抖动——记录切换历史
    echo "$(date +%s):$load" >> "$TRIO_ROOT/state/depth-history.txt" 2>/dev/null
    local recent=$(tail -3 "$TRIO_ROOT/state/depth-history.txt" 2>/dev/null | wc -l)
    [ "$recent" -ge 3 ] && { echo "  ⚠️ 频繁切换→锁定当前Level 30分钟"; touch "$TRIO_ROOT/state/depth-lock"; }
}

