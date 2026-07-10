
# @data-depends: metrics.md 表格格式 | 列名 | 值 | 目标 |
# @data-depends: DAILY.md 度量表格式同上
# @炸点: 两处任意列名重命名 → sync静默失败 → 数字不对齐

#!/usr/bin/env python3
"""按列名更新 Markdown 表格——替代 sed 正则硬匹配"""
import sys, re

def update_table(filepath, updates):
    """updates = {'列名': '新值', ...}"""
    with open(filepath) as f:
        content = f.read()
    
    for col_name, new_val in updates.items():
        # 匹配 | 列名 | 原值 | ... 格式
        content = re.sub(
            rf'(\|\s*{re.escape(col_name)}\s*\|)\s*\S+\s*(\|)',
            rf'\1 {new_val} \2',
            content
        )
    
    # 更新时间戳
    from datetime import datetime
    ts = datetime.now().strftime('%Y-%m-%d %H:%M')
    content = re.sub(r'^> 最后更新:.*', f'> 最后更新: {ts} | 自动同步', content, flags=re.M)
    
    with open(filepath, 'w') as f:
        f.write(content)
    return True

def update_daily(filepath, updates):
    """更新 DAILY.md 度量表"""
    with open(filepath) as f:
        content = f.read()
    for col_name, new_val in updates.items():
        content = re.sub(
            rf'(\|\s*{re.escape(col_name)}\s*\|)\s*\S+\s*(\|)',
            rf'\1 {new_val} \2',
            content
        )
    with open(filepath, 'w') as f:
        f.write(content)
    return True

if __name__ == '__main__':
    cmd = sys.argv[1]
    filepath = sys.argv[2]
    updates = dict(arg.split('=') for arg in sys.argv[3:])
    
    if cmd == 'metrics':
        update_table(filepath, updates)
    elif cmd == 'daily':
        update_daily(filepath, updates)
    print(f'✅ {filepath} 已更新 ({len(updates)} 项)')
