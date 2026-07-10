#!/bin/bash
# ================================================================
# TRIO 基础版 · 新用户初始化向导
# ================================================================
# 用法: bash init.sh
#
# 四步对话式初始化:
#   Step 1 · 我是谁 —— 工作类型、语言、AI 态度
#   Step 2 · 我的地盘 —— 工作目录、项目组织方式
#   Step 3 · 我的标准 —— 质量门禁选择
#   Step 4 · 开始进化 —— 启用自进化引擎
#
# 产出:
#   config/user-config.json     — 用户配置（核心）
#   config/file-routing.json    — 文件路由规则
#   config/gate-framework.json  — 门禁框架
# ================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BOLD='\033[1m'; NC='\033[0m'

echo ""
echo -e "  ${BOLD}══════════════════════════════════════════════${NC}"
echo -e "  ${BOLD}🔒 不会装任何东西、不会碰系统文件、不会上传数据${NC}"
echo -e "  ${BOLD}══════════════════════════════════════════════${NC}"
echo ""
echo -e "✨  ${BOLD}Hello，我是你的 TRIO 呀！${NC}"
echo ""
echo -e "   先聊几个小问题，我就知道该怎么陪你了——"
echo -e "   你喜欢什么、在意什么、想把东西放在哪。"
echo ""

# 检查是否已经初始化过
if [ -f "$SCRIPT_DIR/config/user-config.json" ]; then
    echo -e "${YELLOW}⚠️  检测到已有 config/user-config.json${NC}"
    echo -e "   重新初始化会覆盖现有配置。"
    echo ""
    read -r -p "   继续？(y/N) " confirm
    if [ "${confirm,,}" != "y" ]; then
        echo "   已取消。"
        exit 0
    fi
    # 备份旧配置
    cp "$SCRIPT_DIR/config/user-config.json" "$SCRIPT_DIR/config/user-config.json.bak"
    echo -e "   ${GREEN}旧配置已备份为 user-config.json.bak${NC}"
    echo ""
fi

# ═══════════════════════════════════════════════════════════════
# Step 1 · 我是谁
# ═══════════════════════════════════════════════════════════════
echo -e "  ${BOLD}🌱 先认识一下——你是做什么的？${NC}"
echo ""

# 1.1 工作类型
echo "你主要做什么类型的工作？"
echo "  1) 尽调/研究 — 分析公司、行业、人物"
echo "  2) 开发/工程 — 写代码、架构设计、交付"
echo "  3) 写作/内容 — 文档、报告、创作"
echo "  4) 综合 — 以上都有"
echo "  5) 其他（自己描述）"
echo ""
read -r -p "  选 (1-5) [4]: " work_type
work_type="${work_type:-4}"
case "$work_type" in
    1) work_type_label="尽调/研究" ;;
    2) work_type_label="开发/工程" ;;
    3) work_type_label="写作/内容" ;;
    4) work_type_label="综合" ;;
    5) read -r -p "  请描述: " work_type_label ;;
    *) work_type_label="综合" ;;
esac
echo ""

# 1.2 工作语言
echo "你的主要工作语言？"
echo "  1) 简体中文"
echo "  2) English"
echo "  3) 中日英混合"
echo ""
read -r -p "  选 (1-3) [1]: " lang
lang="${lang:-1}"
case "$lang" in
    1) primary_lang="zh-CN"; cjk="true" ;;
    2) primary_lang="en"; cjk="false" ;;
    3) primary_lang="mixed"; cjk="true" ;;
    *) primary_lang="zh-CN"; cjk="true" ;;
esac
echo ""

# 1.3 AI 态度
echo "你怎么看待 AI 协作？"
echo "  1) 搭档 — AI 是另一个脑子，一起讨论、互相挑战"
echo "  2) 工具 — AI 是高效执行者，我给指令、它执行"
echo "  3) 导师 — AI 帮我学习、发现盲区、提升判断"
echo ""
read -r -p "  选 (1-3) [1]: " ai_attitude
ai_attitude="${ai_attitude:-1}"
case "$ai_attitude" in
    1) ai_role="partner" ;;
    2) ai_role="tool" ;;
    3) ai_role="mentor" ;;
    *) ai_role="partner" ;;
esac
echo ""

