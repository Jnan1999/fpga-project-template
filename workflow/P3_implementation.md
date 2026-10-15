# P3 并行实现（Parallel Implementation）

> 阶段目标：接口已冻结，三条线**互不依赖、可并行推进**（可分派给不同 agent 同时工作）：
> A 线 RTL 三件套 ∥ B 线 Golden Model ∥ C 线验证环境。
> 这是全流程最大的时间压缩点。

## 1. 入口条件
- 接口冻结 gate 通过：`project.yaml` 中 `P2.status: done`，且 `interfaces` 全部 `frozen: true`

## 2. Agent 输入（按线）
| 线 | 必读输入 |
| --- | --- |
| A RTL 线 | 模块 LLD（`docs/02_module_design/<mod>/`）、`project.yaml` interfaces 表、示例 `hw/rtl/pulse_gen/` 三件套、`CLAUDE.md` 铁律 |
| B Golden Model 线 | 模块 LLD（重点数据通路节：Qm.n/舍入/饱和/延迟）、`host/README.md` 三路比对流程 |
| C 验证环境线 | `03-02_测试矩阵.md`、`03-01_Vplan`、`hw/verif/README.md`、接口协议（ICD） |

## 3. Agent 任务
**A 线 — RTL 实现**（角色 agent：`.claude/agents/rtl-engineer.md`）
- 按 CLAUDE.md"新增模块 checklist"逐模块生成三件套（core 纯功能 / dft_wrap 内部例化 core / wrap 统一入口）
- 接口逐字匹配 interfaces 冻结表；`rtl.f` 登记；`project.yaml` 模块 status 改 coding

**B 线 — Golden Model**（角色 agent：`.claude/agents/golden-modeler.md`）
- `host/golden_model/<mod>.py`：**定点实现**，逐 bit 对齐 LLD 数据通路节（禁止 float 近似代替定点语义）
- 独立从 LLD/算法推导，**禁止反向翻译 RTL 代码**
- 带 `--selftest` 最小自验；I/O 文件格式与 C 线 TB 约定一致（hex 一行一样点）

**C 线 — 验证环境**
- 实例化 `hw/verif/` 骨架：interface / driver / monitor / scoreboard / `tb_<mod>.sv`
- 用例与测试矩阵一一对应（用例名 = 矩阵 ID）；scoreboard 自动比对 Golden Model 输出，**禁止人工看波形判对错**
- `verif.f` 登记；断言 bind 到 DUT，不改设计代码

## 4. 验证命令（三线各自完工必跑，向用户出示结果）
| 线 | 命令 | 机读判据 |
| --- | --- | --- |
| A | `python scripts/check_ports.py hw/rtl/<mod>/rtl/<mod>.v hw/rtl/<mod>/dft_wrap/<mod>_dft.v` | 退出码 0（每模块） |
| A | `vivado -mode batch -source hw/scripts/create_impl_project.tcl` 后 elaboration | 无 error；`report_methodology` 无 critical warning |
| B | `python host/golden_model/<mod>.py --selftest` | 输出 PASS |
| C | `vivado -mode batch -source hw/verif/scripts/run_sim.tcl -tclargs tb_<mod>`（冒烟用例） | 编译/elaborate 通过，冒烟用例可运行 |

## 5. 出口标准（G3 pre-commitment review）
- 三线验证命令全绿；用户审核代码 diff 通过（借审核理解计算流程）
- 用户确认后更新 `project.yaml`：`P3.status: done`、`P4.status: in_progress`、`current_phase: P4`、相关模块 status 改 verified 前置态

## 6. 常见失败模式
| 失败模式 | 规避 |
| --- | --- |
| core 里出现 dbg_ 端口 / 调试代码 / `$display` | core 纯功能；观测注入全部在 dft_wrap，走 dbg_ 前缀 |
| dft_wrap 复制 core 逻辑而非内部例化 | 功能只能存在一份；dft 必须 `u_core` 例化，否则功能漂移 |
| RTL 接口与冻结表漂移（改名/改位宽） | 接口逐字复制 interfaces 表；check_ports 与 elaboration 双闸 |
| Golden Model 用 float 近似 | 必须定点逐 bit 对齐 LLD；否则比对基准失效 |
| TB 靠人看波形判对错 | scoreboard/断言自动比对；失败凭"用例名+种子"可复现 |
| top 直接例化 core/dft | top 只例化 `*_wrap` |
