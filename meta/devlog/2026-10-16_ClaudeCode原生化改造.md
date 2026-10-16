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

---

## 追加（同日）：第二次外部评审驱动——核心原则修正（ADR 0020）

另一模型评审 0016~0019。核心批评：0019 放开"方法自由"正确，但"只认 SUMMARY"作为唯一硬要求过强（agent 可改脚本又只认 SUMMARY → 可能漏测却输出 PASS）。采纳其"方法自由、证据可追溯、验收不可自改"替代"SUMMARY 唯一硬要求"。

**采纳并落地：**
- CLAUDE.md「工具操作」重写为三原则（方法自由/证据可追溯/验收不可自改）+ 长任务三态
- ops.yaml → 0.3.0：补 check_ports SUMMARY 段（消除"某脚本可无 SUMMARY"冲突）、统一 run_sim 退出码为 0=PASS（消除"执行成功却退 0 但测试失败"口径冲突）、result_glob 注明"仅浏览，证据 run_id 绑定不回退最新"
- tcl-ops.md：机读契约段重写（SUMMARY=反馈非证据）+ 证据选择 run_id 绑定 + 长任务三态 + MCP 改"当前取舍"
- commands/module-check.md：**去自动修复**（检查权限不隐含修复权限，依接口契约定位该修哪侧由用户定）+ 修 `$ARGUMENTS`/`${ARGUMENTS}` 混用 bug
- commands/new-module.md：按阶段限定产出（P1/P2 只设计、P3 才实现）+ dft_mode 前置 + scaffold 不计已实现（纠正"先 RTL 后 LLD"）
- ADR 0018 标注"零重写是目标待验证"+ 两边界；ADR 0019 自由度改按风险分级 + MCP 理由收敛

**甄别后拒绝：** 评审的 `-coverage all`（仓库从无此项）、多处行号引用（与实际内容不符，系推测）；`disable-model-invocation`、`/gate` vs `/project:gate`、rules 触发时机三说法无法证实 → 标"待验证"不盲改。

**遗留未关闭项（列入第二批）**：check_ports 正则解析边界；contracts/interfaces.yaml 尚未被工具链消费（接口权威未贯通）。

关联 ADR：0020（修正 0019、部分修订 0018）。
