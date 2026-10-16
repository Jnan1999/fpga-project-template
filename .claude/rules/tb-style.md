---
paths: ["hw/verif/**"]
---

# 验证代码规范（编辑 hw/verif/ 下文件时适用）

## 布局（铁律 2：设计与验证物理分离）
- 可综合代码禁止出现在本目录；TB / SV class / interface / 断言 bind 只放这里
- TB 按模块分目录：`hw/verif/tb/<mod>/tb_<mod>.sv`
- 新增/删除验证文件必须同步登记 `hw/verif/filelists/verif.f`（注释单独成行，禁止行尾注释）

## 比对纪律（ADR 0003/0010 信任模型）
- **禁止人工看波形判对错**——全部走 scoreboard / 断言自动比对
- 期望来源 = Golden Model 输出（`$readmemh` hex，一行一样点，位宽对齐）或 LLD 推导；**禁止从 RTL 行为反推期望**（同错同对）
- 用例必须带种子记录，失败可凭"用例名+种子"复现
- 禁止无效应激凑覆盖率；未覆盖项逐条分类（补用例，或证明冗余申请用户豁免）

## Golden Model 关系（写 ref_model 或调用 GM 时）
- GM 从 LLD/算法原理独立实现，禁止反向翻译 RTL；发现 GM 与 RTL 不一致 → 报告用户走 P4 归因，不得改 GM 迁就 RTL
- I/O 格式与 TB 约定一致（hex 一行一样点）；每个 GM 带 `--selftest`

## 回归纪律
- 回归顺序：smoke → regression → full；前一层未全过不进下一层
- 日志末尾必须产出 `=== SUMMARY ===` 机读段（PASS/FAIL + 关键数值），run_sim.tcl 负责生成
