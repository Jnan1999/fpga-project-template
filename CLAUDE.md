# CLAUDE.md —— Agent 工作入口

> 你是本 FPGA 项目的开发 Agent。开始任何工作前：**先读 `project.yaml`** 获取项目元信息与当前阶段，
> **再读 `workflow/` 中对应阶段的 playbook** 并按其执行。本文件只放全局规范与速查。

## 项目元信息
见 `project.yaml`（机器可读单一事实来源）：
- **一区 `project:`**：项目名 / FPGA 型号 / 工具版本 / 开发板 —— 用户初始化时填写，**Agent 只读，禁止修改**
- **二区**：当前阶段 `current_phase`、模块注册表 `modules`、接口冻结表 `interfaces`、寄存器映射指针

## 四条铁律（不可违反）
1. **源文件外置工程**：所有 RTL/约束/BD 保持在工程外；`.xpr` 由脚本重建，不入库、不复制源文件进工程
2. **设计与验证分离**：可综合代码只放 `hw/rtl/`；TB / SV class / interface / 断言 bind 只放 `hw/verif/`
3. **可测性三件套（默认模式，非无条件铁律）**：需观测/故障注入的业务模块 = `<mod>.v`（core）+ `<mod>_dft.v`（内部例化 core）+ `<mod>_wrap.v`（统一入口，`ENABLE_DFT` 切换）。top 只例化 `*_wrap`。
   **例外**：`common/` 的 CDC/同步器、简单组合逻辑、官方 IP/原语（布局与 CDC 识别敏感）**不强制**三件套；模块在 `project.yaml` 注册表用 `dft_mode` 声明模式（`three_piece`/`ip`/`primitive`/`none`）及理由（ADR 0014）。
4. **端口一致性**：采用三件套的模块，core 与 dft 的功能端口逐字一致（名/方向/位宽），`dbg_` 前缀调试端口豁免；改动端口后必须跑 `scripts/check_ports.py`
5. **工具操作走工具层**：禁止绕过 `hw/scripts/ops.yaml` 声明的命名操作直接拼 vivado/工具命令——否则机读 SUMMARY、证据绑定（git hash+工具版本+run ID）、版本采集全被旁路（ADR 0016/0017）

## Agent 行为总纲
1. `project.yaml` 一区只读；二区状态更新须对应阶段 gate 经用户确认后才改
2. **P0 阶段禁止假设需求**：必须按 `workflow/P0_requirements.md` 的主动提问协议，生成需求确认清单并多轮对话确认，全部确认后才允许写 SRS
3. 任何阶段完工前：必须跑该阶段 playbook 的"验证命令"，并向用户出示结果（PASS/FAIL + 关键数值）
4. 接口冻结表 `interfaces` 中 `frozen: true` 的接口禁止改动；新增/修改接口必须走 P1/P2 流程并登记
5. 拿不准的设计决策：列出选项 + 推荐理由，问用户，不自行裁决
6. **必读清单是下界不是上界**：playbook §2 列的是最低保障；发现清单外相关资料（datasheet 其他章节、Xilinx 手册、相邻模块代码）必须主动阅读，并在汇报中注明额外读了什么（ADR 0001）
7. **Xilinx 手册引用规范**：引用官方手册内容必须注明 UG 编号 + 章节 + 文档版本（如 "UG953 v2021.1"）；版本须对应 `project.yaml` 的 Vivado 版本（2021.1）；禁止凭记忆编造端口/参数/时序数值（ADR 0002）

