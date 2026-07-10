#!/bin/bash
# @layer: infra
# backup.sh — 备份模块
# 依赖: lib/common.sh (TRIO_ROOT, TRIO_DB, 颜色)

cmd_backup() {
    local backup_dir="$TRIO_DB/归档/TRIO-backups"
    mkdir -p "$backup_dir"
    local ts=$(date +%Y%m%d-%H%M)
    local archive="$backup_dir/trio-${ts}.tar.gz"

    (cd "$TRIO_ROOT" && tar -czf "$archive" --exclude=.git --exclude=state --exclude=__pycache__ . 2>/dev/null)

    if [ -f "$archive" ]; then
        echo "📦 备份完成: trio-${ts}.tar.gz ($(du -h "$archive" | cut -f1))"
        # 保留最近 7 个备份
        ls -t "$backup_dir"/trio-*.tar.gz 2>/dev/null | tail -n +8 | xargs rm -f 2>/dev/null
    else
        echo "⚠️ 备份失败"
    fi
}
