# logs/ —— 构建与仿真日志（结构化反馈通道）

> 约定：所有构建/仿真/检查脚本的日志统一落盘到本目录。
> 目的：**Agent 读日志自行分析，用户不再手工复制粘贴报错**。

## 命名规范
| 类型 | 文件名格式 |
| --- | --- |
| 仿真 | `sim_<mod>_<yyyymmdd_HHMMSS>.log` |
| 综合/实现 | `impl_<yyyymmdd_HHMMSS>.log` |
| 端口检查 | `check_ports_<yyyymmdd_HHMMSS>.log` |
| 回归批次 | `regress_<level>_<yyyymmdd_HHMMSS>.log`（level: smoke/regression/full） |

## SUMMARY 段（每个日志末尾必须输出，机读摘要）

```
=== SUMMARY ===
RESULT: PASS | FAIL
FAILED_TESTS: tb_xxx_003, tb_xxx_007    # 无失败则写 none
ERRORS: 0
WARNINGS: 12
KEY_METRICS: coverage_line=96.2%, wns=+0.123ns   # 按日志类型填关键指标
================
```

- Agent 只需读末尾 SUMMARY 段即可判断成败与关键指标；FAIL 时再向上检索具体 error
- 分析失败时 Agent 引用：`logs/<文件名>` + 行号，而不是让用户描述现象

## 实现状态
本约定当前为**文档规范**；tcl 脚本的 SUMMARY 输出与自动落盘在第二批实现（见 workflow 优化计划）。
