#!/bin/bash
# TRIO 基础版 环境检测器
# 用法: bash setup.sh
# 不会安装任何东西——只告诉你还缺什么、怎么装

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

PASS=0; WARN=0; FAIL=0
MISSING=()

check() {
    local name="$1"; shift
    local cmd="$1"; shift
    local fix="$*"
    if command -v "$cmd" &>/dev/null; then
        local ver=$($cmd --version 2>/dev/null | head -1 || echo "?")
        echo -e "  ${GREEN}✅${NC} 已装备 $name — $ver"
        PASS=$((PASS + 1))
    else
        echo -e "  ${YELLOW}⬜${NC} 空槽位——$name 还没拿到"
        echo -e "     ${CYAN}🗺️  获取方式: $fix${NC}"
        MISSING+=("$name: $fix")
        FAIL=$((FAIL + 1))
    fi
}

check_version() {
    local name="$1"; local cmd="$2"; local min="$3"; local fix="$4"
    if command -v "$cmd" &>/dev/null; then
        local ver=$($cmd --version 2>/dev/null | grep -oP '\d+\.\d+' | head -1 || echo "0")
        if [ "$(printf '%s\n' "$min" "$ver" | sort -V | head -1)" = "$min" ]; then
            echo -e "  ${GREEN}✅${NC} 已装备 $name — $ver (≥$min)"
            PASS=$((PASS + 1))
        else
            echo -e "  ${YELLOW}⚠️${NC}  $name 版本偏低 ($ver < 需要 $min)"
            echo -e "     ${CYAN}🗺️  获取方式: $fix${NC}"
            WARN=$((WARN + 1))
        fi
    fi
}

echo ""
echo -e "  ⚔️  ${BOLD}冒险准备——检查你的背包${NC}"
echo ""
echo -e "  出发前看看包里还缺什么……"
echo ""

# ═══ 系统 ═══
echo -e "${BOLD}🌍  所在的世界${NC}"
case "$(uname -s)" in
    Linux*)
        if grep -qi microsoft /proc/version 2>/dev/null; then
            echo -e "  ${GREEN}✅${NC} WSL2 (Windows Linux 子系统)"
        else
            echo -e "  ${GREEN}✅${NC} Linux"
        fi
        ;;
    Darwin*) echo -e "  ${GREEN}✅${NC} macOS" ;;
    MINGW*|MSYS*)
        echo -e "  ${RED}❌${NC} Git Bash 不支持——TRIO 需要真实 Linux 环境"
        echo -e "     ${CYAN}→ Windows 用户请装 WSL2: wsl --install${NC}"
        echo -e "     ${CYAN}→ 然后把 TRIO 放在 WSL 里 (如 ~/TRIO)，不要放 /mnt/c/${NC}"
        FAIL=$((FAIL + 1))
        ;;
    *) echo -e "  ${YELLOW}⚠️${NC}  未知系统: $(uname -s)" ;;
esac

# ═══ Bash ═══
check_version "Bash" bash 4.0 "Mac: brew install bash | Linux: sudo apt install bash"

# ═══ Git ═══
check "Git" git "Mac: brew install git | Linux: sudo apt install git | Windows: 装 WSL2 后自带"

# ═══ Node.js ═══
check_version "Node.js" node 18.0 "Mac: brew install node | Linux: sudo apt install nodejs"

# ═══ npm ═══
check "npm" npm "Mac: 随 Node.js 安装 | Linux: sudo apt install npm"

# ═══ Python ═══
check_version "Python 3" python3 3.10 "Mac: brew install python@3.12 | Linux: sudo apt install python3"

# ═══ 解压工具 ═══
check "unzip" unzip "sudo apt install unzip"
check "curl" curl "sudo apt install curl"
check "wget" wget "sudo apt install wget"

# ═══ Claude Code ═══
if command -v claude &>/dev/null; then
    echo -e "  ${GREEN}✅${NC} Claude Code — $(claude --version 2>/dev/null || echo '已安装')"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌${NC} Claude Code 未安装"
    echo -e "     ${CYAN}→ npm install -g @anthropic-ai/claude-code${NC}"
    echo -e "     ${CYAN}→ 如果 npm 全局安装后找不到命令:${NC}"
    echo -e "     ${CYAN}   echo 'export PATH=\"\$PATH:\$(npm prefix -g)/bin\"' >> ~/.bashrc${NC}"
    MISSING+=("Claude Code: npm install -g @anthropic-ai/claude-code")
    FAIL=$((FAIL + 1))
fi

