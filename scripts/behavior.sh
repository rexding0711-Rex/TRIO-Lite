#!/bin/bash
# @layer: infra
# behavior.sh — 行为追踪模块
# 依赖: lib/common.sh (TRIO_ROOT, TRIO_DB, 颜色)

cmd_behavior() {
    local event="${1:-ping}"
    local note="${2:-}"
    local ts=$(date -Iseconds)
    echo "{\"ts\":\"$ts\",\"event\":\"$event\",\"note\":\"$note\"}" >> "$TRIO_ROOT/state/behavior-log.jsonl"
    echo "📝 $event"
}

cmd_behavior_auto() {
    local log="$TRIO_ROOT/state/behavior-log.jsonl"
    local ref="$TRIO_ROOT/DAILY.md"
    local count=0

    local changed=$(find "$TRIO_ROOT" \( -name "*.md" -o -name "*.json" -o -name "*.sh" \) -newer "$ref" 2>/dev/null | grep -v "state/\|.git/\|runs/" | head -30)

    # 检测各类变更
    if echo "$changed" | grep -q "docs/adr/"; then
        cmd_behavior "架构决策" "新增或修改了ADR" > /dev/null 2>&1; count=$((count + 1))
    fi
    if echo "$changed" | grep -q "guard\|layer"; then
        cmd_behavior "系统防御" "更新了禁区守卫或层依赖规则" > /dev/null 2>&1; count=$((count + 1))
    fi
    if echo "$changed" | grep -q "config/scenarios/"; then
        cmd_behavior "场景设计" "新增或修改了场景SOP" > /dev/null 2>&1; count=$((count + 1))
    fi
    if echo "$changed" | grep -q "config/roles/"; then
        cmd_behavior "角色调整" "新增/吸收/修改了角色定义" > /dev/null 2>&1; count=$((count + 1))
    fi
    if echo "$changed" | grep -q "config/protocols/"; then
        cmd_behavior "协议升级" "新增或修改了协议" > /dev/null 2>&1; count=$((count + 1))
    fi
    if echo "$changed" | grep -q "knowledge/skills/"; then
        cmd_behavior "技能沉淀" "从run中提取了可复用技能" > /dev/null 2>&1; count=$((count + 1))
    fi
    if echo "$changed" | grep -q "capability-stack"; then
        cmd_behavior "能力栈调整" "修改了TRIO能力栈" > /dev/null 2>&1; count=$((count + 1))
    fi
    if echo "$changed" | grep -q "metrics\|DAILY"; then
        cmd_behavior "度量刷新" "更新了系统指标或每日总览" > /dev/null 2>&1; count=$((count + 1))
    fi
    if echo "$changed" | grep -q "mgmt.sh"; then
        cmd_behavior "引擎升级" "修改了mgmt.sh管理脚本" > /dev/null 2>&1; count=$((count + 1))
    fi
    if echo "$changed" | grep -q "日进化"; then
        cmd_behavior "进化引擎" "更新了日进化流程" > /dev/null 2>&1; count=$((count + 1))
    fi

    # 检测用户数据目录变更
    local db_changed=$(find "$TRIO_DB" \( -name "*.md" -o -name "*.json" \) -newer "$ref" 2>/dev/null | head -10)
    if [ -n "$db_changed" ]; then
        cmd_behavior "知识入库" "新增了知识产出" > /dev/null 2>&1; count=$((count + 1))
    fi

    echo "📝 自动记录 $count 条行为 (参考点: DAILY.md)"
}

cmd_behavior_report() {
    local log="$TRIO_ROOT/state/behavior-log.jsonl"
    echo "📊 TRIO 行为摘要"
    echo ""
    if [ ! -f "$log" ] || [ ! -s "$log" ]; then
        echo "  暂无行为数据"
        return 0
    fi
    echo "总事件: $(wc -l < "$log")"
    echo ""
    echo "事件分布:"
    grep -oP '"event":"[^"]*"' "$log" 2>/dev/null | sort | uniq -c | sort -rn | head -10
    echo ""
    echo "最近5条:"
    tail -5 "$log" 2>/dev/null | while read line; do
        echo "$line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(f\"  {d['ts'][:19]} | {d['event']:20s} | {d.get('note','')[:60]}\")" 2>/dev/null || true
    done
}