# ═══════════════════════════════════════════════════════════════
# Step 2 · 我的地盘
# ═══════════════════════════════════════════════════════════════
echo -e "  ${BOLD}🏠 你的地盘——东西都放在哪？${NC}"
echo ""

# 2.1 工作目录
echo "你的主要工作目录在哪？"
echo "  这个目录下面通常有你的项目、文档、资料。"
echo "  WSL 用户注意：Windows 路径如 D:\\MyProjects 对应 /mnt/d/MyProjects"
echo ""
read -r -p "  工作目录路径: " work_dir
if [ -z "$work_dir" ]; then
    work_dir="$HOME/TRIO-work"
    echo -e "  ${CYAN}未输入，使用默认: $work_dir${NC}"
fi
# 确保目录存在
mkdir -p "$work_dir" 2>/dev/null || echo -e "  ${YELLOW}⚠️  目录创建失败，请确认路径正确${NC}"
echo ""

# 2.2 项目组织方式
echo "你的项目怎么组织？"
echo "  1) 每个项目一个文件夹，全放在一起 (如 work/项目A, work/项目B)"
echo "  2) 按客户/领域分类 (如 work/客户A/项目1, work/行业X/项目2)"
echo "  3) 比较随意，没有固定结构"
echo ""
read -r -p "  选 (1-3) [1]: " org_style
org_style="${org_style:-1}"
case "$org_style" in
    1) org_pattern="flat" ;;
    2) org_pattern="grouped" ;;
    3) org_pattern="loose" ;;
    *) org_pattern="flat" ;;
esac
echo ""

# ═══════════════════════════════════════════════════════════════
# Step 3 · 我的标准
# ═══════════════════════════════════════════════════════════════
echo -e "  ${BOLD}🎯 你在意什么？——选你的质量标准${NC}"
echo ""
echo "你最在意什么？选你最关心的 1-5 项（空格分隔，选完回车）："
echo ""
echo "  [1] 数据来源 — 每条声明必须有出处，不能拍脑袋"
echo "  [2] 反方论证 — 结论必须有反面视角，不能只唱赞歌"
echo "  [3] 格式规范 — 交付物格式统一、排版干净"
echo "  [4] 置信标注 — 不确定的事必须标出来，不能推测冒充事实"
echo "  [5] 逻辑完整 — 推理链条不能跳步、不能循环论证"
echo "  [6] 时效检查 — 数据不能过时、引用必须是最新的"
echo "  [7] 安全红线 — 不执行危险命令、不泄露敏感信息"
echo "  [8] 可复现性 — 分析过程可追溯、结论可复现"
echo "  [9] 简洁优先 — 不要废话、不要过度分析、直击要点"
echo "  [0] 我全都要（默认启用以上全部）"
echo "  [C] 自定义 — 我自己描述我在意什么"
echo ""
read -r -p "  你的选择 [0]: " gates_choice
gates_choice="${gates_choice:-0}"

selected_gates=()
if [ "$gates_choice" = "0" ]; then
    selected_gates=(1 2 3 4 5 6 7 8 9)
elif [ "$gates_choice" = "C" ] || [ "$gates_choice" = "c" ]; then
    read -r -p "  请描述你在意的质量标准: " custom_gate
    selected_gates=("custom:$custom_gate")
else
    for g in $gates_choice; do
        selected_gates+=("$g")
    done
fi
echo ""

# ═══════════════════════════════════════════════════════════════
# Step 4 · 开始进化
# ═══════════════════════════════════════════════════════════════
echo -e "  ${BOLD}🚀 最后一步——让我越用越懂你${NC}"
echo ""
echo "我可以随着使用慢慢了解你的习惯——当然，你说了算。"
echo ""
echo "  日进化引擎：每天自动总结 + 发现你的重复模式"
read -r -p "  启用？(Y/n) " daily_evo
daily_evo="${daily_evo:-y}"

echo ""
echo "  自进化建议：当发现你的使用模式时，主动提议优化"
echo "  (如 '你每次都先审再动手，要不要我默认启动审计？')"
read -r -p "  启用？(Y/n) " auto_evo
auto_evo="${auto_evo:-y}"

echo ""
echo "  思维记录器：长期追踪你的思维偏好，生成认知画像"
echo "  (数据只存在本地，不上传)"
read -r -p "  启用？(Y/n) " thinking_rec
thinking_rec="${thinking_rec:-y}"
echo ""

