// ================================================================
// PPTX Blueprint v1.0 — TRIO 标准化 PPTX 生成模板
// ================================================================
// 使用说明：
//   1. 所有新 PPTX 脚本从此模板派生
//   2. 中文必须用 FONT.zh / FONT.zhBold，英文用 FONT.en / FONT.enBold
//   3. 绝对禁止直接写 "Arial" 作为中文 fontFace
//   4. 违者 check-cjk-fonts.py 会在生成后拦截
// ================================================================

const pptxgen = require("pptxgenjs");

// === 字体常量（锁定，不可覆盖） ===
// 用 Object.freeze 防止运行时被意外修改
const FONT = Object.freeze({
  zh:       "Microsoft YaHei",        // 中文正文 — 永远不要改成 Arial
  zhBold:   "Microsoft YaHei Bold",   // 中文标题
  en:       "Segoe UI",               // 英文/数字正文
  enBold:   "Segoe UI Bold",          // 英文/数字标题
  mono:     "Cascadia Code",          // 等宽/代码
});

// 运行时断言：如果检测到 FONT 被修改，立即报错
function assertFontNotLatin(fontName, context) {
  const forbidden = ["Arial", "Calibri", "Helvetica", "Times New Roman", "Cambria"];
  for (const bad of forbidden) {
    if (fontName.toLowerCase().includes(bad.toLowerCase())) {
      throw new Error(
        `[CJK-FONT-ERROR] ${context}: 检测到拉丁字体 "${fontName}" 被用于中文文本。\n` +
        `请使用 FONT.zh 或 FONT.zhBold 代替。\n` +
        `错误位置: ${context}`
      );
    }
  }
}

// === 色彩预设 — 科技深色风 ===
const COLOR = Object.freeze({
  space:    "080C1A",
  navy:     "0F1832",
  cardBg:   "141E3A",
  cyan:     "00D4FF",
  purple:   "7B5CFC",
  orange:   "FF6B35",
  green:    "00E5A0",
  coral:    "FF3B5C",
  white:    "FFFFFF",
  gray50:   "E8ECF4",
  gray300:  "8E94A5",
  gray500:  "5A6072",
  gray700:  "2D3345",
});

// === 工具函数 ===

// 创建章节封面页
function addChapterPage(slide, pres, partNum, title, subtitle) {
  slide.background = { color: COLOR.space };
  slide.addShape(pres.shapes.RECTANGLE, { x: 0, y: 0, w: 10, h: 0.03, fill: { color: COLOR.cyan } });
  slide.addShape(pres.shapes.RECTANGLE, { x: 7.2, y: 0, w: 2.8, h: 5.625, fill: { color: COLOR.navy, transparency: 40 } });
  slide.addText(`PART ${partNum}`, {
    x: 0.8, y: 1.3, w: 8.4, h: 0.5,
    fontSize: 14, fontFace: FONT.en, color: COLOR.orange, charSpacing: 8, margin: 0,
  });
  assertFontNotLatin(FONT.en, `章节页 PART ${partNum}`);
  slide.addText(title, {
    x: 0.8, y: 1.8, w: 8.4, h: 1.0,
    fontSize: 44, fontFace: FONT.zhBold, color: COLOR.white, margin: 0,
  });
  assertFontNotLatin(FONT.zhBold, `章节页标题 ${title}`);
  slide.addText(subtitle, {
    x: 0.8, y: 2.85, w: 8.4, h: 0.5,
    fontSize: 13, fontFace: FONT.zh, color: COLOR.gray300, margin: 0,
  });
  slide.addShape(pres.shapes.LINE, { x: 0.8, y: 3.5, w: 2.5, h: 0, line: { color: COLOR.orange, width: 3 } });
  slide.addShape(pres.shapes.RECTANGLE, { x: 0.8, y: 4.9, w: 3.0, h: 0.02, fill: { color: COLOR.purple } });
}

// 创建内容页标题
function addPageTitle(slide, pres, title, subtitle) {
  slide.background = { color: COLOR.white };
  slide.addShape(pres.shapes.RECTANGLE, { x: 0, y: 0, w: 10, h: 0.03, fill: { color: COLOR.cyan } });
  slide.addText(title, {
    x: 0.6, y: 0.3, w: 8.8, h: 0.55,
    fontSize: 24, fontFace: FONT.zhBold, color: COLOR.navy, margin: 0,
  });
  assertFontNotLatin(FONT.zhBold, `页面标题 ${title}`);
  if (subtitle) {
    slide.addText(subtitle, {
      x: 0.6, y: 0.85, w: 8.8, h: 0.3,
      fontSize: 11, fontFace: FONT.en, color: COLOR.gray500, margin: 0,
    });
  }
  slide.addShape(pres.shapes.LINE, { x: 0.6, y: 1.2, w: 2.0, h: 0, line: { color: COLOR.cyan, width: 2.5 } });
}

// 创建页脚
function addFooter(slide, pageNum) {
  slide.addText(`企业文件  |  机密  |  ${pageNum}`, {
    x: 0.4, y: 5.2, w: 9.2, h: 0.3,
    fontSize: 7, fontFace: FONT.en, color: COLOR.gray300, align: "right", margin: 0,
  });
}

// 关键指标卡片 (dashboard 风格)
function addMetricCard(slide, x, y, w, h, value, label, accentColor) {
  slide.addShape(pres.shapes.RECTANGLE, { x: x, y: y, w: w, h: h, fill: { color: COLOR.cardBg }, shadow: { type: "outer", blur: 6, offset: 2, angle: 135, color: "000000", opacity: 0.25 } });
  slide.addShape(pres.shapes.RECTANGLE, { x: x, y: y, w: w, h: 0.04, fill: { color: accentColor } });
  slide.addText(value, {
    x: x + 0.15, y: y + 0.2, w: w - 0.3, h: h * 0.5,
    fontSize: 26, fontFace: FONT.enBold, color: accentColor, align: "center", margin: 0,
  });
  slide.addText(label, {
    x: x + 0.15, y: y + h * 0.55, w: w - 0.3, h: h * 0.35,
    fontSize: 10, fontFace: FONT.zh, color: COLOR.gray300, align: "center", margin: 0,
  });
}

// 导出（配合 require 使用）
module.exports = {
  FONT,
  COLOR,
  assertFontNotLatin,
  addChapterPage,
  addPageTitle,
  addFooter,
  addMetricCard,
  pptxgen,
};
