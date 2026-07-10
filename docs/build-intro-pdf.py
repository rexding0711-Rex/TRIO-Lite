"""TRIO基础版 介绍PDF生成器"""
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm
from reportlab.lib.colors import HexColor
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
import os

# 注册中文字体
font_paths = [
    "/usr/share/fonts/truetype/arphic-gkai00mp/gkai00mp.ttf",   # AR PL UKai - 楷体
    "/usr/share/fonts/truetype/arphic-gbsn00lp/gbsn00lp.ttf",   # AR PL UMing - 明体
]

font_reg = None
for fp in font_paths:
    if os.path.exists(fp):
        try:
            pdfmetrics.registerFont(TTFont('CJKFont', fp))
            font_reg = 'CJKFont'
            print(f"✅ 使用字体: {fp}")
            break
        except Exception as e:
            print(f"⚠️ {fp}: {e}")
            continue

if not font_reg:
    raise RuntimeError("无法注册中文字体")

FONT = font_reg
print(f"✅ 使用字体: {FONT}")

# 颜色
BLACK = HexColor('#000000')
WHITE = HexColor('#FFFFFF')
GRAY = HexColor('#555555')
LIGHT_GRAY = HexColor('#F5F5F5')
ACCENT = HexColor('#1a1a1a')

WIDTH, HEIGHT = A4

# 样式
styles = getSampleStyleSheet()

style_title = ParagraphStyle('CNTitle', fontName=FONT, fontSize=28, leading=36,
    alignment=TA_CENTER, textColor=BLACK, spaceAfter=6*mm)
style_subtitle = ParagraphStyle('CNSubtitle', fontName=FONT, fontSize=12, leading=18,
    alignment=TA_CENTER, textColor=GRAY, spaceAfter=12*mm)
style_h1 = ParagraphStyle('CNH1', fontName=FONT, fontSize=18, leading=24,
    textColor=BLACK, spaceBefore=10*mm, spaceAfter=4*mm)
style_h2 = ParagraphStyle('CNH2', fontName=FONT, fontSize=14, leading=20,
    textColor=BLACK, spaceBefore=6*mm, spaceAfter=2*mm)
style_body = ParagraphStyle('CNBody', fontName=FONT, fontSize=10, leading=16,
    textColor=BLACK, spaceAfter=2*mm)
style_small = ParagraphStyle('CNSmall', fontName=FONT, fontSize=8, leading=12,
    textColor=GRAY)
style_center = ParagraphStyle('CNCenter', fontName=FONT, fontSize=10, leading=16,
    alignment=TA_CENTER, textColor=BLACK)

def make_table(headers, rows, col_widths=None):
    """创建统一样式的表格"""
    data = [[Paragraph(h, style_h2)] for h in headers]
    data = [data[0]]  # 单行表头
    # 重新构建
    header_row = [Paragraph(h, ParagraphStyle('TH', fontName=FONT, fontSize=11, leading=16, textColor=WHITE)) for h in headers]
    data = [header_row]
    for row in rows:
        data.append([Paragraph(str(c), style_body) for c in row])

    if not col_widths:
        col_widths = [WIDTH*0.8/len(headers)] * len(headers)

    t = Table(data, colWidths=col_widths)
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), BLACK),
        ('TEXTCOLOR', (0, 0), (-1, 0), WHITE),
        ('BACKGROUND', (0, 1), (-1, -1), WHITE),
        ('GRID', (0, 0), (-1, -1), 0.5, HexColor('#CCCCCC')),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [WHITE, LIGHT_GRAY]),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('RIGHTPADDING', (0, 0), (-1, -1), 6),
    ]))
    return t

# 构建文档
output_path = "TRIO基础版-介绍.pdf"
doc = SimpleDocTemplate(output_path, pagesize=A4,
    leftMargin=20*mm, rightMargin=20*mm, topMargin=15*mm, bottomMargin=15*mm)

story = []

# 封面
story.append(Spacer(1, 30*mm))
story.append(Paragraph("TRIO 基础版", style_title))
story.append(Paragraph("三个视角，一个答案", style_subtitle))
story.append(Spacer(1, 8*mm))
story.append(Paragraph("同一问题，三种性格的 AI 从不同角度审视", style_center))
story.append(Paragraph("互相挑刺之后，你拿到的是经过对抗验证的答案", style_center))
story.append(Spacer(1, 20*mm))
story.append(Paragraph("版本 2.0  |  开源 MIT  |  6215 行代码  |  100% 本地", style_small_center := ParagraphStyle('SMC', fontName=FONT, fontSize=9, leading=14, alignment=TA_CENTER, textColor=GRAY)))
story.append(PageBreak())

# 核心机制
story.append(Paragraph("核心机制：三视角协作", style_h1))
story.append(Paragraph("TRIO 不是三个 AI 模型。它是<strong>同一个 AI，换三种思考方式</strong>：", style_body))
story.append(Spacer(1, 3*mm))

