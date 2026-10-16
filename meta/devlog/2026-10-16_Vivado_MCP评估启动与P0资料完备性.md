# Devlog 2026-10-16：Vivado MCP 评估启动 + P0 资料完备性检查

> 两件事：(1) 用户指示评估 AMD 官方 Vivado MCP（Ross），目标=常驻会话能否规避 batch 模式
> 间歇读文件失败；(2) 用户给出 FBG_32CH 项目的预想 P0 交互流程，评审后把采纳的模式沉淀进模板。

## 1. Vivado MCP 调研结论（官方来源）

- 官方工具真实存在：**AMD Ross Agentic AI Assistant**（github.com/Xilinx/ross-ai-assistant，
  MIT），Vivado MCP Server 提供 `vivado_start/stop/connect/execute/status/log_messages` 等工具，
  常驻会话通过 Vivado 内置 `webserver` Tcl 命令 + smart proxy 通信。
- **下载**：二进制只在 account.amd.com（需 AMD 账号登录），GitHub Release 无二进制。
  Windows 版：`vivado-mcp-server-windows-amd64-2026.9.1.exe`。agent 无法代下（账号），
  已把"5 分钟手动步骤"写进 FBG_32CH/VIVADO_MCP_SETUP.md，`.mcp.json` 已预配。
- **兼容性关键事实**：官方测试基线 Vivado **2026.1**，本机 **2021.1**；官方称"架构上兼容
  所有已发布版本"（走标准 Tcl webserver 接口），已实测 2021.1 存在 `webserver` 命令——
  通信通道可用，个别工具若用新版 Tcl API 按个案处理。
- **评估协议**：batch 与 MCP 并存；先在 FBG_32CH 统计 batch 模式失败率作基线
  （check_elab × 5），用户下载二进制后再用 MCP 常驻会话跑同样脚本对比。
  若确认有效 → 修订 ADR 0019（"暂不引入 Vivado MCP"本来就是"当前取舍"，留了重估口子）。

## 2. P0 预想流程评审（用户给出 FBG 解调仪场景）

评审结论：**流程骨架与模板 P0 主动提问协议高度重合**（建议答案+依据、多轮确认、清单全 ✅
才写 SRS），两处真实增强已采纳进模板：

| 预想流程元素 | 评审 | 处理 |
| --- | --- | --- |
| 每个问题 agent 先给建议答案，用户确认或自定义 | 已是协议内容（§3.1"建议答案+依据"） | 不改，预想流程理解正确 |
| BOM/datasheet 未上传时 agent 应提醒，用户可选联网搜索 | **真实缺口**：原协议只被动说"参考资料已上传（如有）" | 采纳：P0 §1a 资料完备性检查（BOM 级清单 → 缺则提醒上传/联网检索落盘 docs/refs/ 记来源；缺失器件的相关问题不得标 ✅） |
| 多轮后汇总清单，用户修改，确认后"开始下一阶段" | 基本符合，但"是否开始代码设计"措辞有风险 | 采纳并纠偏：明确"开始下一阶段"= 走 /project:gate（G1）；G1 后是 P1 架构，代码设计从 P2/P3 开始 |
| 清单全 ✅ 后直接进下一阶段 | **纠偏**：清单是中间产物，全 ✅ 后须先产出 SRS/RTM/立项书三份草稿并评审（§3.3 原有），再 G1 | playbook 已有，评审回复中显式强调 |

模板改动：`workflow/P0_requirements.md`（§1a 新增 + §3.2 阶段语义 + §4 措辞更新）。

## 3. FBG_32CH 项目目录状态

- `E:\Zynq7020\FBG_32CH` = 模板 e1ba24d+ 克隆，uv 已 sync，`scripts/tests` 自测绿，
  `check_gate.py status` 行为正确（全 UNKNOWN，fail-closed）。
- `.mcp.json`（项目级 vivado-mcp，预配路径）+ `VIVADO_MCP_SETUP.md`（下载/注册/验证步骤）。
- **待用户**：下载 MCP 二进制（AMD 账号）→ 放约定路径 → 新会话批准 vivado-mcp → 冒烟对比。
