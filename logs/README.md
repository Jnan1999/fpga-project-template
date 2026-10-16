# logs/ —— 构建与仿真日志（结构化反馈通道）

> 约定：所有构建/仿真/检查脚本的日志统一落盘到本目录。
> 目的：**Agent 读日志自行分析，用户不再手工复制粘贴报错**。

## 命名规范
| 类型 | 文件名格式 |
| --- | --- |
| 仿真 | `sim_<yyyymmdd_HHMMSS>_<tb>.log`（run_sim.tcl 已落地） |
| 建实现工程 | `create_proj_<yyyymmdd_HHMMSS>.log`（create_impl_project.tcl 已落地） |
| elaboration 检查 | `elab_<yyyymmdd_HHMMSS>.log`（check_elab.tcl 已落地，G3 证据） |
| 综合/实现 | `impl_<yyyymmdd_HHMMSS>.log`（实现流程脚本落地时遵循） |
| 端口检查 | `check_ports_<yyyymmdd_HHMMSS>.log` |
| 回归批次 | `regress_<level>_<yyyymmdd_HHMMSS>.log`（level: smoke/regression/full） |

## SUMMARY 段（每个日志末尾必须输出，机读摘要）

```
=== SUMMARY ===
RESULT: PASS | FAIL
RUN_ID: <yyyymmdd_HHMMSS>[_<tb>]     # 运行身份（证据绑定，ADR 0012）
GIT_HASH: <git rev-parse --short HEAD>
TOOL_VERSION: <version 命令输出>
ERRORS: 0
<KEY>: <value>                       # 关键数值（用例计数、覆盖率、WNS 等，按日志类型）
===============
```

- **必带身份字段**：`RUN_ID` / `GIT_HASH` / `TOOL_VERSION`——gate 证据按 GIT_HASH 绑定当前源码（`scripts/check_gate.py` 的 evidence 检查），防过期/并行串用
- 关键数值用**独立 `KEY: value` 行**（如 `COV_LINE: 96.2`、`WNS_NS: 0.123`），不要塞进自由文本——check_gate 按字段核对
- Agent 只需读末尾 SUMMARY 段即可判断成败与关键指标；FAIL 时再向上检索具体 error
- 分析失败时 Agent 引用：`logs/<文件名>` + 行号，而不是让用户描述现象

## 实现状态
`run_sim.tcl` / `create_impl_project.tcl` / `check_elab.tcl` 已落地 SUMMARY 输出（第二批）；
回归/实现流程脚本落地时按本页规范补齐。
