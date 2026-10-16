---
description: 门禁推进——用 check_gate.py 核对阶段出口契约，向用户申请 gate 评审（人触发）
argument-hint: "[P0|P1|...|P6 或 G1|G2|G3|G4]（缺省读 project.yaml 的 current_phase）"
---

按以下步骤执行 gate 申请流程：

1. 读 `project.yaml`：确定目标阶段（若用户给了参数 `$ARGUMENTS` 则用参数，否则用 `current_phase`）。
2. 跑机读契约检查（验收标准见 `workflow/gates.yaml`，那是验收口径，agent 不得自改）：
   - `uv run python scripts/check_gate.py exit <目标阶段>`
   - 若结果中有"慢检查未执行"项且本阶段涉及 Vivado 证据（G3/P4/P5），重跑加 `--slow`（会真正调用 Vivado，按长任务对待）。
3. 解读结果（三值语义，fail-closed）：
   - **FAIL** → 明确列出失败项与缺口，停止，不得申请推进；
   - **UNKNOWN** → 逐条处理：证据缺失就补跑对应 op（见 `hw/scripts/ops.yaml`）；证据 git hash 不绑定就重跑产生新证据；`manual` 项整理成待用户确认的问题清单；
   - **PASS**（机器可查项全过）→ 进入第 4 步。
4. 汇总为一张表：判据 | 证据（logs 具体文件名 + SUMMARY 字段 + git hash）| 结果，连同 manual 项清单一并向用户出示，**申请** gate 确认。未经用户明确确认：
   - 禁止更新 `project.yaml` 的阶段状态 / `current_phase`；
   - 禁止推进到下一阶段工作。
5. 用户确认后，才可更新 `project.yaml`（二区：该阶段 `status: done`，下一阶段 `in_progress`，`current_phase` 前进），并在汇报中说明改动。

注意：
- check_gate 的 PASS 只证明"契约项被满足"，不证明契约本身正确；gate 的盖章权永远在用户（workflow/README 信任模型）。
- 批准针对本次出示的具体证据（git hash + 工具版本 + 运行批次）；上游产物变更后旧证据按失效传播矩阵作废（ADR 0012），需重新核对。
- 入口核对可用 `uv run python scripts/check_gate.py entry <阶段>`；总览用 `status`。
