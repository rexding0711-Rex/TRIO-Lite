#!/bin/bash
# @layer: infra
# skills.sh — 技能提取 + 状态校验模块
# 依赖: lib/common.sh (TRIO_ROOT, 颜色)

cmd_state_check() {
    local run_dir="${1:-}"
    [ -z "$run_dir" ] && { echo "用法: mgmt.sh state-check <run_dir>"; return 1; }
    python3 "$TRIO_ROOT/scripts/state_check.py" "$run_dir"
    return $?
}

cmd_skill_extract() {
    local run_id="${1:-}"
    local scenario="${2:-deconstruct}"
    local skills_dir="$TRIO_ROOT/knowledge/skills"
    local template="$skills_dir/.template.md"

    [ -z "$run_id" ] && { echo "用法: mgmt.sh skill-extract <run_id> [scenario]"; return 1; }
    [ ! -f "$template" ] && { echo "⚠️ 模板缺失——技能提取跳过（不阻塞run完成）"; return 0; }

    echo "📝 技能提取 — $run_id ($scenario)"
    echo "  模板: $template"
    echo "  输出: $skills_dir/${scenario}-*.md"
    echo "  ✅ 技能提取就绪 — 由场景Step 10自动调用"
}
