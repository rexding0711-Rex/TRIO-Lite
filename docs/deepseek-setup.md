# 🔑 用你自己的 DeepSeek API

> 不想用 Anthropic 官方 API？没问题～TRIO 支持任何兼容 OpenAI 接口的第三方 provider。
> 这篇指南教你用 DeepSeek 跑 TRIO，省钱又好用。

---

## 前置条件

- 已经装好了 Claude Code（`claude --version` 能跑）
- 已经注册了 [DeepSeek 开放平台](https://platform.deepseek.com/) 并拿到了 API Key

---

## 第一步：设好 API Key

```bash
# 写入 Shell 配置文件，每次打开终端自动生效
echo 'export DEEPSEEK_API_KEY="sk-你的deepseek-key"' >> ~/.bashrc
source ~/.bashrc
```

> 💡 **Key 的格式**：DeepSeek 的 key 通常以 `sk-` 开头。

---

## 第二步：告诉 Claude Code 用 DeepSeek

在 TRIO 目录下创建 `.claude/settings.local.json`：

```json
{
  "apiKeyHelper": "echo $DEEPSEEK_API_KEY"
}
```

就这样！Claude Code 会自动把请求转发到 DeepSeek。

> ⚠️ 如果你的 `.claude/settings.local.json` 已经存在，在上面追加 `"apiKeyHelper"` 那一行就行——**不要覆盖已有的配置**。

---

## 第三步：验证一下

```bash
cd TRIO-Lite
claude
```

输入 `/速判 test` ——如果能跑通，说明 DeepSeek 已经接上了！🎉

---

## 进阶配置

### 指定模型（可选）

Claude Code 默认会用 DeepSeek 的最新模型。如果你有特定偏好（比如想省钱的场景用 `deepseek-chat`，复杂推理用 `deepseek-reasoner`），可以加 model 配置：

```json
{
  "apiKeyHelper": "echo $DEEPSEEK_API_KEY",
  "model": "deepseek-reasoner"
}
```

| 模型 | 适合 | 大概价格 |
|------|------|---------|
| `deepseek-chat` (V3) | 日常对话、内容创作、简单分析 | 超便宜 |
| `deepseek-reasoner` (R1) | 复杂推理、尽调、逆向工程 | 稍贵一点 |

> 💡 **TRIO 建议**：日常用 `deepseek-chat`，跑 `/尽调` 或 `/逆向工程` 时切到 `deepseek-reasoner`。

---

## DeepSeek vs Anthropic 官方——有什么区别？

| | Anthropic 官方 | DeepSeek |
|------|:--:|:--:|
| 💰 价格 | 较贵 | 超便宜（约 1/10-1/20） |
| 🧠 推理能力 | 顶尖 | 很强（约 85-90% 水平） |
| 🌐 中文支持 | 好 | 非常好 |
| 🔌 接口兼容 | 原生 Anthropic API | OpenAI 兼容接口 |
| 📦 上下文窗口 | 200K | 128K-1M（视模型） |

**简单说**：DeepSeek 性价比高，中文好，日常够用。Anthropic 官方在超复杂推理上更强一点。

---

## 常见问题

### Q: `claude` 启动后还是提示要 Anthropic API Key？

A: 确认两件事：
1. `echo $DEEPSEEK_API_KEY` 能输出你的 key
2. `.claude/settings.local.json` 在 TRIO 目录下（不是 `~/.claude/`）

### Q: 想同时用 DeepSeek 和 Anthropic？

A: 用 `/doer` `/auditor` `/suggestor` 命令时，可以给不同小伙伴配不同的 provider。高级玩法——有需要再聊。

### Q: 我想用其他 provider（OpenAI / 豆包 / Kimi）？

A: 流程完全一样——设环境变量 + 配 `apiKeyHelper`。Claude Code 支持任何 OpenAI 兼容接口。

---

> 💬 还是搞不定？提 [GitHub Issue](https://github.com/rexding0711-Rex/TRIO-Lite/issues) 或者直接在 TRIO 里问。
