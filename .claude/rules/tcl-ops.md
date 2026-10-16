---
paths: ["hw/scripts/**", "hw/verif/scripts/**", "**/*.tcl"]
---

# 工具操作层规范（编辑 tcl / 工具脚本时适用）

> 本目录是**工具操作层**。`hw/scripts/ops.yaml` 是**参考清单（非强制白名单，ADR 0019）**：agent 看示例自行决定调用时机/参数，可改造或新写脚本。唯一硬要求是机读契约。

## 机读契约（唯一硬要求）
任何工具脚本，日志末尾必须输出：
```
=== SUMMARY ===
RESULT: PASS | FAIL
<KEY>: <value>   # 关键数值（用例计数、错误计数、种子等）
```
- agent 判断成败只认这一段；**缺失则按 fail-closed 视为结果未知**，不得"没报错就当成功"
- 退出码：0=PASS，非 0=FAIL；无法确定结果时返回非 0（ADR 0013）
- 在 ops.yaml 同步该脚本的 `result_glob`（结果日志定位模式），让 agent/check_gate 能确定性找到结果，不靠猜

## 脚本写法约定（新增/修改时）
- **kind 意识**：执行类（建工程/综合，改变世界）vs 检查类（只读判定）——gate 只接受检查类输出作证据（ADR 0010）
- **长任务**：综合/实现/大回归用后台运行 + 轮询日志，ops.yaml 标 `long_running: true`
- **可移植**：脚本是项目完成后的可移植资产——参数（器件/版本）集中在文件头，换项目改参数即可重建

## 源文件外置工程（铁律 1）
- `.xpr` 由脚本重建，不入库；**禁止** `import_files` / 勾选 *Copy sources into project*
- 源文件只通过 filelist 引用：`read_filelist` 读取 `rtl.f` / `verif.f`

## 不要做的事
- **不要包装成 MCP server**：Vivado 是批处理模型（跑→写文件→读报告），Bash + SUMMARY 是正确抽象；MCP 是常驻上下文污染且模型不匹配（ADR 0019，延续 ADR 0007 对 amd-doc-search 的同一理由）

## filelist 解析契约（ADR 0013，已踩过的坑）
- 读取每行后**先剥离 `#` 行尾注释再 trim**（否则注释被拼进路径导致 add_files 失败——评审 #5 实锤 bug）
- 空行跳过；路径相对仓库根；`-f` 嵌套仅用于 verif.f 引用 rtl.f

## 版本与证据（ADR 0012）
- 脚本开头用 `version` 等命令采集工具版本，写入运行产物（证据绑定：git hash + 工具版本 + run ID）
- 运行产物按 `板卡 / debug|release / run_id` 隔离，不得覆盖旧报告
