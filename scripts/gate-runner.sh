#!/bin/bash
# ================================================================
# TRIO 基础版 · 门禁执行器 v1.0
# ================================================================
# 用法:
#   bash scripts/gate-runner.sh <目标文件> [hook_point]
#
# hook_point: pre-delivery | post-session (默认 pre-delivery)
#
# 读取 config/gate-framework.json，逐项执行门禁检查。
# 内置门禁: file-exists, date-sanity, path-security
# 用户门禁: config/gates/ 下的脚本（exit 0=通过, exit 1=失败）
#
# 退出码: 0=通过, 1=阻断
# ================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$SCRIPT_DIR/config/gate-framework.json"
GATES_DIR="$SCRIPT_DIR/config/gates"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

TARGET="${1:-}"
HOOK="${2:-pre-delivery}"

# ── 参数校验 ──────────────────────────────────────────────
if [ -z "$TARGET" ]; then
    echo "用法: $0 <目标文件> [hook_point]"
    echo "  hook_point: pre-delivery | post-session"
    exit 2
fi

if [ ! -f "$CONFIG" ]; then
    echo -e "${YELLOW}⚠️  config/gate-framework.json 不存在${NC}"
    echo -e "  运行 ${CYAN}bash init.sh${NC} 生成配置，或手动创建。"
    exit 0
fi

# ── 内置门禁实现 ──────────────────────────────────────────

