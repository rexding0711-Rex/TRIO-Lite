# @layer: interface
# /TRIO

TRIO 基础版 状态总览——环境检测 + 运行状态 + 角色管理 + 架构调整。

## 执行

### Step 0: 环境检测
运行 `bash setup.sh`。根据输出：
- **❌ 缺失 > 0** → 停止状态展示，进入安装向导模式。引导用户按 `SETUP.md` 逐步修复。
- **⚠️ 警告 > 0** → 提示用户，然后继续展示状态。
- **✅ 全部通过** → 继续展示状态。

### Step 1: 运行状态
扫描 `runs/` 下所有 `state.json`，按状态分组展示：
- 🔵 running — 正在执行（含进度条 step/total_steps）
- 🟡 paused_escalate — 暂停等待裁决（提示用 /trio-resume 恢复）
- 🟢 completed — 已完成
- ⚫ aborted — 用户终止
- 💀 zombie — running 但超过 2 小时未更新（建议 /trio-abort）

### Step 2: 角色清单
遍历 `config/roles/` 所有角色文件，按类型分组展示：
- 🎨 发散型 (Suggestor)
- 🔍 审计型 (Auditor)
- 🔧 工程型 (Doer)

### Step 3: 知识库状态
检查知识库最后更新时间、公司库条目数、待归档数量。

### Step 4: 架构调整（子功能）
当用户需要管理角色和场景时触发：
- `合并 A + B → C` — 两个角色合并为新角色
- `休眠 X` — 标记角色为 dormant
- `激活 Y` — 从 archive 恢复角色
- `新增场景 S` — 创建新场景 JSON + 命令 md

调整后遍历 `config/roles/` 全部角色文件校验 frontmatter 必填字段，遍历 `config/scenarios/` 校验每步 role 在角色目录中存在。

## 输出格式
```
TRIO 基础版 | v2.0 | {时间}

🔵 运行中 (N): {run_id} — [████░░] step N/M
🟡 等待裁决 (N): {run_id} → /trio-resume {run_id}
🟢 已完成 (N): {run_id}

角色: {N} | 场景: {N} | 命令: {N}
知识库: 最后更新 {时间} | 公司库: {N}家
```
