#!/bin/bash
# @layer: infra
# TRIO 回复前自动校验脚本
# 检查常见错误: 文件路径不存在、日期不对齐

TEXT="${1:-$(cat)}"
ERRORS=0

# 获取 TRIO 根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRIO_ROOT="$(dirname "$SCRIPT_DIR")"

# 加载路径配置
[ -f "$TRIO_ROOT/config/paths.conf" ] && source "$TRIO_ROOT/config/paths.conf"

# 1. 检查文件路径存在性
echo "$TEXT" | grep -oP '(?<=`)[^`]+\.(md|json|pdf|pptx|docx)' 2>/dev/null | while read path; do
  if [ ! -f "$TRIO_ROOT/$path" ] && [ ! -f "$path" ]; then
    echo "❌ 文件不存在: $path"
    ERRORS=$((ERRORS+1))
  fi
done

# 2. 检查日期: 不可能是未来日期（>当前+7天）
TODAY=$(TZ=Asia/Shanghai date +%Y-%m-%d)
FUTURE=$(TZ=Asia/Shanghai date -d "+7 days" +%Y-%m-%d)
echo "$TEXT" | grep -oP '20\d{2}-\d{2}-\d{2}' 2>/dev/null | while read dt; do
  if [[ "$dt" > "$FUTURE" ]]; then
    echo "⚠️  可疑日期: $dt（>7天后），确认不是手误？"
  fi
done

# 3. 检查 PDF 承诺
if echo "$TEXT" | grep -q '\.pdf'; then
  echo "$TEXT" | grep -oP '[^ ,，。\n]+\.pdf' 2>/dev/null | while read pdf; do
    if [ ! -f "$pdf" ] && [ ! -f "$TRIO_DB/项目/"*/"$pdf" ]; then
      echo "⚠️  声称的 PDF 可能不存在: $pdf"
    fi
  done
fi

exit $ERRORS