# ═══════════════════════════════════════════════════════════════
# 生成配置文件
# ═══════════════════════════════════════════════════════════════
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "  正在生成配置..."
echo ""

# --- user-config.json ---
cat > "$SCRIPT_DIR/config/user-config.json" << UEOF
{
  "version": "1.0.0",
  "created": "$(date -Iseconds 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%S+00:00")",
  "user": {
    "work_type": "$work_type_label",
    "primary_language": "$primary_lang",
    "cjk_required": $cjk,
    "ai_role": "$ai_role"
  },
  "workspace": {
    "root": "$work_dir",
    "project_organization": "$org_pattern",
    "subdirs": {
      "projects": "$work_dir/项目",
      "knowledge": "$work_dir/知识库",
      "archive": "$work_dir/归档",
      "reports": "$work_dir/报告"
    }
  },
  "gates": {
    "selected": $(echo "${selected_gates[@]}" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().split()))" 2>/dev/null || echo "[]"),
    "hook": "pre-delivery"
  },
  "evolution": {
    "daily_evolution": $([ "${daily_evo,,}" = "y" ] && echo "true" || echo "false"),
    "auto_suggest": $([ "${auto_evo,,}" = "y" ] && echo "true" || echo "false"),
    "thinking_recorder": $([ "${thinking_rec,,}" = "y" ] && echo "true" || echo "false")
  },
  "_note": "这是你的 TRIO 配置。随时编辑此文件来调整。删除此文件后重新运行 bash init.sh 可以重来。"
}
UEOF

# --- file-routing.json ---
cat > "$SCRIPT_DIR/config/file-routing.json" << FEOF
{
  "version": "1.0.0",
  "description": "文件路由规则——TRIO 根据此文件判断新生成的文件该放哪",
  "workspace_root": "$work_dir",
  "routes": [
    {
      "id": "projects",
      "source_patterns": ["项目", "交付物", "deliverable", "report"],
      "dest": "$work_dir/项目",
      "auto": false,
      "description": "项目相关的交付物和报告"
    },
    {
      "id": "knowledge",
      "source_patterns": ["方法论", "模板", "SOP", "指南", "method", "template", "guide"],
      "dest": "$work_dir/知识库",
      "auto": false,
      "description": "可复用的方法论、模板、指南"
    },
    {
      "id": "archive",
      "source_patterns": ["归档", "旧版本", "archive", "old"],
      "dest": "$work_dir/归档",
      "auto": true,
      "description": "不再活跃的旧文件"
    }
  ],
  "forbidden_in_os": {
    "extensions": [".pptx", ".docx", ".pdf", ".xlsx", ".xls", ".png", ".jpg", ".gif", ".mp4", ".zip", ".db"],
    "message": "二进制文件不允许出现在 TRIO OS 目录。请放到工作目录。"
  },
  "uncertain_rules": {
    "action": "ask_user",
    "fallback_question": "这个文件该放哪？"
  },
  "_note": "编辑 routes 数组来添加你的文件路由规则。source_patterns 匹配文件路径关键词。auto=true 则自动搬移不询问。"
}
FEOF

