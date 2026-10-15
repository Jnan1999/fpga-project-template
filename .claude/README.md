# .claude/ —— 项目级 Agent 配置

| 内容 | 说明 |
| --- | --- |
| `agents/` | 角色化 agent：rtl-engineer（P3 RTL 线）、golden-modeler（P3 GM 线）、verification-lead（P4） |
| `settings.example.json` | 权限示例：预批准只读检查与构建命令。审阅后重命名为 `settings.json` 生效（可自行裁剪） |

## amd-doc-search MCP（官方手册检索 —— ⏸️ 默认不启用，ADR 0007）

> **当前状态：不启用。** MCP 会把一批工具常驻注入 Agent 上下文，造成上下文污染；
> 且当前阶段手册引用频率低，"手册地图 + 提示词引用规范"已够用。
> 本节能容仅作**备选记录**，需要时再由用户显式启用。

AMD 官方提供 **amd-doc-search MCP server**，检索 Vivado/Vitis/器件官方文档（UG/PG 手册），
权威、免维护、可绑定版本，且有本地知识库选项（检索不离开本机）。

**何时考虑启用**：涉及复杂原语/新 IP 配置、本地手册地图与模型记忆不足以支撑、或手册引用频繁到值得占上下文时。

**启用方式（届时由用户配置，二选一）：**
1. **Vivado AI Extension**（VS Code / Cursor 插件）——自带 Vivado MCP server + amd-doc-search 配置
2. **独立 MCP server**——按官方指引配置，可选本地知识库

配置入口与最新指引见官方仓库 `xilinx/ross-ai-assistant` 与 https://ross.amd.com/chat#setup 。

> 未启用期间，Agent 手册检索 = "手册地图（`docs/refs/xilinx/`）+ 提示词引用规范"
> （注明 UG号+章节+版本，凭已知权威写法作答并标注"待核实"）。

## 备注
本目录是**项目级** Claude Code 配置，会被项目内所有会话加载。
`settings.json` 涉及权限授权，默认不入库（由用户本地重命名启用），避免把授权规则传播到所有衍生项目。
