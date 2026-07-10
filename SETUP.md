# 🎮 新手村指南——从这里开始你的 TRIO 冒险

> 预计 15-30 分钟，跟着走就行。卡住了？跳到最下面的 [常见问题](#-卡住了) 看看。

---

## ⚔️ 冒险开始前——你需要什么

| 装备 | 干什么用 | 必须？ |
|------|---------|:--:|
| 🗡️ Claude Code CLI | TRIO 的小心脏——没有它跑不起来 | ✅ |
| 🔑 API Key | Claude Code 的通行证 | ✅ |
| 🧰 Python 3.10+ | 管理脚本 | ✅ |
| 🛡️ Bash 4.0+ | 所有脚本 | ✅ |
| 📦 Node.js 18+ | Claude Code 需要 | ✅ |
| 🗺️ Git | 下载 TRIO + 版本管理 | 🟡 推荐 |

> 💡 **TRIO 不需要 MCP 服务器。** 斜杠命令就是 Markdown 文件，Claude Code 原生支持。零基础也能用。

---

## 🏕️ 第一关：拿到引擎 (Claude Code)

### 1.1 先装 Node.js（如果还没有）

**Mac 勇者：**
```bash
brew install node
```

**Linux 勇者 (Debian/Ubuntu)：**
```bash
sudo apt update && sudo apt install nodejs npm
```

**Windows 勇者：**
TRIO 的脚本需要 Linux 环境。先召唤 WSL2：

```powershell
# 在 PowerShell（管理员）中念咒：
wsl --install
```

重启后进入 WSL 终端，然后按 Linux 方式继续。

验证咒语：
```bash
node --version   # 应该 ≥ 18.0
npm --version
```

### 1.2 装 Claude Code

```bash
npm install -g @anthropic-ai/claude-code
```

验证：
```bash
claude --version
```

> ❌ 提示 `claude: command not found`？跳到 [卡住了](#-卡住了) 看看。

---

## 🔑 第二关：获取通行证 (API Key)

### 方式 A：Anthropic 官方（推荐新手）

1. 打开 [Anthropic Console](https://console.anthropic.com/)
2. 注册/登录 → API Keys → Create Key
3. 复制 key（长得像：`sk-ant-api03-...`）

装备上：
```bash
# 写进 ~/.bashrc，每次打开终端自动生效
echo 'export ANTHROPIC_API_KEY="sk-ant-api03-你的key"' >> ~/.bashrc
source ~/.bashrc
```

### 方式 B：第三方 API（省钱！）

已经有 DeepSeek、OpenAI 或其他 provider 的 API？

👉 **跟着这个走**：[📖 第三方 API 配置指南](docs/deepseek-setup.md)（5 分钟搞定）

快速版（给老玩家）：
```bash
echo 'export DEEPSEEK_API_KEY="sk-你的key"' >> ~/.bashrc
source ~/.bashrc
echo '{"apiKeyHelper": "echo $DEEPSEEK_API_KEY"}' > .claude/settings.local.json
```

> DeepSeek 大概便宜 10-20 倍，中文也很好——日常用完全够。

---

## 🧰 第三关：收集工具 (Python + 环境检查)

### 装 Python 3

**Mac：**
```bash
brew install python@3.12
```

**Linux (Debian/Ubuntu)：**
```bash
sudo apt install python3
```

验证：
```bash
python3 --version   # 应该 ≥ 3.10
```

> ✅ TRIO 的 Python 脚本只用标准库——**不需要 pip install**。

### 运行背包检查

```bash
# 在 TRIO 目录中
bash setup.sh
```

它会告诉你还缺什么装备、怎么获取。缺了也别慌——每个空槽位都附了获取方式 🗺️

---

## 🎭 第四关：下载 TRIO

```bash
git clone https://github.com/rexding0711-Rex/TRIO-Lite.git
cd TRIO-Lite
```

> 💡 WSL 用户：把 TRIO 放在 Linux 文件系统里（如 `~/TRIO`），不要放 `/mnt/c/` 下。跨文件系统会很慢。

---

## ✨ 第五关：创建你的角色

```bash
bash init.sh
```

2 分钟，跟 TRIO 聊几句——你是谁、喜欢什么、在意什么。聊完就有了你的专属配置。

> 跳过也行——TRIO 用默认设定陪你。但聊过之后，它会越用越懂你。

---

## ⚔️ 出发！第一个任务

```bash
claude
```

进入后试试：

```
/速判 <你想了解的东西>
```

或者来个大冒险：

```
/尽调 <你感兴趣的公司或话题>
```

---

## 🆘 卡住了？

### `claude: command not found`
npm 全局安装的路径不在 `$PATH` 里。
```bash
npm list -g --depth=0          # 找到安装位置
export PATH="$PATH:$(npm prefix -g)/bin"   # 加到 ~/.bashrc
```

### `Permission denied`——脚本不让跑
```bash
chmod +x scripts/*.sh mgmt.sh
```

### WSL 用户——文件放哪？
放在 WSL 的 Linux 文件系统（如 `~/TRIO`），别放 `/mnt/c/` 下面。

### 数据目录 (`TRIO_DB`) 选哪？
- Mac/Linux: `$HOME/TRIO-data`
- WSL: `/mnt/d/TRIO-data`（D 盘，Windows 和 WSL 互通）

### bash 版本太低？
TRIO 需要 bash ≥ 4.0。Mac 用户注意——macOS 自带的 bash 是 3.2：
```bash
brew install bash
echo $BASH_VERSION   # 确认 ≥ 4.0
```

### 需要装 MCP 吗？
**不需要。** TRIO 的斜杠命令（`/尽调`、`/doer` 等）是 Claude Code 原生支持的 Markdown 格式。零基础直接用。

---

## 🗺️ 接下来的冒险

1. 🎭 认识面具：`/doer` `/auditor` `/suggestor`
2. ⚡ 快速判定：`/速判 <你感兴趣的公司>`
3. 🔬 深度尽调：`/尽调 <目标>`
4. 🌱 每天跑一次 `/日进化`——让 TRIO 记住你的成长

---

> 有问题？提 [GitHub Issue](https://github.com/rexding0711-Rex/TRIO-Lite/issues)。
> 想让 TRIO 更聪明？分享你的使用日志（纯模式数据，不含隐私）。