# --- gate-framework.json ---
cat > "$SCRIPT_DIR/config/gate-framework.json" << GEOF
{
  "version": "1.0.0",
  "description": "门禁框架——交付前自动检查你定义的质量标准",
  "gates": $(python3 -c "
import json, sys
gate_map = {
    '1': {'id': 'source-trace', 'name': '数据来源检查', 'trigger': 'analysis', 'severity': 'block', 'desc': '每条声明必须有出处'},
    '2': {'id': 'counter-argument', 'name': '反方论证检查', 'trigger': 'analysis', 'severity': 'block', 'desc': '结论必须有反面视角'},
    '3': {'id': 'format-check', 'name': '格式规范检查', 'trigger': 'delivery', 'severity': 'warn', 'desc': '交付物格式统一、排版干净'},
    '4': {'id': 'confidence-label', 'name': '置信度标注检查', 'trigger': 'analysis', 'severity': 'block', 'desc': '不确定的事必须标置信度'},
    '5': {'id': 'logic-chain', 'name': '逻辑完整性检查', 'trigger': 'analysis', 'severity': 'block', 'desc': '推理链不能跳步或循环'},
    '6': {'id': 'freshness', 'name': '时效性检查', 'trigger': 'analysis', 'severity': 'warn', 'desc': '数据和引用不能过时'},
    '7': {'id': 'security', 'name': '安全红线检查', 'trigger': 'always', 'severity': 'block', 'desc': '不执行危险命令、不泄露敏感信息'},
    '8': {'id': 'reproducible', 'name': '可复现性检查', 'trigger': 'analysis', 'severity': 'warn', 'desc': '分析过程可追溯、结论可复现'},
    '9': {'id': 'brevity', 'name': '简洁性检查', 'trigger': 'delivery', 'severity': 'warn', 'desc': '不要废话、直击要点'},
}
selected = sys.argv[1].strip('[]').split(',')
gates = []
for g in selected:
    g = g.strip().strip(\"'\").strip('\"')
    if g in gate_map:
        gates.append(gate_map[g])
    elif g.startswith('custom:'):
        gates.append({'id': 'custom', 'name': g[7:], 'trigger': 'analysis', 'severity': 'warn', 'desc': '用户自定义'})
print(json.dumps(gates, indent=2, ensure_ascii=False))
" "${selected_gates[*]}" 2>/dev/null || echo "[]"),
  "built_in_gates": [
    {"id": "file-exists", "name": "文件路径存在", "severity": "block", "desc": "引用的文件路径必须真实存在"},
    {"id": "date-sanity", "name": "日期合理性", "severity": "block", "desc": "时间戳不能是未来日期"},
    {"id": "path-security", "name": "路径安全", "severity": "block", "desc": "不操作系统目录和敏感路径"}
  ],
  "hook_points": ["pre-delivery", "post-session"],
  "plugin_dir": "config/gates",
  "_note": "在 config/gates/ 目录下放入你的检查脚本（.sh 或 .py），在 gates 数组中引用即可。severity: block=阻断交付, warn=警告但放行, silent=只记录。"
}
GEOF

# 创建插件目录
mkdir -p "$SCRIPT_DIR/config/gates" "$SCRIPT_DIR/config/user-rules"
touch "$SCRIPT_DIR/config/gates/.gitkeep" "$SCRIPT_DIR/config/user-rules/.gitkeep"

# 创建知识库骨架（在工作目录下）
if [ -d "$work_dir" ]; then
    mkdir -p "$work_dir/知识库" "$work_dir/项目" "$work_dir/归档" "$work_dir/报告"
    if [ ! -f "$work_dir/知识库/INDEX.md" ]; then
        echo "# 知识库" > "$work_dir/知识库/INDEX.md"
        echo "" >> "$work_dir/知识库/INDEX.md"
        echo "> TRIO 会在使用过程中自动积累知识到这里。" >> "$work_dir/知识库/INDEX.md"
        echo "> 你也可以手动添加：方法论、模板、SOP、学习笔记等。" >> "$work_dir/知识库/INDEX.md"
    fi
fi

# ═══════════════════════════════════════════════════════════════
# 完成
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "  ${BOLD}🎉 好嘞，搞定啦！${NC}"
echo ""
echo -e "  从现在起，我就是你的 TRIO 了。"
echo ""
echo -e "  ${CYAN}你的专属档案已经生成：${NC}"
echo -e "    📋 config/user-config.json      — 你是谁、喜欢什么"
echo -e "    🗺️  config/file-routing.json    — 东西该放哪"
echo -e "    🛡️  config/gate-framework.json  — 你的质量标准"
echo ""
echo -e "  ${CYAN}你的地盘：${NC} $work_dir"
echo -e "    ├── 项目/     ← 你的冒险任务"
echo -e "    ├── 知识库/   ← 途中发现的宝藏"
echo -e "    ├── 报告/     ← 战利品"
echo -e "    └── 归档/     ← 过去的冒险"
echo ""
echo -e "  ${BOLD}开始你的第一次冒险：${NC}"
echo "    claude"
echo "    然后输入: /速判 <你想了解的东西>"
echo ""
echo -e "  ${YELLOW}💡 想调整什么？编辑 config/user-config.json，或者删掉它重新运行 bash init.sh。${NC}"
echo ""
