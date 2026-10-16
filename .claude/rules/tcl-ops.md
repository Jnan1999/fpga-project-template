---
paths: ["hw/scripts/**", "hw/verif/scripts/**", "**/*.tcl"]
---

# 工具操作层规范（编辑 tcl / 工具脚本时适用）

> 本目录是**工具操作层**（ADR 0016）：上层（playbook / agent / command）通过 `hw/scripts/ops.yaml` 声明的**命名操作**调用，不直接拼 vivado 命令（铁律 5）。

## op 契约（新增/修改脚本时必须同步维护 ops.yaml）
每个 op 五要素：
1. **入口脚本** + 参数（`-tclargs`）
2. **kind**：`actuation`（执行类：改变世界，如建工程/综合）| `verification`（检查类：只读判定，如端口检查；gate 只接受 verification 类输出作证据）
3. **产出物**：工程目录 / 报告 / 日志路径
4. **机读 SUMMARY**：日志末尾 `=== SUMMARY ===` 段（PASS/FAIL + 关键数值），缺失视为失败
5. **退出码**：0=PASS，非 0=FAIL；**fail-closed**——无法确定结果时返回非 0，不得默认成功（ADR 0013）

## 源文件外置工程（铁律 1）
- `.xpr` 由脚本重建，不入库；**禁止** `import_files` / 勾选 *Copy sources into project*
- 源文件只通过 filelist 引用：`read_filelist` 读取 `rtl.f` / `verif.f`

## filelist 解析契约（ADR 0013，已踩过的坑）
- 读取每行后**先剥离 `#` 行尾注释再 trim**（否则注释被拼进路径导致 add_files 失败——评审 #5 实锤 bug）
- 空行跳过；路径相对仓库根；`-f` 嵌套仅用于 verif.f 引用 rtl.f

## 版本与证据（ADR 0012）
- 脚本开头用 `version` 等命令采集工具版本，写入运行产物（证据绑定：git hash + 工具版本 + run ID）
- 运行产物按 `板卡 / debug|release / run_id` 隔离，不得覆盖旧报告