mask_data = [
    ['🎨 好奇宝宝', '发散·洞察·联想', '行业扫描、竞品情报、跨领域类比', '「诶，这个方向有点意思……」'],
    ['🔍 较真鬼',   '质疑·审计·验证', '事实核查、成本拆解、逻辑漏洞挖掘', '「等一下，你这句话没有证据」'],
    ['🔧 实干家',   '收敛·决策·交付', '架构设计、方案选择、文件打包',     '「好了，结论是这样，下一步做这个」'],
]
story.append(make_table(['面具', '性格', '擅长', '一句话'], mask_data, [22*mm, 28*mm, 58*mm, 62*mm]))
story.append(Spacer(1, 3*mm))
story.append(Paragraph("三个视角各自独立输出 → 实干家综合 → 一份「已经被挑过刺」的结论。", style_body))

# 15个命令
story.append(Paragraph("15 个命令", style_h1))

story.append(Paragraph("一键分析", style_h2))
cmd1 = [
    ['/速判', '快速评估（3-5分钟）', '想看个东西靠不靠谱'],
    ['/尽调', '全流程尽调（7步）', '深度评估公司/项目/方案'],
    ['/竞品', '竞品分析', '产品对比、市场定位'],
    ['/内容', '内容创作交付', '写文章、报告、方案'],
    ['/复盘', '快速审计复盘', '项目做完，回头看看'],
]
story.append(make_table(['命令', '功能', '场景'], cmd1, [25*mm, 55*mm, 90*mm]))

story.append(Paragraph("自由模式", style_h2))
cmd2 = [
    ['/trio-run', '三视角自由模式，不限场景'],
    ['/trio-resume', '恢复之前的 run'],
    ['/trio-abort', '取消进行中的 run'],
    ['/日进化', '每日知识沉淀'],
    ['/能力镜像', '查看能力成长情况'],
]
story.append(make_table(['命令', '功能'], cmd2, [35*mm, 135*mm]))

# 5个场景
story.append(Paragraph("5 个场景 SOP", style_h1))
story.append(Paragraph("每个场景是一套标准化的多步骤流程，不是简单问答：", style_body))
story.append(Spacer(1, 2*mm))

scene_data = [
    ['尽调', '7 步', '任务编排→行业定位→事实核查→成本拆解→叙事解剖→综合评分→打包', '评分卡+PDF'],
    ['竞品分析', '5 步', '扫描→对比→护城河→威胁→策略', '竞品矩阵+雷达图'],
    ['审计复盘', '5 步', '目标→结果对比→偏差→根因→改进', '审计报告'],
    ['内容交付', '4 步', '需求→大纲→初稿→审核→终稿', '文章/方案/报告'],
    ['快速评估', '3 步', '扫描→核查→判定', '评级+一句话结论'],
]
story.append(make_table(['场景', '步骤', '流程', '输出'], scene_data, [22*mm, 12*mm, 96*mm, 40*mm]))

# 11个角色
story.append(Paragraph("11 个工程角色", style_h1))
role_data = [
    ['产业情报工程师', '行业扫描、数据收集、竞品初筛'],
    ['事实核查工程师', '逐条验证声明、溯源、置信度标注'],
    ['成本拆解工程师', 'BOM 拆解、隐性成本、估值合理性'],
    ['因果分析工程师', '因果 DAG 构建、反事实检验'],
    ['复盘工程师', '系统性逻辑缺陷挖掘、PR vs 真相'],
    ['产品架构师', '10 维综合评分、最终判定、方案选择'],
    ['任务编排工程师', '复杂目标分解为子任务 DAG'],
    ['内容生产工程师', '文章/报告/方案的撰写与打磨'],
    ['全栈交付工程师', 'PDF/Word/Markdown/HTML 打包'],
    ['认知镜像工程师', '能力追踪、偏差校准'],
    ['资产盘点工程师', '知识库索引维护、技能提取'],
]
story.append(make_table(['角色', '职责'], role_data, [45*mm, 125*mm]))

# 技术架构
story.append(Paragraph("技术架构", style_h1))
story.append(Paragraph("用户 → 15 命令 → 场景路由(5 SOP) → 角色调度(11 角色) → 三视角输出 → 基础设施(备份/同步/进化/门禁)", style_body))
story.append(Spacer(1, 3*mm))
story.append(Paragraph("依赖: Claude Code（npm 全局安装）  |  数据: 100% 本地  |  协议: MIT", style_small))

# 适合谁
story.append(Paragraph("适合你 / 不适合你", style_h1))
fit_data = [
    ['✅ 觉得 AI 回答太快太自信，想要被验证过的答案', '❌ 只需要简单问答（ChatGPT 就够了）'],
    ['✅ 做分析/调研/评估类工作，需要结构化输出', '❌ 不需要结构化分析'],
    ['✅ 想看「三个角度讨论同一件事」发现盲区', '❌ 对命令行感到不适'],
    ['✅ 对 AI 工作流感兴趣，想有开箱即用框架', ''],
]
story.append(make_table(['适合', '不适合'], fit_data, [95*mm, 75*mm]))

story.append(Spacer(1, 12*mm))
story.append(Paragraph("TRIO 不是一个更好的 ChatGPT。它是你的思维搭档——三个性格不同的小伙伴，陪你一起想清楚。", style_center))

# 生成
doc.build(story)
print(f"✅ PDF 已生成: {output_path}")
print(f"   大小: {os.path.getsize(output_path) / 1024:.0f} KB")
