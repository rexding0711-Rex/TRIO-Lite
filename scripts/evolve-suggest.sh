#!/bin/bash
# ================================================================
# TRIO 基础版 · 进化建议引擎 v1.0
# ================================================================
# 用法:
#   bash scripts/evolve-suggest.sh              — 输出建议
#   bash scripts/evolve-suggest.sh --apply <id> — 应用某条建议
#   bash scripts/evolve-suggest.sh --dismiss <id> — 忽略某条建议
#
# 从 behavior-log.jsonl 中检测用户的重复行为模式，
# 生成可操作的进化建议。用户确认后自动更新配置。
# ================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STATE_DIR="$SCRIPT_DIR/state"
BEHAVIOR_LOG="$STATE_DIR/behavior-log.jsonl"
SUGGEST_LOG="$STATE_DIR/evolve-suggestions.jsonl"
USER_CONFIG="$SCRIPT_DIR/config/user-config.json"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BOLD='\033[1m'; NC='\033[0m'

mkdir -p "$STATE_DIR"

ACTION="${1:-}"
TARGET_ID="${2:-}"

# ── 模式检测 ──────────────────────────────────────────────

detect_patterns() {
    # 如果行为日志不存在或太短，直接返回
    if [ ! -f "$BEHAVIOR_LOG" ] || [ "$(wc -l < "$BEHAVIOR_LOG" 2>/dev/null || echo 0)" -lt 5 ]; then
        return
    fi

    local today
    today=$(TZ=Asia/Shanghai date +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)

    # ── 模式 1: 场景使用频率 ──
    local top_scenario
    top_scenario=$(grep -oP '"scenario"\s*:\s*"\K[^"]+' "$BEHAVIOR_LOG" 2>/dev/null \
        | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')
    local top_count
    top_count=$(grep -oP '"scenario"\s*:\s*"\K[^"]+' "$BEHAVIOR_LOG" 2>/dev/null \
        | sort | uniq -c | sort -rn | head -1 | awk '{print $1}')

    if [ -n "$top_scenario" ] && [ "${top_count:-0}" -ge 5 ]; then
        echo "{\"id\":\"suggest-${today}-1\",\"date\":\"$today\",\"type\":\"shortcut\",\"pattern\":\"高频场景: $top_scenario (${top_count}次)\",\"suggestion\":\"为 /$top_scenario 创建快捷别名或设为默认场景\",\"action\":\"手动编辑 user-config.json 添加 default_scenario\",\"status\":\"pending\"}"
    fi

    # ── 模式 2: 前置操作链 ──
    # 检测 "每次跑 X 之前都先跑 Y"
    local chain
    chain=$(grep -oP '"event"\s*:\s*"\K[^"]+' "$BEHAVIOR_LOG" 2>/dev/null | tail -30)
    if [ -n "$chain" ]; then
        local pre_count
        pre_count=$(echo "$chain" | grep -c "速判\|quick" 2>/dev/null || echo 0)
        local full_count
        full_count=$(echo "$chain" | grep -c "尽调\|due_diligence\|逆向" 2>/dev/null || echo 0)
        if [ "${pre_count:-0}" -ge 3 ] && [ "${full_count:-0}" -ge 3 ]; then
            echo "{\"id\":\"suggest-${today}-2\",\"date\":\"$today\",\"type\":\"preflight\",\"pattern\":\"深查前习惯先速判 ($pre_count 次)\",\"suggestion\":\"每次 /尽调 前自动跑 /速判 预筛\",\"action\":\"编辑 config/user-config.json，在 preferences 中添加 preflight: quick_assessment\",\"status\":\"pending\"}"
        fi
    fi

    # ── 模式 3: 交付前手动检查 → 建议添加门禁 ──
    local manual_checks
    manual_checks=$(grep -c "check\|检查\|校验\|verify" "$BEHAVIOR_LOG" 2>/dev/null || echo 0)
    if [ "${manual_checks:-0}" -ge 3 ]; then
        echo "{\"id\":\"suggest-${today}-3\",\"date\":\"$today\",\"type\":\"automate\",\"pattern\":\"你经常手动检查 ($manual_checks 次)\",\"suggestion\":\"把这些检查写成门禁脚本，放到 config/gates/ 让它自动跑\",\"action\":\"在 config/gates/ 下创建检查脚本，在 gate-framework.json 中引用\",\"status\":\"pending\"}"
    fi

    # ── 模式 4: 使用时段偏好 ──
    local night_count
    night_count=$(grep -cP '"(2[123]|0[0-5]):\d\d"' "$BEHAVIOR_LOG" 2>/dev/null || echo 0)
    local total_events
    total_events=$(wc -l < "$BEHAVIOR_LOG" 2>/dev/null || echo 1)
    if [ "${night_count:-0}" -gt $((total_events / 2)) ] 2>/dev/null; then
        echo "{\"id\":\"suggest-${today}-4\",\"date\":\"$today\",\"type\":\"rhythm\",\"pattern\":\"你主要在深夜工作 (${night_count}/${total_events} 事件)\",\"suggestion\":\"考虑调整输出深度——深夜认知负载高时自动降为简洁模式\",\"action\":\"在 config/user-config.json 的 evolution 段添加 night_mode: concise\",\"status\":\"pending\"}"
    fi
}

# ── 应用建议 ──────────────────────────────────────────────

apply_suggestion() {
    local id="$1"
    if [ ! -f "$SUGGEST_LOG" ]; then
        echo -e "${YELLOW}⚠️  没有待处理的建议${NC}"
        return 1
    fi

    local entry
    entry=$(grep "\"$id\"" "$SUGGEST_LOG" 2>/dev/null || true)
    if [ -z "$entry" ]; then
        echo -e "${YELLOW}⚠️  未找到建议: $id${NC}"
        return 1
    fi

    local action
    action=$(echo "$entry" | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('action',''))" 2>/dev/null || echo "")

    # 标记为 applied
    local tmp
    tmp=$(mktemp)
    sed "s/\"status\":\"pending\"/\"status\":\"applied\"/" "$SUGGEST_LOG" > "$tmp" && mv "$tmp" "$SUGGEST_LOG"

    echo -e "${GREEN}✅ 已应用: $id${NC}"
    echo -e "   ${CYAN}$action${NC}"
    echo ""
    echo -e "   ${YELLOW}→${NC} 部分建议需要手动操作（如编辑配置文件）。"
}

# ── 忽略建议 ──────────────────────────────────────────────

dismiss_suggestion() {
    local id="$1"
    if [ ! -f "$SUGGEST_LOG" ]; then
        echo -e "${YELLOW}⚠️  没有待处理的建议${NC}"
        return 1
    fi

    local tmp
    tmp=$(mktemp)
    sed "s/\"status\":\"pending\"/\"status\":\"dismissed\"/" "$SUGGEST_LOG" > "$tmp" && mv "$tmp" "$SUGGEST_LOG"

    echo -e "${GREEN}已忽略: $id${NC} (不再提醒)"
}

# ── 主流程 ────────────────────────────────────────────────

case "$ACTION" in
    --apply)
        if [ -z "$TARGET_ID" ]; then
            echo "用法: $0 --apply <suggestion_id>"
            exit 1
        fi
        apply_suggestion "$TARGET_ID"
        ;;

    --dismiss)
        if [ -z "$TARGET_ID" ]; then
            echo "用法: $0 --dismiss <suggestion_id>"
            exit 1
        fi
        dismiss_suggestion "$TARGET_ID"
        ;;

    *)
        echo ""
        echo -e "${BOLD}╔══════════════════════════════════════════╗${NC}"
        echo -e "${BOLD}║  TRIO 进化建议引擎                        ║${NC}"
        echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
        echo ""

        # 先检测新模式
        new_suggestions=$(detect_patterns)

        # 追加到建议日志
        if [ -n "$new_suggestions" ]; then
            while IFS= read -r s; do
                [ -z "$s" ] && continue
                sid=$(echo "$s" | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('id',''))" 2>/dev/null || echo "")
                # 避免重复
                if [ -f "$SUGGEST_LOG" ] && grep -q "$sid" "$SUGGEST_LOG" 2>/dev/null; then
                    continue
                fi
                echo "$s" >> "$SUGGEST_LOG"
            done <<< "$new_suggestions"
        fi

        # 显示待处理建议
        if [ ! -f "$SUGGEST_LOG" ] || [ "$(grep -c '"status":"pending"' "$SUGGEST_LOG" 2>/dev/null || echo 0)" -eq 0 ]; then
            if [ "$(wc -l < "$BEHAVIOR_LOG" 2>/dev/null || echo 0)" -lt 5 ]; then
                echo -e "  行为数据还不够（需要 ≥5 条事件）。"
                echo -e "  继续使用 TRIO，我会慢慢了解你的习惯。"
                echo ""
                echo -e "  ${CYAN}事件数: $(wc -l < "$BEHAVIOR_LOG" 2>/dev/null || echo 0)${NC}"
            else
                echo -e "  ${GREEN}暂无新建议。${NC}"
                echo -e "  看起来你的工作流已经比较稳定了。"
            fi
        else
            echo -e "  发现以下模式，要我帮你优化吗？"
            echo ""

            count=0
            while IFS= read -r line; do
                [ -z "$line" ] && continue
                count=$((count + 1))
                id=$(echo "$line" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d['id'])" 2>/dev/null || echo "")
                type=$(echo "$line" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d['type'])" 2>/dev/null || echo "")
                pattern=$(echo "$line" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d['pattern'])" 2>/dev/null || echo "")
                suggestion=$(echo "$line" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d['suggestion'])" 2>/dev/null || echo "")

                icon="💡"
                case "$type" in
                    shortcut) icon="⚡" ;;
                    preflight) icon="🛫" ;;
                    automate) icon="🤖" ;;
                    rhythm) icon="🌙" ;;
                esac

                echo -e "  ${BOLD}$icon 建议 #$count${NC}"
                echo -e "  ${CYAN}发现:${NC} $pattern"
                echo -e "  ${CYAN}建议:${NC} $suggestion"
                echo -e "  ${YELLOW}应用:${NC} bash scripts/evolve-suggest.sh --apply $id"
                echo -e "  ${YELLOW}忽略:${NC} bash scripts/evolve-suggest.sh --dismiss $id"
                echo ""
            done < <(grep '"status":"pending"' "$SUGGEST_LOG" 2>/dev/null || true)
        fi
        ;;
esac
