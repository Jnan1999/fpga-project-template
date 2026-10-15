# ADR 0002：Xilinx 官方手册检索三层方案

- 日期：2026-10-15
- 状态：已确认（其中"MCP 首选层"的实施时机被 [ADR 0007](0007_暂不启用amd-doc-search-MCP.md) 修订为：默认不启用，仅注释保留）

## 背景
编写 RTL（尤其涉及时钟原语、SelectIO、官方 IP）时需要权威参考。裸让模型"自行搜索"不可靠——模型可能凭记忆编造手册内容（端口名、参数默认值、时序数值）。用户提出三个候选：提示词搜索 / 手册地图 / 官方向量库，并询问主流 agent 对 RAG 的态度。

## 调查
- AMD 官方提供 **Ross Agentic AI Assistant**（github.com/xilinx/ross-ai-assistant），核心是 **amd-doc-search MCP server**，可检索官方文档，且有本地知识库选项
- 2025 年主流趋势：coding agent 从 embedding RAG 转向 **agentic search（grep/glob 工具式探索）**；Anthropic 明确 Claude Code 放弃 RAG（agentic search 在内部 benchmark 胜出）。关键词精确的技术手册检索天然适合 agentic search，RAG 的语义模糊匹配是短板

## 决策（三层叠加）
1. **amd-doc-search MCP（首选检索）**：官方权威、免维护、版本可绑定
2. **手册地图 `docs/refs/xilinx/`（必做）**：解决"该查哪本哪章"——MCP 解决"查得到"，地图解决"该查哪"
3. **提示词引用规范（兜底）**：引用手册内容必须注明 UG 编号 + 章节 + 文档版本，供用户审计

## 理由
三层互补：地图给路标、MCP 给权威内容、提示词规范给可审计性。不自建向量库（成本高、易过时、官方 MCP 已覆盖）。

## 后果
- 新建 `docs/refs/xilinx/README.md` 手册地图（版本绑定 2021.1）
- rtl-engineer agent 增加"官方优先"规则：能用官方 IP 不手搓；原语/推断模板照 UG901/UG953 写
- CLAUDE.md 行为总纲新增引用规范条款
- `.claude/` 增加 amd-doc-search MCP 接入说明（用户确认后启用）
