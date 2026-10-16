---
description: 门禁推进——核对当前阶段出口标准，向用户申请 gate 评审（人触发；第二批 check_gate.py 落地后改为调用它）
argument-hint: "[P0|P1|...|P6]（缺省读 project.yaml 的 current_phase）"
---

按以下步骤执行当前阶段的 gate 申请流程：

1. 读 `project.yaml`：确定目标阶段（若用户给了参数 `$ARGUMENTS` 则用参数，否则用 `current_phase`）、该阶段的 gate 名称与出口标准。
2. 打开对应 `workflow/P*.md` playbook 的「验证命令」与「出口标准(Gate)」两节，以及 `workflow/README.md` 的 gate 判据表。
3. **逐条核对出口判据**，给出机读证据：
   - 已有机读检查（如 `python scripts/check_ports.py`）逐个重跑，出示退出码与关键输出；
   - 文档类判据（清单全勾选、RTM 行非空等）逐条引用文件与行号；
   - 日志类判据引用 `logs/` 对应文件末尾 `=== SUMMARY ===` 段。
4. 汇总为一张表：判据 | 证据 | PASS/FAIL。**有任何 FAIL 或未验证项 → 明确列出缺口并停止，不得申请推进。**
5. 全部 PASS 时，向用户出示汇总表，**申请** gate 确认。未经用户明确确认：
   - 禁止更新 `project.yaml` 的阶段状态 / `current_phase`；
   - 禁止推进到下一阶段工作。
6. 用户确认后，才可更新 `project.yaml`（二区），并在汇报中说明改动。

注意：批准针对本次出示的具体证据（git hash + 工具版本 + 运行批次）；上游产物变更后旧证据按失效传播矩阵作废（ADR 0012），需重新核对。
