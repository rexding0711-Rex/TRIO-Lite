#!/bin/bash
# @layer: infra
# sync.sh — 数据同步模块
# 依赖: lib/common.sh (TRIO_ROOT, TRIO_DB, 颜色, 日期工具)

# ============================================================
# SYNC — 从文件系统同步数据到 metrics/DAILY
# ============================================================

cmd_sync() {
    local now=$(today)

    echo "═══════════════════════════════════════════════════════════"
    echo "  🔄 TRIO 数据同步 — $now"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    # 1. 从文件系统读取真实数据
    local total_runs
    total_runs=$(find "$TRIO_ROOT/runs/" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
    local total_companies
    total_companies=$(find "$TRIO_DB/知识库/company-benchmark/" -mindepth 1 -maxdepth 1 -type d ! -name "*.md" 2>/dev/null | wc -l)
    local total_topics
    total_topics=$(grep -c '^[a-z]' "$TOPICS_FILE" 2>/dev/null || echo "0")
    local total_patterns=0
    local total_people
    total_people=$(find "$TRIO_DB/知识库/person-benchmark/" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
    local people_cards
    people_cards=$(find "$TRIO_DB/知识库/person-benchmark/" -name "*.md" 2>/dev/null | wc -l)

    echo "  真实数据:"
    echo "    runs: $total_runs"
    echo "    公司: $total_companies"
    echo "    kb-refresh: $total_topics 主题"
    echo "    模式: ~$((total_patterns * 3))"
    echo "    人物索引: $total_people 人 ($people_cards 张详卡)"
    echo ""

    # 2. 更新 metrics.md
    local metrics_file="$TRIO_ROOT/metrics.md"
    if [ -f "$metrics_file" ]; then
        python3 "$TRIO_ROOT/scripts/sync_metrics.py" metrics "$metrics_file" \
            "累计 run 数=$total_runs" \
            "累计 \`/逆向工程\` 公司数=$total_companies" \
            "company-library 公司数=$total_companies" \
            2>/dev/null || echo "⚠️ metrics同步失败"
        echo "  ✅ metrics.md 已同步"
    fi

    # 3. 更新 DAILY.md
    local daily_file="$TRIO_ROOT/DAILY.md"
    if [ -f "$daily_file" ]; then
        python3 "$TRIO_ROOT/scripts/sync_metrics.py" daily "$daily_file" \
            "公司库=$total_companies" \
            "run数=$total_runs" \
            2>/dev/null || echo "⚠️ DAILY同步失败"
        echo "  ✅ DAILY.md 已同步"
    fi

    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  ✅ 全部同步完成"
    echo "═══════════════════════════════════════════════════════════"
}

cmd_post_session() {
    local now=$(date '+%Y-%m-%d %H:%M')
    local timestamp_file="$CONFIG_DIR/last_session.txt"
    echo "📋 Post-Session 处理 — $now"
    cmd_sync
    if [ -f "$timestamp_file" ]; then
        local new_runs; new_runs=$(find "$TRIO_ROOT/runs/" -maxdepth 1 -type d -newer "$timestamp_file" 2>/dev/null | wc -l)
        echo "  新 run: $new_runs 个"
    fi
    date '+%Y-%m-%d %H:%M' > "$timestamp_file"
    log_history "system" "post-session" "处理完成"
}