## 关键路径速查
| 内容 | 路径 |
| --- | --- |
| RTL 模块三件套 | `hw/rtl/<mod>/{rtl/<mod>.v, dft_wrap/<mod>_dft.v, <mod>_wrap.v}` |
| 可综合源清单 | `hw/rtl/filelists/rtl.f`（实现/仿真工程共同唯一入口） |
| 验证文件清单 | `hw/verif/filelists/verif.f`（顶部 `-f` 引用 rtl.f） |
| 测试台（按模块） | `hw/verif/tb/<mod>/tb_<mod>.sv` |
| 模块设计文档 | `docs/02_module_design/<mod>/LLD_<mod>.md` |
| LLD 模板（完整/精简） | `docs/templates/` |
| 需求确认清单（P0 产物） | `docs/00_project/00-00_需求确认清单.md` |
| 寄存器映射 | `docs/01_architecture/01-03_寄存器映射规格.md` |
| 接口控制文档 | `docs/01_architecture/01-02_接口控制文档_ICD.md` |
| 测试矩阵 | `docs/03_verification/03-02_测试矩阵.md` |
| 需求跟踪矩阵 | `docs/00_project/00-03_需求跟踪矩阵_RTM.md` |
| 参考资料（datasheet 等） | `docs/refs/` |
| Xilinx 手册地图 | `docs/refs/xilinx/README.md` |
| Golden Model | `host/golden_model/` |
| 构建/仿真日志 | `logs/`（末尾 `=== SUMMARY ===` 段为机读摘要） |
| 示例模块（标准写法参考） | `hw/rtl/pulse_gen/` |
| 工具操作契约（ops） | `hw/scripts/ops.yaml`（命名操作清单：入口/kind/产出/SUMMARY/退出码） |
| 路径懒加载规范 | `.claude/rules/`（rtl-style / tb-style / tcl-ops，编辑对应路径时自动生效） |
| 人触发流程命令 | `.claude/commands/`（`/project:gate`、`/project:new-module`、`/project:module-check`） |

## 新增模块 checklist（按顺序执行）
1. 复制 `hw/rtl/pulse_gen/` → `hw/rtl/<mod>/`，改文件名与模块名（core/dft/wrap 三件套）
2. `hw/rtl/filelists/rtl.f` 追加三行
3. 建 `hw/verif/tb/<mod>/` 并写 TB；`hw/verif/filelists/verif.f` 追加
4. 验证：`python scripts/check_ports.py hw/rtl/<mod>/rtl/<mod>.v hw/rtl/<mod>/dft_wrap/<mod>_dft.v` → 退出码 0
5. 写 LLD：先填 `docs/templates/_模板_LLD_agent精简版.md` → 用户审核 → 补完整版
6. 在 `project.yaml` 的 `modules:` 登记（status: design）

## 常用命令（仓库根目录执行）
| 目的 | 命令 |
| --- | --- |
| 申请门禁推进 | `/project:gate` |
| 新增模块 | `/project:new-module <mod>` |
| 端口一致性检查 | `/project:module-check <mod>`（底层为 `python scripts/check_ports.py`） |
| 建实现工程 | op `create_impl_project`：`vivado -mode batch -source hw/scripts/create_impl_project.tcl` |
| 跑模块仿真 | op `run_sim`：`vivado -mode batch -source hw/verif/scripts/run_sim.tcl -tclargs tb_<mod>` |

> 直接执行底层命令须遵守铁律 5（只调用 `ops.yaml` 已登记的 op，不自行拼装新命令组合）。

## 阶段操作规程（workflow/）
| 阶段 | playbook | 出口 Gate |
| --- | --- | --- |
| P0 需求捕获 | `workflow/P0_requirements.md` | G1：SRS+RTM 评审（需求确认清单全勾选） |
| P1 系统架构 | `workflow/P1_architecture.md` | G2：模块划分+ICD+寄存器映射冻结 |
| P2 模块设计 | `workflow/P2_module_design.md` | LLD 冻结 + 接口最终冻结（interfaces 全 frozen） |
| P3 并行实现 | `workflow/P3_implementation.md` | G3：check_ports + elaboration + methodology 干净 |
| P4 功能验证 | `workflow/P4_verification.md` | 覆盖率达标 + 全回归 PASS + RTM 回填 |
| P5 时序收敛 | `workflow/P5_timing.md` | post-route WNS≥0 + DRC 干净 + 资源达标 |
| P6 集成上板 | `workflow/P6_bringup.md` | G4：板级测试报告 + Release 包 |
