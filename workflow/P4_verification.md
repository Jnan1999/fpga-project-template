# P4 功能验证（Functional Verification）

> 阶段目标：分层回归全绿 + 覆盖率达标 + RTM 回填。本阶段 **Agent 自治度最高**：
> 回归 → 分析失败 → 直接修 bug，用户只审核修复方案。

## 1. 入口条件
- G3 通过：`project.yaml` 中 `P3.status: done`

## 2. Agent 输入（必读）
> 以下清单为**最低要求**（下界非上界）。
| 输入 | 路径 |
| --- | --- |
| 本阶段总规程 + 角色定义 | 本文件 + `.claude/agents/verification-lead.md` |
| 用例清单 | `docs/03_verification/03-02_测试矩阵.md` |
| 验证点与覆盖率目标 | `docs/03_verification/03-01_Vplan.md` |
| 比对基准 | `host/golden_model/` |
| 日志（失败分析起点） | `logs/sim_<mod>_*.log` 末尾 `=== SUMMARY ===` 段 |
| 缺陷记录 | `docs/05_bringup/05-03_调试记录.md` |

## 3. Agent 任务
1. **分层回归**：smoke（提交必跑）→ regression（每次改动）→ full（随机种子集+压力+长稳，版本节点）；前一层未全过不进下一层
2. **失败分析闭环**（每个失败用例）：
   - 读 `logs/` SUMMARY → 凭"用例名+种子"复现 → 比对 Golden Model 期望 vs RTL 实际 → 归因：RTL bug / TB bug / GM bug / 规格歧义
   - **先怀疑 RTL，除非证明 TB/GM 错**；规格歧义不得自行裁决——列证据问用户
   - 修复后重跑该用例 + smoke 集，向用户出示修复 diff 与前后对比
   - 缺陷记录写入 `05-03_调试记录.md`（现象/最小复现/根因/修复/回归结果）
3. **覆盖率收敛**：行 ≥95% / 分支 ≥90% / 功能 100%；未覆盖项逐条分类——补用例，或证明冗余（冗余豁免需用户书面批准）；禁止凑覆盖率的无效应激
4. **回填**：测试矩阵"状态"列、RTM 验证状态列、`03-03_覆盖率与回归报告.md`

## 4. 验证命令
| 命令 | 机读判据 |
| --- | --- |
| `vivado -mode batch -source hw/verif/scripts/run_sim.tcl -tclargs tb_<mod>` | SUMMARY 段 RESULT: PASS |
| 全模块回归（逐模块跑，第二批提供一键回归） | 全部 PASS |
| 覆盖率报告（xsim `-coverage`，输出 `hw/verif/report/`） | 行 ≥95%、分支 ≥90%、功能 100% |

## 5. 出口标准
- 全回归 PASS + 覆盖率达标（或冗余豁免经用户批准）+ RTM 回填完成
- 用户确认后更新 `project.yaml`：`P4.status: done`、`P5.status: in_progress`、`current_phase: P5`、模块 status 改 verified

## 6. 常见失败模式
| 失败模式 | 规避 |
| --- | --- |
| 改 TB/GM 迁就 RTL 错误 | 先怀疑 RTL；GM 任何修改必须用户确认 |
| 随机用例失败不可复现 | 每用例固定种子并记录；失败保留种子+激励 |
| 只跑 smoke 就宣称完成 | 出口标准要求 full 集全过 |
| 凑覆盖率（无效应激刷行覆盖） | 未覆盖项逐条分析；豁免需用户批准 |
| 缺陷只修不记录 | 全部进 05-03，含最小复现——上板阶段会回来查 |
