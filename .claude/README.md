# .claude/ —— 项目级 Agent 配置

| 内容 | 加载机制 | 说明 |
| --- | --- | --- |
| `agents/` | 子代理（Agent 工具调用） | 角色化 agent：rtl-engineer（P3 RTL 线）、golden-modeler（P3 GM 线）、verification-lead（P4）。只放角色纪律；路径绑定的编码规范在 `rules/` |
| `rules/` | **路径懒加载** | 按 `paths` frontmatter 在编辑匹配文件时才注入：rtl-style（hw/rtl/**）、tb-style（hw/verif/**）、tcl-ops（工具脚本）。白捡的 context 节省 |
| `commands/` | 用户显式 `/project:<名>` | 人触发固定流程：`gate`（门禁申请）、`new-module`（六步 checklist）、`module-check`（端口检查） |
| `settings.example.json` | — | 权限示例：预批准只读检查与构建命令。审阅后重命名为 `settings.json` 生效（可自行裁剪） |

> 加载机制的分工逻辑（ADR 0016）：总是加载的铁律/路由放根 `CLAUDE.md`；阶段流程在 `workflow/`（由 CLAUDE.md 入口按 project.yaml 阶段路由）；编码规范按路径懒加载在 `rules/`；人触发流程在 `commands/`；模型自动调用的能力封装为 `skills/`（第三批起，稳定后才封装）。

## 插件化打包边界（ADR 0018）

本目录的 `agents/` + `commands/`（+ 未来 `skills/`）被设计为**可原样抽取为 Claude Code 插件**：
- 这三个目录的内容只引用**项目内相对路径**（workflow/、docs/、scripts/、hw/），不含用户私有信息
- 抽取方式：复制为 `<plugin>/agents|commands|skills/` + 添加 `<plugin>/.claude-plugin/plugin.json` 清单，**零重写**
- **不带走的**：`settings*.json`（权限随项目，不进插件）、`rules/` 中的路径模式随目标项目骨架生效（骨架一致则规则通用）
- 随插件配套但不进 `.claude/` 的部分：`scripts/`（检查器）、`workflow/`（playbook）、`docs/templates/`——插件可携带，安装时落入项目对应位置（第五批初始化工具的职责）

## amd-doc-search MCP（官方手册检索 —— ⏸️ 默认不启用，ADR 0007）

> **当前状态：不启用。** MCP 会把一批工具常驻注入 Agent 上下文，造成上下文污染；
> 且当前阶段手册引用频率低，"手册地图 + 提示词引用规范"已够用。
> 本节内容仅作**备选记录**，需要时再由用户显式启用。

AMD 官方提供 **amd-doc-search MCP server**，检索 Vivado/Vitis/器件官方文档（UG/PG 手册），
权威、免维护、可绑定版本，且有本地知识库选项（检索不离开本机）。

**何时考虑启用**：涉及复杂原语/新 IP 配置、本地手册地图与模型记忆不足以支撑、或手册引用频繁到值得占上下文时。

**启用方式（届时由用户配置，二选一）：**
1. **Vivado AI Extension**（VS Code / Cursor 插件）——自带 Vivado MCP server + amd-doc-search 配置
2. **独立 MCP server**——按官方指引配置，可选本地知识库

配置入口与最新指引见官方仓库 `xilinx/ross-ai-assistant` 与 https://ross.amd.com/chat#setup 。

> 未启用期间，Agent 手册检索 = "手册地图（`docs/refs/xilinx/`）+ 提示词引用规范"：
> 引用具体数值/端口/属性前必须查证官方手册，无法查证时明确告知用户需查哪本手册哪一节，
> **禁止编造后标注"待核实"蒙混**（rtl-style.md 手册核实纪律）。

## 备注
本目录是**项目级** Claude Code 配置，会被项目内所有会话加载。
`settings.json` / `settings.local.json` 涉及权限授权，默认不入库（由用户本地重命名/自建），避免把授权规则传播到所有衍生项目。
个人指令覆盖用仓库根的 `CLAUDE.local.md`（同样 git 忽略）。
