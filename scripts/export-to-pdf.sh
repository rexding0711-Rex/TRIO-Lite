#!/bin/bash
# @layer: infra
# PDF 导出管道 — 双管道策略: PowerPoint COM (主) / LibreOffice (备)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRIO_ROOT="$(dirname "$SCRIPT_DIR")"
CHECKER="$SCRIPT_DIR/check-cjk-fonts.py"

if [ $# -lt 1 ]; then
    echo "用法: $0 <input.pptx> [--skip-check] [--force-p2]"
    exit 1
fi

INPUT="$1"
SKIP_CHECK=false
FORCE_P2=false

shift
while [ $# -gt 0 ]; do
    case "$1" in
        --skip-check) SKIP_CHECK=true ;;
        --force-p2)   FORCE_P2=true ;;
    esac
    shift
done

if [ ! -f "$INPUT" ]; then
    echo "❌ 文件不存在: $INPUT"
    exit 1
fi

INPUT_ABS="$(realpath "$INPUT")"
INPUT_DIR="$(dirname "$INPUT_ABS")"
INPUT_NAME="$(basename "$INPUT_ABS" .pptx)"
OUTPUT_PDF="$INPUT_DIR/${INPUT_NAME}.pdf"

echo "📄 输入: $INPUT_ABS"
echo "📄 输出: $OUTPUT_PDF"

# Step 1: 字体校验
if [ "$SKIP_CHECK" = false ]; then
    echo ""
    echo "🔍 Step 1/3: 字体校验..."
    python3 "$CHECKER" "$INPUT_ABS" --strict || {
        echo "❌ 字体校验失败。使用 --skip-check 跳过或修复后重试。"
        exit 2
    }
fi

# Step 2: 导出 PDF
echo ""
echo "📤 Step 2/3: 导出 PDF..."

if [ "$FORCE_P2" = true ]; then
    echo "使用备选管道 (LibreOffice)..."
    cd "$INPUT_DIR"
    soffice --headless --convert-to pdf "$INPUT_ABS" 2>&1 || {
        echo "❌ LibreOffice 导出失败"
        exit 3
    }
else
    echo "使用主管道 (Windows PowerPoint)..."
    PS1_TEMP="/tmp/trio-ppt-export.ps1"
    WIN_INPUT=$(wslpath -w "$INPUT_ABS" 2>/dev/null || echo "$INPUT_ABS")
    WIN_OUTPUT=$(wslpath -w "$OUTPUT_PDF" 2>/dev/null || echo "$OUTPUT_PDF")
    WIN_SCRIPT=$(wslpath -w "$PS1_TEMP" 2>/dev/null || echo "$PS1_TEMP")

    cat > "$PS1_TEMP" << PSEOF
\$pptxPath = "$WIN_INPUT"
\$pdfPath = "$WIN_OUTPUT"

\$powerpoint = New-Object -ComObject PowerPoint.Application
\$presentation = \$powerpoint.Presentations.Open(\$pptxPath, \$false, \$false, \$false)
\$presentation.SaveCopyAs(\$pdfPath, 32)
\$presentation.Close()
\$powerpoint.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$presentation) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$powerpoint) | Out-Null
Write-Host "PDF exported: \$pdfPath"
PSEOF

    powershell.exe -ExecutionPolicy Bypass -File "$WIN_SCRIPT" 2>&1 || {
        echo "⚠️  PowerShell 管道失败，尝试备选管道 (LibreOffice)..."
        cd "$INPUT_DIR"
        soffice --headless --convert-to pdf "$INPUT_ABS" 2>&1 || {
            echo "❌ 两个管道均失败。"
            exit 3
        }
    }
    rm -f "$PS1_TEMP"
fi

# Step 3: 验证
echo ""
echo "🔍 Step 3/3: 验证输出 PDF..."
if [ -f "$OUTPUT_PDF" ]; then
    SIZE=$(stat --printf="%s" "$OUTPUT_PDF" 2>/dev/null || stat -f%z "$OUTPUT_PDF" 2>/dev/null || echo 0)
    echo "  文件大小: $(( SIZE / 1024 )) KB"
    python3 "$CHECKER" "$OUTPUT_PDF" 2>/dev/null || echo "⚠️  PDF字体检查发现问题（非阻塞）"
    echo ""
    echo "✅ PDF 导出完成: $OUTPUT_PDF"
else
    echo "❌ 输出 PDF 未生成"
    exit 4
fi
