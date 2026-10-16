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

---

## 追加（同日）：工具操作定位修正（用户 clarifying 自由度理念）

用户 clarifying：少设计机械步骤、多给设计思路、相信大模型判断；建工程等低频固定操作不必封装成 command/skill，agent 看示例 tcl 自行改造即可；复杂操作（时序分析等）后续才做 skill。并追问 ops.yaml 机制与 SUMMARY 机读契约含义。

**澄清的事实**：ops.yaml 无强制力（CC 无代码读它，靠 CLAUDE.md 指向被 agent 阅读，本质是机器可读操作说明书）；SUMMARY 机读契约 = 脚本末尾必须输出 `=== SUMMARY ===` 段，agent 只认这段、没有则 fail-closed。

**修正动作**：
- 撤销铁律 5（禁止绕过 ops.yaml）——与"相信 agent 判断"冲突；CLAUDE.md 铁律回归 4 条，工具操作改为"工具操作"参考一节
- ops.yaml → 0.2.0：重定位为参考清单，补 `result_glob`（结果定位）+ `long_running`（长任务约定）
- tcl-ops.md：重写为"机读契约（唯一硬要求）+ 写法约定 + 不做 MCP"
- agent 定义清除残留铁律 5 引用
- 新增 ADR 0019（工具操作=参考非封装 + 不做 Vivado MCP + 自由度分级），标注修订 0017

**自由度分级（后续封装判断依据）**：①顺序禁忌→铁律 ②低频固定→示例脚本不封装 ③复杂方法论→skill（时序收敛/CDC 审查/失败归因/覆盖率收敛/寄存器表生成）④纯创意→只给思路。

关联 ADR：0019（修订 0017）。