# ═══ TRIO 配置 ═══
echo ""
echo -e "${BOLD}🗺️  地图与营地${NC}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -f "$SCRIPT_DIR/config/paths.conf" ]; then
    echo -e "  ${GREEN}✅${NC} config/paths.conf 已配置"
    source "$SCRIPT_DIR/config/paths.conf"
    echo -e "     TRIO_DB = ${CYAN}${TRIO_DB:-未设置}${NC}"
    if [ -d "${TRIO_DB:-}" ]; then
        echo -e "  ${GREEN}✅${NC} 数据目录已创建"
    else
        echo -e "  ${YELLOW}⚠️${NC}  数据目录不存在——TRIO 首次运行时会自动创建"
    fi
else
    echo -e "  ${YELLOW}⚠️${NC}  config/paths.conf 未配置，使用自动检测"
    source "$SCRIPT_DIR/config/platform.sh"
    echo -e "     TRIO_PLATFORM = ${CYAN}${TRIO_PLATFORM:-未知}${NC}"
    echo -e "     TRIO_DB = ${CYAN}${TRIO_DB:-未设置}${NC}"
    echo -e "     ${CYAN}→ 如需自定义: cp config/paths.conf.example config/paths.conf${NC}"
fi

# ═══ API Key ═══
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    echo -e "  ${GREEN}✅${NC} ANTHROPIC_API_KEY 已设置"
elif [ -n "${DEEPSEEK_API_KEY:-}" ] || [ -n "${OPENAI_API_KEY:-}" ]; then
    echo -e "  ${GREEN}✅${NC} 第三方 API Key 已设置 (非 Anthropic)"
else
    echo -e "  ${YELLOW}⚠️${NC}  未检测到 API Key 环境变量"
    echo -e "     ${CYAN}→ 获取 Anthropic key: https://console.anthropic.com/${NC}"
    echo -e "     ${CYAN}→ 然后运行: export ANTHROPIC_API_KEY='sk-ant-api03-...'${NC}"
    echo -e "     ${CYAN}→ 建议写入 ~/.bashrc 让它每次终端启动时自动生效${NC}"
    WARN=$((WARN + 1))
fi

# ═══ 总结 ═══
echo ""
echo -e "${BOLD}═══════════════════════════════════════${NC}"
echo -e "  背包检查: ${GREEN}${PASS} 件装备${NC}  ${YELLOW}${WARN} 待升级${NC}  ${RED}${FAIL} 空槽位${NC}"
echo -e "${BOLD}═══════════════════════════════════════${NC}"

if [ "$FAIL" -gt 0 ]; then
    echo ""
    echo -e "${RED}还差 ${FAIL} 件装备。没关系，冒险不着急——收集齐了再出发！${NC}"
    echo ""
    for m in "${MISSING[@]}"; do
        echo -e "  ${RED}▸${NC} $m"
    done
    echo ""
    echo "📖 详细攻略: SETUP.md"
elif [ "$WARN" -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}⚠️  背包基本满了 (${WARN} 件装备可以升级)。不升级也能出发，升级了更顺手！${NC}"
    echo ""
    echo "下一步: bash init.sh && claude"
else
    echo ""
    echo -e "${GREEN}🎉 背包满了！准备出发 🎒✨${NC}"
    echo ""
    echo "下一步: bash init.sh && claude"
    echo "试试: /速判 <你感兴趣的公司或概念>"
fi

# ═══ 数据目录初始化（已废弃——请使用 init.sh） ═══
if [ "${1:-}" = "--init" ]; then
    echo ""
    echo -e "${YELLOW}⚠️  setup.sh --init 已废弃。请使用: bash init.sh${NC}"
    echo ""
    if [ -f "$SCRIPT_DIR/config/paths.conf" ]; then
        source "$SCRIPT_DIR/config/paths.conf"
    else
        source "$SCRIPT_DIR/config/platform.sh"
    fi
    if [ -n "${TRIO_DB:-}" ]; then
            mkdir -p "$TRIO_DB/知识库" "$TRIO_DB/项目" "$TRIO_DB/归档" "$TRIO_DB/runs"
            if [ ! -f "$TRIO_DB/知识库/index.md" ]; then
                echo "# 知识库索引" > "$TRIO_DB/知识库/index.md"
                echo "" >> "$TRIO_DB/知识库/index.md"
                echo "> 首次使用 TRIO 后自动填充。" >> "$TRIO_DB/知识库/index.md"
            fi
            echo -e "  ${GREEN}✅${NC} 数据目录已创建: ${CYAN}$TRIO_DB${NC}"
            echo -e "     ├── 知识库/"
            echo -e "     ├── 项目/"
            echo -e "     ├── 归档/"
            echo -e "     └── runs/"
        fi
    fi

echo ""
