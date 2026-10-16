# ADR 0009：门禁契约 gates.yaml + check_gate.py（三模式、三值语义、证据绑定）

- 日期：2026-10-16
- 状态：已确认（第二批落地）

## 背景
workflow/README 的 gate 判据表此前只有文字描述，"Gate 未通过禁止推进"靠 agent 自觉。
需要一个机读契约把每条判据变成可执行检查，同时不越过两条红线：
**验收标准 agent 不得自改**（ADR 0020）、**gate 盖章权永远在用户**（ADR 0003/0010 信任模型）。

## 决策
1. **契约与执行分离**：`workflow/gates.yaml` 是验收标准（与验证计划同级，改动须经用户评审）；
   `scripts/check_gate.py` 只是它的执行器，不内嵌任何判据。
2. **三模式**：`status`（全 gate 总览）/ `entry <P*>`（入口前置：上一阶段 done）/ `exit <P*|G*>`（出口契约）。
3. **三值语义（fail-closed）**：PASS / FAIL / **UNKNOWN**。UNKNOWN 覆盖：证据缺失、证据歧义
   （多份日志无法定位 run）、git hash 不绑定、慢检查未加 `--slow` 执行、仅剩 `manual` 人工项。
   UNKNOWN 不放行也不算失败——它显式表达"机器只能查到这里"。退出码 0/1/2。
4. **证据绑定（ADR 0012 落地）**：`evidence` 类检查取 glob 最新日志 → 解析末尾 `=== SUMMARY ===`
   → `GIT_HASH` 字段必须等于当前 HEAD，否则 UNKNOWN（防过期/并行串用）。关键数值用
   独立 `KEY: value` 行（支持 `{min:}/{max:}` 阈值），不允许自由文本指标。
5. **慢检查挂 `--slow`**：带 `run:` 字段的 evidence 检查（如 check_elab 调 Vivado）默认只核对
   既有日志；加 `--slow` 才真正重跑工具。同一次调用内相同 run 命令只执行一次。
6. **manual 类恒 UNKNOWN**：凡含人工项的 gate 机器永远到不了 PASS——这是刻意的：
   check_gate 的 PASS 只证明"契约项被满足"，不证明契约正确、不代替人工评审。
7. **check_gate 不写 project.yaml**：阶段状态推进必须经用户确认后由 agent 显式更新（/project:gate 流程）。

## 已验证（2026-10-16 本机 Vivado 2021.1）
- `check_gate.py exit G3 --slow` 全链路绿：check_ports（three_piece 一致）→ check_elab.tcl
  （synth_design -rtl + report_methodology，SUMMARY 落 logs/elab_<run_id>.log）→ evidence
  核对 GIT_HASH==HEAD、ERRORS=0、METHODOLOGY_CRITICAL=0 → 退出码 0。
- **环境抖动**：Vivado 间歇报 couldn't read 自身安装脚本（D:\XilinxTools\...\rt\*.tcl，
  每次不同文件，重跑即过）——本机杀毒/索引软件扫描干扰的典型症状，非模板问题；
  建议用户把 `D:\XilinxTools` 加入 Defender 排除目录。
- **已知边界**：GIT_HASH 绑定 HEAD 提交，不能识别未提交的脏工作区改动（后续可加
  `git status --porcelain` 检查，列入后续批次评估）。

## 后果
- 新增 `workflow/gates.yaml`、`scripts/check_gate.py`、`hw/scripts/check_elab.tcl`；
  `/project:gate` 命令改为调用 check_gate.py；ops.yaml 0.4.0 登记 check_elab/check_gate
- 模板补齐 `hw/rtl/top/top.v`（pulse_gen_wrap 例化示例），`rtl.f` 中尚未附源的 common/
  条目改为注释（取消注释前必须先落盘文件，否则 fail-closed 报错）——模板开箱 elaboration 即绿
- logs/README：SUMMARY 段补必带身份字段（RUN_ID/GIT_HASH/TOOL_VERSION）与结构化数值行约定
