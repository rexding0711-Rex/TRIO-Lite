#!/bin/bash
# @layer: infra
# TRIO Stop Hook 校验脚本
# Stop hook 传入 JSON: {"stop_reason":"...","last_assistant_message":"..."}

INPUT=$(cat)
MSG=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('last_assistant_message',''))" 2>/dev/null || echo "")
REASON=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('stop_reason',''))" 2>/dev/null || echo "")
ERRORS=0

# 获取 TRIO 根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRIO_ROOT="$(dirname "$SCRIPT_DIR")"

# 加载路径配置
[ -f "$TRIO_ROOT/config/paths.conf" ] && source "$TRIO_ROOT/config/paths.conf"

# 跳过用户中断和空消息
[ "$REASON" = "user_interrupt" ] && exit 0
[ -z "$MSG" ] && exit 0

# 1. 检查声明了 PDF 但文件不存在
echo "$MSG" | grep -oP '[^ ,，。\n\)]+\.pdf' 2>/dev/null | while read pdf; do
  if [ ! -f "$pdf" ]; then
    found=$(find "$TRIO_ROOT" "${TRIO_DB:-$HOME/TRIO-data}" -name "$pdf" 2>/dev/null | head -1)
    if [ -z "$found" ]; then
      echo "❌ PDF缺失: $pdf"
    fi
  fi
done

# 2. 检查时间戳缺少时区
echo "$MSG" | grep -oP '20\d{2}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}' 2>/dev/null | while read ts; do
  if ! echo "$ts" | grep -q '+08:00'; then
    echo "⚠️  可能手写时间戳: $ts（缺少时区）"
  fi
done

echo '{"decision": "approve"}'
exit 0
