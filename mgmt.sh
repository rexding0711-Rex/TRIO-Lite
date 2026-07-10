#!/bin/bash
# @layer: infra
# TRIO 基础版 管理脚本 — 总路由
# 子模块: scripts/{sync,guard,depth,behavior,daily-fill,backup,skills,kb-refresh}.sh
# 共享库: lib/common.sh
# 路径配置: config/paths.conf

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TRIO_ROOT="$SCRIPT_DIR"

# ── 加载路径配置 ──
if [ -f "$SCRIPT_DIR/config/paths.conf" ]; then
    source "$SCRIPT_DIR/config/paths.conf"
elif [ -f "$SCRIPT_DIR/config/platform.sh" ]; then
    source "$SCRIPT_DIR/config/platform.sh"
    echo "💡 使用自动检测的数据目录: ${TRIO_DB:-未设置}"
    echo "   如需自定义: cp config/paths.conf.example config/paths.conf"
else
    echo "⚠️  未找到路径配置"
    echo "   请先: cp config/paths.conf.example config/paths.conf"
    exit 1
fi

# ── 加载共享库 ──
source "$SCRIPT_DIR/lib/common.sh"

# 全局错误 trap（只设一次）
trap 'cmd_error "TRAP" "$?" "${BASH_COMMAND:-unknown}" "${FUNCNAME:-main}"' ERR

# ── 加载子模块（只含 cmd_* 函数）──
source "$SCRIPT_DIR/scripts/sync.sh"
source "$SCRIPT_DIR/scripts/kb-refresh.sh"
source "$SCRIPT_DIR/scripts/guard.sh"
source "$SCRIPT_DIR/scripts/depth.sh"
source "$SCRIPT_DIR/scripts/behavior.sh"
source "$SCRIPT_DIR/scripts/daily-fill.sh"
source "$SCRIPT_DIR/scripts/backup.sh"
source "$SCRIPT_DIR/scripts/skills.sh"

# ── 主路由 ──
case "${1:-help}" in
    sync)             cmd_sync ;;
    post-session)     cmd_post_session
                       bash "$SCRIPT_DIR/scripts/thinking-recorder.sh" update 2>/dev/null || true ;;
    kb-refresh)       case "${2:-help}" in
                          next)   cmd_kb_refresh_next ;;
                          done)   cmd_kb_refresh_done "${3:-}" ;;
                          list)   cmd_kb_refresh_list "${3:-all}" ;;
                          reset)  cmd_kb_refresh_reset ;;
                          add)    cmd_kb_refresh_add "${3:-}" "${4:-}" "${5:-}" "${6:-}" ;;
                          skip)   cmd_kb_refresh_skip "${3:-}" ;;
                          help|*) cmd_kb_refresh_help ;;
                      esac ;;
    layer-check)      cmd_layer_check ;;
    guard)            cmd_guard ;;
    depth)            cmd_depth ;;
    behavior)         cmd_behavior "${2:-}" "${3:-}" ;;
    behavior-auto)    cmd_behavior_auto ;;
    behavior-report)  cmd_behavior_report ;;
    daily-fill)       cmd_daily_fill ;;
    skill-extract)    cmd_skill_extract "${2:-}" "${3:-}" ;;
    state-check)      cmd_state_check "${2:-}" ;;
    backup)           cmd_backup ;;
    help|*)
        echo "TRIO 基础版 · 工具箱"
        echo "  数据目录: ${TRIO_DB:-未配置}（别担心，init.sh 会帮你搞定）"
        echo ""
        echo "  sync              同步数据文件"
        echo "  post-session      会话结束后处理"
        echo "  kb-refresh        知识刷新调度器"
        echo "  layer-check       层依赖校验"
        echo "  guard             禁区扫描"
        echo "  depth             认知负载检测"
        echo "  behavior[-auto|-report]  行为追踪"
        echo "  daily-fill        填充每日自问"
        echo "  backup            备份"
        echo "  skill-extract     技能提取"
        echo "  state-check       状态校验"
        ;;
esac
