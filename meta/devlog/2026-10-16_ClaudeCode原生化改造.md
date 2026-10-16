# Devlog 2026-10-16：第一批收尾——Claude Code 原生化改造（rules/commands/ops/插件边界）

## 背景
用户提出 agent 三层划分（设计层/工作流层/工具操作层），随后确认"参考 Claude Code 典型项目结构改造，后期封装成插件"。评审确认职责分层正确，但需叠加 Claude Code 的**加载时机轴**（rules 是路径懒加载，非全局生效——用户贴的目录注释有误，已勘正）。

## 动作
**新增：**
- `.claude/rules/`：rtl-style.md（paths: hw/rtl/**）、tb-style.md（hw/verif/**）、tcl-ops.md（工具脚本/**.tcl）——编码规范从 agent 定义剥离，编辑对应文件时才注入
- `.claude/commands/`：gate.md / new-module.md / module-check.md——人触发固定流程
- `hw/scripts/ops.yaml`：工具操作层契约（ops_version 0.1.0；三个 op：create_impl_project/run_sim/check_ports；五要素 entry/kind/artifacts/summary/exit_code；actuation vs verification 分类；预登记二批/四批 op）
- `.claude/settings.example.json`：恢复示例文件（用户此前重命名启用后模板缺示例）；授权补 `uv run python` 与 `uv sync` 形式
- ADR 0016（双轴架构+铁律5）/0017（op 契约与 commands 边界）/0018（插件化打包边界）

**修改：**
- CLAUDE.md：加铁律 5（禁止绕过 ops.yaml 拼工具命令）；路径速查加 ops/rules/commands 行；常用命令表改斜杠命令 + op 名
- 三个 agent 定义：编码规范改为指向 rules（瘦身），保留角色纪律；rtl-engineer 手册核实表述从"标注待核实"升级为"必须查证，无法查证明确告知用户查哪本手册哪节"（堵编造风险）
- .claude/README.md：重写（加载机制表 + 插件迁移指南 + MCP 节同步手册核实纪律）
- README.md：组件表加 rules/commands/ops.yaml 行；铁律改五条；目录树注释更新
- .gitignore：补 CLAUDE.local.md（个人覆盖文件不入库）
- meta/decisions/README.md：索引加 0016/0017/0018 + 关系说明

**设计约束（ADR 0018）**：.claude/agents|commands|skills 只引用项目内相对路径、无私有信息，保证"复制目录 + plugin.json 清单 = 插件"零重写。settings/CLAUDE.md 不进插件；rules 随骨架分发。

**注意**：`.claude/settings.json`（用户本地，git 忽略）中旧授权仍为 `python ...` 形式，第二批 uv 落地时用户需按新的 settings.example.json 手动同步。

关联 ADR：0016/0017/0018。后续：第二批契约工具批（check_gate.py 将登记为 verification op，gates.yaml 引用 contracts/interfaces.yaml）。
