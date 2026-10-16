# ADR 0017：op 契约五要素与 commands 边界

- 日期：2026-10-16
- 状态：已确认

## 背景
工具操作层要支持"换工具/换 Vivado 版本也能直接用"，关键是上层引用的不是脚本文件，而是**命名操作（op）**。同时用户确认的 Claude Code 化改造中，gate 推进、新模块创建等固定流程落在 `.claude/commands/`。

## 决策
1. **`hw/scripts/ops.yaml`** 为 op 契约清单。每个 op 五要素：
   - `entry`：入口命令（当前 vendor 实现）+ 参数
   - `kind`：`actuation`（执行类：改变世界）| `verification`（检查类：只读判定）
   - `artifacts`：产出物路径
   - `summary`：机读 `=== SUMMARY ===` 段约定
   - `exit_code`：0=PASS / 非 0=FAIL，**fail-closed**（ADR 0013）
2. **gate 只接受 `kind: verification` 的 op 输出作证据**——防止"执行脚本顺便输出 PASS"自证（ADR 0010 信任模型）
3. op 契约与 vendor/版本解耦：entry 是当前实现，换工具只改 entry。**不预设 adapters 目录**（YAGNI，当前单 vendor 单版本；第二版本出现时再拆）
4. 首批 commands 边界（人触发、流程固定、不经 skill 自动调用）：
   - `/project:gate` —— 门禁申请（第二批改为调用 check_gate.py）
   - `/project:new-module <mod>` —— 六步 checklist
   - `/project:module-check <mod>` —— check_ports 包装
5. 预登记后续批次的 op：check_gate/new_module（二批）、build_bitstream/program_device/read_timing（四批）

## 理由
- 五要素是 SUMMARY 机读化（logs/README 已有约定）+ 信任模型（actuation/verification 分类）+ 证据绑定（ADR 0012）的最小闭集
- commands 的三个命令覆盖当前全部"人发起、流程固定"场景；其余交互保持自然语言对话，不过度命令化
- module-check 独立成命令而非并入 new-module：P3 日常端口改动后单独高频使用

## 后果
- 新增 `hw/scripts/ops.yaml`（ops_version 0.1.0，三个 op：create_impl_project / run_sim / check_ports）
- 新增 `.claude/commands/` 三个命令文件
- playbook 后续逐步把"执行命令"表述改为"调用 op 名"（本批先改 CLAUDE.md 常用命令表）