check_file_exists() {
    # 从目标文件中提取引用的文件路径，检查是否真实存在
    local target="$1"
    local issues=0

    # 提取 Markdown 链接和图片路径
    while IFS= read -r line; do
        # [text](path) 格式
        local refs
        refs=$(echo "$line" | grep -oP '\[[^\]]+\]\(\K[^)]+' 2>/dev/null || true)
        for ref in $refs; do
            # 跳过 URL
            [[ "$ref" =~ ^https?:// ]] && continue
            # 跳过锚点
            [[ "$ref" =~ ^# ]] && continue
            local full_path
            if [[ "$ref" = /* ]]; then
                full_path="$ref"
            else
                full_path="$(dirname "$target")/$ref"
            fi
            if [ ! -e "$full_path" ]; then
                echo -e "    ${RED}✗${NC} 引用文件不存在: $ref"
                issues=$((issues + 1))
            fi
        done
    done < "$target"

    # 提取 D:\ 或 /mnt/ 路径
    local win_paths
    win_paths=$(grep -oP '[A-Z]:\\[^\s)\]]+' "$target" 2>/dev/null || true)
    for wp in $win_paths; do
        local unix_path
        unix_path=$(echo "$wp" | sed 's|\\|/|g; s|^\([A-Z]\):|/mnt/\L\1|')
        if [ ! -e "$unix_path" ]; then
            echo -e "    ${YELLOW}⚠${NC}  Windows 路径可能不存在: $wp"
        fi
    done

    return $issues
}

check_date_sanity() {
    # 检查文件中的日期是否合理（不能是未来日期）
    local target="$1"
    local issues=0
    local today
    today=$(TZ=Asia/Shanghai date +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)

    # 提取 2026-xx-xx 格式的日期
    local dates
    dates=$(grep -oP '20\d{2}-\d{2}-\d{2}' "$target" 2>/dev/null || true)
    for d in $dates; do
        if [[ "$d" > "$today" ]]; then
            # 允许未来 7 天（可能是计划日期）
            local future_cutoff
            future_cutoff=$(date -d "+7 days" +%Y-%m-%d 2>/dev/null || date -v+7d +%Y-%m-%d 2>/dev/null || echo "")
            if [ -n "$future_cutoff" ] && [[ "$d" > "$future_cutoff" ]]; then
                echo -e "    ${YELLOW}⚠${NC}  日期远超未来: $d"
                issues=$((issues + 1))
            fi
        fi
    done

    return $issues
}

check_path_security() {
    # 检查目标文件中是否引用了敏感系统路径
    local target="$1"
    local issues=0
    local dangerous=("/etc/" "/root/" "~/.ssh/" "C:\\\\Windows" "/var/run/")

    for pattern in "${dangerous[@]}"; do
        if grep -q "$pattern" "$target" 2>/dev/null; then
            echo -e "    ${RED}✗${NC} 引用敏感路径: $pattern"
            issues=$((issues + 1))
        fi
    done

    return $issues
}

# ── 执行用户自定义门禁 ────────────────────────────────────

run_user_gate() {
    local gate_script="$1"
    local target="$2"

    if [ ! -f "$gate_script" ]; then
        echo -e "    ${YELLOW}⚠${NC}  门禁脚本不存在: $gate_script"
        return 2  # 2 = 跳过
    fi

    if [ ! -x "$gate_script" ]; then
        echo -e "    ${YELLOW}⚠${NC}  门禁脚本不可执行: $gate_script"
        return 2
    fi

    # 执行脚本，传入目标文件路径
    local output
    if output=$("$gate_script" "$target" 2>&1); then
        echo -e "    ${GREEN}✓${NC} 通过"
        [ -n "$output" ] && echo "$output" | sed 's/^/      /'
        return 0
    else
        echo -e "    ${RED}✗${NC} 未通过"
        [ -n "$output" ] && echo "$output" | sed 's/^/      /'
        return 1
    fi
}

# ── 主流程 ────────────────────────────────────────────────

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  TRIO 门禁检查 · $HOOK${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "目标: ${CYAN}$TARGET${NC}"
echo ""

BLOCKED=0
WARNINGS=0
TOTAL=0

# ── 内置门禁 ──
echo -e "${BOLD}内置门禁:${NC}"

echo -n "  [文件路径] ... "
TOTAL=$((TOTAL + 1))
if check_file_exists "$TARGET"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    BLOCKED=$((BLOCKED + 1))
fi

echo -n "  [日期合理性] ... "
TOTAL=$((TOTAL + 1))
if check_date_sanity "$TARGET"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

echo -n "  [路径安全] ... "
TOTAL=$((TOTAL + 1))
if check_path_security "$TARGET"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    BLOCKED=$((BLOCKED + 1))
fi

# ── 用户门禁（从 gate-framework.json 读取） ──
if [ -f "$CONFIG" ]; then
    # 用 python3 解析 JSON，列出 gates 数组
    user_gates=$(python3 -c "
import json, sys
try:
    with open('$CONFIG') as f:
        cfg = json.load(f)
    for g in cfg.get('gates', []):
        gid = g.get('id', 'unknown')
        name = g.get('name', gid)
        severity = g.get('severity', 'warn')
        print(f'{gid}|{name}|{severity}')
except Exception as e:
    print(f'#error:{e}', file=sys.stderr)
" 2>/dev/null)

    if [ -n "$user_gates" ] && [[ ! "$user_gates" =~ ^#error ]]; then
        echo ""
        echo -e "${BOLD}用户门禁:${NC}"

        while IFS='|' read -r gid gname gseverity; do
            [ -z "$gid" ] && continue
            echo -n "  [$gname] ... "
            TOTAL=$((TOTAL + 1))

            # 在 config/gates/ 下找匹配的脚本
            script_path="$GATES_DIR/${gid}.sh"
            if [ -f "$script_path" ]; then
                run_user_gate "$script_path" "$TARGET"
                rc=$?
                if [ $rc -eq 1 ]; then
                    if [ "$gseverity" = "block" ]; then
                        BLOCKED=$((BLOCKED + 1))
                    else
                        WARNINGS=$((WARNINGS + 1))
                    fi
                fi
            else
                echo -e "    ${YELLOW}⚠${NC}  门禁 '$gid' 已声明但脚本不存在 (config/gates/${gid}.sh)"
                echo -e "    ${CYAN}→${NC} 创建此脚本来定义检查逻辑。exit 0=通过, exit 1=失败。"
                WARNINGS=$((WARNINGS + 1))
            fi
        done <<< "$user_gates"
    fi
fi

# ── 汇总 ──
echo ""
echo -e "${BOLD}────────────────────────────────────────${NC}"
echo -ne "  检查: ${TOTAL} 项  |  "

if [ "$BLOCKED" -gt 0 ]; then
    echo -e "${RED}✗ ${BLOCKED} 项阻断${NC}"
else
    echo -e "${GREEN}✓ 全部通过${NC}"
fi

[ "$WARNINGS" -gt 0 ] && echo -e "  ${YELLOW}⚠ ${WARNINGS} 项警告${NC}"

if [ "$BLOCKED" -gt 0 ]; then
    echo ""
    echo -e "${RED}🚫 门禁未通过 — 交付被阻断${NC}"
    echo -e "  修复以上 ${BLOCKED} 项后重新运行:"
    echo -e "  ${CYAN}bash scripts/gate-runner.sh $TARGET $HOOK${NC}"
    exit 1
else
    echo ""
    echo -e "${GREEN}✅ 门禁通过${NC}"
    exit 0
fi
