# .claude/ —— 项目级 Agent 配置

| 内容 | 说明 |
| --- | --- |
| `agents/` | 角色化 agent：rtl-engineer（P3 RTL 线）、golden-modeler（P3 GM 线）、verification-lead（P4） |
| `settings.example.json` | 权限示例：预批准只读检查与构建命令。审阅后重命名为 `settings.json` 生效（可自行裁剪） |

## amd-doc-search MCP（官方手册检索，ADR 0002 首选层）

AMD 官方提供 **amd-doc-search MCP server**，检索 Vivado/Vitis/器件官方文档（UG/PG 手册）。
作为 RTL/时序阶段查手册的首选（权威、免维护、可绑定版本），与 `docs/refs/xilinx/` 手册地图互补。

**启用方式（需用户确认后配置，二选一）：**
1. **Vivado AI Extension**（VS Code / Cursor 插件）——自带 Vivado MCP server + amd-doc-search 配置
2. **独立 MCP server**——按官方指引配置，可选**本地知识库**（检索不离开本机）

配置入口与最新指引见官方仓库 `xilinx/ross-ai-assistant` 与 https://ross.amd.com/chat#setup 。

> 未接入 MCP 前，Agent 退化为"手册地图 + 提示词引用规范"（注明 UG号+章节+版本，凭已知权威写法作答并标注待核实）。
> 接入后 Agent 可直接调用 MCP 检索权威内容。

## 备注
本目录是**项目级** Claude Code 配置，会被项目内所有会话加载。
`settings.json` 涉及权限授权，默认不入库（由用户本地重命名启用），避免把授权规则传播到所有衍生项目。
