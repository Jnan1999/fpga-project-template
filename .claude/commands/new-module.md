---
description: 新增模块——按当前阶段限定产出（P1/P2 登记+设计草稿，P3 才生成实现），遵循先设计后实现
argument-hint: "<模块名>（小写蛇形，如 adc_frontend）"
---

为模块 `$ARGUMENTS` 执行新增流程。**先读 `project.yaml` 的 `current_phase`，按阶段限定产出**（先设计、后实现，ADR 0020）——不要一上来就生成 RTL。

## 第 0 步（所有阶段先做）：定 dft_mode + 登记
- 判断模块性质，确定 `dft_mode`（three_piece / ip / primitive / none，ADR 0014）**并给出理由**；
- 在 `project.yaml` 的 `modules:` 登记 `$ARGUMENTS`（status: design）。

## 按阶段分支

**P1 / P2（设计阶段）——只产出"设计"，不写实现：**
1. 写 LLD 草稿：用 `docs/templates/_模板_LLD_agent精简版.md` 填 `docs/02_module_design/$ARGUMENTS/LLD_$ARGUMENTS.md`，重点是接口（端口/协议/时序）与数据通路（Qm.n/延迟）；
2. 接口若属模块间接口，登记 `project.yaml` interfaces 表（走 P1/P2 冻结流程）；
3. **到此为止**——实现代码（RTL/TB）留待 P3。向用户提交 LLD 草稿审核。

**P3（实现阶段，且该模块 LLD 已评审通过、接口已冻结）——才生成实现：**
1. 复制三件套：`hw/rtl/pulse_gen/` → `hw/rtl/$ARGUMENTS/`（仅当 `dft_mode == three_piece`），重命名并逐处替换；遵守 `.claude/rules/rtl-style.md`；
2. 登记 `hw/rtl/filelists/rtl.f`（注释单独成行，禁行尾注释）；
3. 建 TB `hw/verif/tb/$ARGUMENTS/tb_$ARGUMENTS.sv`，登记 `verif.f`；遵守 `.claude/rules/tb-style.md`；
4. 跑 `/project:module-check $ARGUMENTS`（只报告差异；不一致时按接口契约定位该修哪侧，报告用户）；
5. `project.yaml` 状态推进到 `coding`。

**若只复制了空骨架而未实现逻辑**：明确标注它是 scaffold（脚手架），**不得计为"已实现"**。

## 反模式（禁止）
- P1/P2 阶段就生成 RTL/TB 实现；
- 实现完三件套后才回头补 dft_mode 或 LLD（顺序应相反）；
- 端口不一致时为通过检查而改合法设计去迎合简化解析器。
