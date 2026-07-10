#!/bin/bash
# @layer: infra
# guard.sh — 层依赖校验 + 禁区扫描
# 依赖: lib/common.sh (TRIO_ROOT, TRIO_DB, 颜色)

cmd_layer_check() {
    local layers_json="$TRIO_ROOT/config/layers.json"
    local violations=0

    echo "🔍 层依赖校验 — $(date '+%Y-%m-%d %H:%M')"
    echo ""

    echo "  [1] 进化层 ←→ 知识层 同层互拷检查..."
    if grep -q "metrics" "$TRIO_ROOT/DAILY.md" 2>/dev/null; then
        echo "    ⚠️ DAILY.md(进化层) 引用 metrics.md(进化层同层) — 应通过mgmt.sh"
        violations=$((violations + 1))
    fi

    echo "  [2] 知识层 → 进化层 反向依赖检查..."
    local rev_deps=$(grep -rl "DAILY.md\|metrics.md\|ADR-" "$TRIO_ROOT/knowledge/" "$TRIO_ROOT/docs/" 2>/dev/null | grep -v ".jsonl" | head -5)
    if [ -n "$rev_deps" ]; then
        echo "    ⚠️ 知识层文件引用了进化层:"
        echo "$rev_deps" | while read f; do echo "      $f"; done
        violations=$((violations + 1))
    fi

    echo "  [3] 未标记层归属的文件..."
    local untagged=$(find "$TRIO_ROOT" -name "*.md" -path "*/knowledge/*" -o -name "*.md" -path "*/docs/*" 2>/dev/null | while read f; do
        head -1 "$f" 2>/dev/null | grep -q "@layer:" || echo "      $f"
    done | head -5)
    if [ -n "$untagged" ]; then
        echo "    ⚠️ knowledge/docs 中有文件未标记层:"
        echo "$untagged"
        violations=$((violations + 1))
    fi

    echo ""
    if [ "$violations" -eq 0 ]; then
        echo "  ✅ 层依赖全部合规"
    else
        echo "  🟡 $violations 项需要注意——不影响使用，但建议有空修一下"
    fi
}

cmd_guard() {
    local violations=0
    local guard_json="$TRIO_ROOT/config/guard.json"
    echo "🛡️ TRIO 禁区扫描"
    echo ""

    # 1. 禁止的扩展名
    local exts=$(python3 -c "import json; print(' '.join(json.load(open('$guard_json'))['forbidden']['extensions']))" 2>/dev/null)
    for ext in $exts; do
        local found=$(find "$TRIO_ROOT" -name "*$ext" -not -path "*/.git/*" -not -path "*/node_modules/*" 2>/dev/null | grep -v "guard.json" | head -5)
        if [ -n "$found" ]; then
            echo "  🔴 非法扩展名 $ext:"
            echo "$found" | while read f; do echo "     $f"; done
            violations=$((violations + $(echo "$found" | wc -l)))
        fi
    done

    # 2. 禁止的项目关键词
    local patterns=$(python3 -c "import json; print('|'.join(json.load(open('$guard_json'))['forbidden']['patterns']))" 2>/dev/null | sed 's/\*//g')
    if [ -n "$patterns" ]; then
        local pattern_hits=$(find "$TRIO_ROOT" -type f -name "*.md" -not -path "*/.git/*" -not -path "*/config/*" -not -path "*/.claude/*" -not -path "*/knowledge/lessons-learned/*" 2>/dev/null | xargs -I{} basename {} 2>/dev/null | grep -iE "$patterns" | head -5)
        if [ -n "$pattern_hits" ]; then
            echo "  🟡 可疑项目关键词文件名:"
            echo "$pattern_hits" | while read f; do echo "     $f"; done
            violations=$((violations + $(echo "$pattern_hits" | wc -l)))
        fi
    fi

    echo ""
    if [ "$violations" -eq 0 ]; then
        echo "  ✅ TRIO 目录干净——没有乱入的项目文件"
    else
        echo "  📂 $violations 个文件放错位置了——项目文件不该在 TRIO 目录里"
        echo "  规则: 项目文件 → ${TRIO_DB}/项目/{项目名}/"
        guard_error
    fi
    return $violations
}
