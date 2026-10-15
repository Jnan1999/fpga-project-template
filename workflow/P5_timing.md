# P5 时序收敛（Timing Closure / 最终签核）

> 阶段目标：最终时序签核——约束完整、基线化实现、迭代收敛，直至 post-route Setup/Hold/PulseWidth 全绿且资源达标。
> 方法依据：UG949（UltraFast 方法论）+ UG1292（时序收敛）。**不要指望实现阶段救烂 RTL**。
>
> ⚠️ **时序活动不止在 P5**（评审#4b）：时序是贯穿的，P5 只做**最终签核**——
> P1/P2 建立时钟/CDC/I-O 预算；P3 起每次综合即做早期时序检查（post-synth WNS）；
> P4 期间持续监控；**不要等功能验证全部结束才第一次发现架构无法满足时序**。

## 1. 入口条件
- `project.yaml` 中 `P4.status: done`（功能验证完成，RTL 功能冻结）

## 2. Agent 输入（必读）
> 以下清单为**最低要求**（下界非上界）。
| 输入 | 路径 |
| --- | --- |
| 时钟树/CDC 清单 | `docs/01_architecture/01-04_时钟与复位架构.md` |
| Xilinx 手册地图（UG949/UG1292/UG906） | `docs/refs/xilinx/README.md` |
| 约束策略模板 | `docs/04_implementation/04-01_时序约束策略.md` |
| 现有约束 | `hw/constraints/*.xdc` |
| 资源预算 | `docs/01_architecture/01-01_HLD.md` §9 |
| 收敛报告模板 | `docs/04_implementation/04-02_资源与时序收敛报告.md` |

## 3. Agent 任务
1. **约束先行**（从第一天就全约束，不是事后补）：
   - 主时钟 / 生成时钟（MMCM 派生）/ 输入输出延迟（源同步按 datasheet t_PD、t_SKEW）
   - CDC 约束：按 01-04 清单逐条 `set_clock_groups` / `set_false_path` / `set_max_delay -datapath_only`
   - `check_timing` 干净：无 unconstrained clocks / 无未约束输入输出
2. **基线化实现**：综合 → opt → place → route，每步存 DCP + 时序/methodology/利用率报告；建立 WNS 检查点（post-synth / post-place / post-route）
3. **失败路径分析与迭代**（每次迭代向用户出示：失败路径 Top N + 归因 + 方案）：
   - post-synth WNS 已经很差（< -0.5ns 量级）→ 回 P3/P4 改 RTL（加流水线/减逻辑级数），改后必须重跑 P4 smoke 回归
   - 局部长尾 → 约束修正 / 布局指导（pblock 慎用）/ 策略重跑
   - **RTL 任何功能改动 → 必须回归**，禁止只改不验
4. 填写 `04-01_时序约束策略.md` 与 `04-02_资源与时序收敛报告.md`（含 slack 趋势）

## 4. 验证命令
| 命令（Vivado Tcl，工程内） | 机读判据 |
| --- | --- |
| `check_timing` | 无 unconstrained 项（时钟/输入输出/生成时钟全约束） |
| `report_timing_summary`（post-route） | **Setup：WNS ≥ 0 且 TNS = 0；Hold：WHS ≥ 0 且 THS = 0；Pulse Width：WPWS ≥ 0 且 TPWS = 0**（三类齐全，与 04-02 报告模板一致，评审#4） |
| `report_methodology` / `report_drc` | 无 critical warning（或有用户书面豁免） |
| `report_utilization` | 各类资源 < HLD §9 预算 |
| `report_clock_interaction` | CDC 路径全部有约束覆盖 |
| CDC 结构检查（`report_cdc`，或 Vivado 版本的等价 DRC） | 无未同步/不安全 CDC 结构 |

> ⚠️ **约束豁免 ≠ CDC 安全**：`set_false_path` / `set_clock_groups` 让路径不再参与时序分析，
> 不等于该跨域路径安全。每条豁免必须：①写明理由进 04-01；②有对应的 CDC 结构（同步器/异步 FIFO/握手）佐证；
> ③逐条经用户评审。时序例外的作用范围必须最小化（禁用过宽的 `set_clock_groups -asynchronous` 一刀切）。

## 5. 出口标准
- 上表判据全绿；用户确认收敛方案与报告
- 用户确认后更新 `project.yaml`：`P5.status: done`、`P6.status: in_progress`、`current_phase: P6`、模块 status 改 timed

## 6. 常见失败模式
| 失败模式 | 规避 |
| --- | --- |
| 指望 place/route 救烂 RTL | post-synth WNS 差即回 RTL 加流水；实现只能锦上添花 |
| CDC 路径无约束导致"假通过" | 对照 01-04 清单逐条加约束；`report_clock_interaction` 核查 |
| 过度约束（乱设 false_path/multicycle） | 每条例外约束写明理由进 04-01；评审逐条过 |
| 改 RTL 后不回归 | 功能改动必跑 P4 smoke；时序迭代不动功能 |
| 约束与 ICD/datasheet 不符 | 输入输出延迟数值注明 datasheet 出处页码 |
