# contracts/ —— 机器可读契约（权威来源分层）

> 评审#2 / ADR 0011：原 `project.yaml` interfaces 表只有 name/from/to/protocol/width，
> **不足以支撑"P2 要求 LLD 与接口表信号级逐字一致"的检查**。因此把契约按权威来源分层。

## 权威来源分层（单一事实来源原则）

| 数据 | 权威来源 | 说明 |
| --- | --- | --- |
| 项目配置、模块索引、流程状态 | `project.yaml` | 阶段/模块/接口的**索引与状态** |
| 信号、参数、接口语义（机读） | `contracts/interfaces.yaml` | 逐信号的端口/方向/位宽表达式/时钟复位域/握手/异常语义 |
| 解释、图示、设计理由 | `docs/01_architecture/01-02_ICD.md`、各 LLD | 给人读；不复制机读字段，引用契约 |
| 当前执行状态与批准记录 | `project.yaml` + 验证证据 | 状态机与 gate 批准 |

**规则**：机读字段（信号名/位宽/方向/参数）只在 `contracts/interfaces.yaml` 出现一次；
ICD/LLD 用自然语言+表格解释并**引用**契约，不另建可漂移的副本。

## interfaces.yaml 每条接口至少包含
- `interface_version`：接口自身版本（冻结的是具体版本，不是一个可被继续修改的名称）
- 端点 `from`/`to`、`protocol`
- `ports`：逐信号 `{name, dir, width_expr, clock, reset}`（width_expr 可为参数表达式如 `CNT_W`）
- `parameters`：`{name, default, range}`
- 握手/延迟/背压/异常语义（`handshake`, `backpressure`, `exceptions`）
- `frozen` + `frozen_at`（git hash）+ `approved_by`：冻结时记录内容摘要与批准人

## 与 project.yaml 的关系
`project.yaml` 的 `interfaces` 保留为**轻量索引**（name/from/to/frozen），
完整信号级契约在 `contracts/interfaces.yaml`。第二批 check_gate.py 以本目录为准做信号级比对。
