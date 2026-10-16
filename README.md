# FPGA Project Template

> 一套对标头部公司规范的 FPGA 项目目录骨架与工程化约定，适用于 Xilinx Zynq-7000 / UltraScale+ 等 Vivado 项目，单人或小团队均可直接落地。
> 设计理念：**文档先行、设计与验证物理分离、双工程共享同一份 RTL、可测性（DFT）内建、一切可脚本化重建**。

## 0. Agent 协作模式

本模板内置 **Agent 驱动开发框架**：Agent 负责执行（写文档/代码/TB/回归/修 bug），人在各阶段 gate 审核确认。

| 组件 | 作用 |
| --- | --- |
| `CLAUDE.md` | Agent 入口：四条铁律、路径速查、行为总纲 |
| `project.yaml` | 机器可读单一事实来源：项目信息（一区，用户填）+ 阶段状态/模块注册表/接口冻结表（二区，Agent 维护） |
| `workflow/` | 七阶段操作规程（P0 需求 → P1 架构 → P2 模块设计[接口冻结] → P3 并行实现[RTL∥GoldenModel∥验证环境] → P4 功能验证 → P5 时序收敛 → P6 集成上板） |
| `.claude/agents/` | 角色化 agent：rtl-engineer / golden-modeler / verification-lead |
| `.claude/rules/` | 路径懒加载编码规范（rtl/tb/tcl），编辑对应文件时自动生效 |
| `.claude/commands/` | 人触发流程命令：`/project:gate`、`/project:new-module`、`/project:module-check` |
| `hw/scripts/ops.yaml` | 工具操作参考清单（非强制）：常用操作的示例入口 + 结果判读 + 机读契约 |
| `docs/refs/` | 参考资料（datasheet/BOM），P0/P1 的 Agent 必读输入 |

每个 gate 经用户确认后更新 `project.yaml` 阶段状态。初始化新项目时替换 `project.yaml` 的 `<...>` 占位符并填写一区。

## 1. 核心约定（四条铁律）

1. **源文件外置工程**：所有 RTL/约束/BD 保持在工程外部，工程（`.xpr`）由脚本重建，不入库、不勾选 *Copy sources into project*。
2. **设计与验证分离**：可综合代码在 `hw/rtl/`，不可综合验证代码（TB/SV/断言）在 `hw/verif/`，通过 filelist 共享同一份 RTL。
3. **每个模块三件套**（默认模式，例外用 `dft_mode` 声明）：`<mod>.v`（功能核心）+ `<mod>_dft.v`（可测性包装，内部例化核心）+ `<mod>_wrap.v`（顶层统一入口，`ENABLE_DFT` 参数切换发布/调试）。top 永远只例化 `*_wrap`。
4. **接口一致可执行**：core 与 dft 的功能端口必须一致，由 `scripts/check_ports.py` 在 CI 中强制校验，`dbg_` 前缀调试端口豁免。

> 工具操作（建工程/仿真/综合）不是铁律——`hw/scripts/ops.yaml` 是给 agent 的参考清单，agent 可自由改造脚本；唯一硬要求是脚本日志末尾输出 `=== SUMMARY ===` 机读段（ADR 0019）。

## 2. 快速开始

### 2.1 用模板创建新项目
```bash
# 方式一：GitHub 上点 "Use this template"
# 方式二：本地复制
cp -r fpga-project-template my_project && cd my_project
```

### 2.2 修改项目配置（四处）
| 位置 | 改什么 |
| --- | --- |
| `project.yaml` 一区 | 项目名、器件、开发板、工具版本（Agent 单一事实来源，先改这里） |
| `hw/scripts/create_impl_project.tcl` | `PART`（器件型号）、`PROJ_NAME` |
| `hw/verif/scripts/run_sim.tcl` | `PART`、默认 `TEST_TOP` |
| 本 README / `docs/00_project/` | 项目名、需求、器件信息 |

### 2.3 跑通示例模块 `pulse_gen`
模板自带一个完整可参考的示例模块（脉冲发生器），包含 core/dft/wrap 三件套与端口门禁：
```bash
# 端口一致性检查（CI 门禁）
uv run python scripts/check_ports.py \
  hw/rtl/pulse_gen/rtl/pulse_gen.v \
  hw/rtl/pulse_gen/dft_wrap/pulse_gen_dft.v

# 建实现工程
vivado -mode batch -source hw/scripts/create_impl_project.tcl

# 建仿真工程（指定测试顶层）
vivado -mode batch -source hw/verif/scripts/run_sim.tcl -tclargs tb_pulse_gen
```

### 2.4 新增一个模块
1. 复制 `hw/rtl/pulse_gen/` 为 `hw/rtl/<your_mod>/`，改三件套文件名与模块名；
2. 在 `hw/rtl/filelists/rtl.f` 追加三行；
3. 在 `hw/verif/tb/<your_mod>/` 写 TB，在 `hw/verif/filelists/verif.f` 追加；
4. 跑 `check_ports.py` 确认 core/dft 功能端口一致；
5. 复制 `docs/templates/` 下的 LLD 模板写模块设计文档（Agent 先填精简版，审核后补完整版）。

## 3. 目录结构

```
fpga-project-template/
├── CLAUDE.md            # Agent 入口：铁律、路径速查、行为总纲
├── project.yaml         # 机器可读单一事实来源（项目信息/阶段/模块/接口冻结表）
├── workflow/            # 七阶段 Agent 操作规程（P0~P6 playbook）
├── .claude/             # Agent 配置：agents/ 角色、rules/ 路径懒加载规范、commands/ 流程命令、权限示例
├── docs/                # 所有设计文档，按开发阶段编号（唯一事实来源）
│   ├── refs/            # 参考资料（datasheet/BOM，P0/P1 的 Agent 必读输入）
│   ├── templates/       # 文档模板（LLD 完整版 + Agent 精简版）
│   ├── 00_project/      # 需求确认清单、立项书、需求规格 SRS、需求跟踪矩阵 RTM
│   ├── 01_architecture/ # 系统架构 HLD、接口控制 ICD、寄存器映射、时钟复位、软件架构
│   ├── 02_module_design/# 每个模块一份《模块详细设计 LLD》（含模板与示例）
│   ├── 03_verification/ # 验证计划、测试矩阵、覆盖率/回归报告、验证报告
│   ├── 04_implementation/ # 时序约束策略、资源与时序收敛报告
│   ├── 05_bringup/      # 板级 Bring-up 计划、硬件测试方案、调试记录、测试报告
│   ├── 06_review/       # 各阶段评审记录、评审 Checklist
│   └── 07_release/      # Release Notes、项目复盘
├── hw/                  # PL 侧（Vivado）
│   ├── rtl/             # 【可综合】设计源，只读可信源
│   │   ├── common/      # 通用组件（CDC、复位同步、异步 FIFO）
│   │   ├── pulse_gen/   # 示例模块（rtl/ + dft_wrap/ + *_wrap.v 三件套）
│   │   ├── top/         # 系统顶层
│   │   └── filelists/rtl.f  # 可综合源清单（impl/sim 共同引用）
│   ├── verif/           # 【不可综合】验证代码
│   │   ├── tb/          # 测试顶层与用例（按模块分目录）
│   │   ├── sv/          # interface / env / agent / sequence / coverage
│   │   ├── assertions/  # bind 断言（不改设计）
│   │   ├── stimulus/ ref_model/
│   │   ├── filelists/verif.f  # 验证清单（-f 引入 rtl.f）
│   │   └── scripts/run_sim.tcl
│   ├── impl_proj/       # 实现工程产物（脚本生成，git 忽略）
│   ├── sim_proj/        # 仿真工程产物（脚本生成，git 忽略）
│   ├── bd/              # Block Design 导出的 .tcl
│   ├── constraints/     # XDC 约束
│   ├── ip_repo/         # 自定义 IP 打包源
│   └── scripts/         # create_impl_project.tcl + ops.yaml（工具操作契约清单）
├── sw/                  # PS 侧（Vitis 裸机/FreeRTOS）
├── host/                # 上位机（Python：命令下发、数据解析、Golden Model）
├── scripts/             # 跨 hw/sw/host 的顶层脚本（含 check_ports.py）
├── ci/                  # 持续集成配置
├── third_party/         # 第三方 IP、库（记录版本，禁止手改）
├── releases/            # 发布产物（BOOT.BIN、bit、elf）
└── logs/                # 构建/回归日志
```

## 4. 双工程如何共享同一份 RTL

```
                ┌──────────────────────┐
                │  hw/rtl（可综合，只读）│
                └──────────┬───────────┘
                           │ rtl.f
          ┌────────────────┴────────────────┐
          │                                 │
 实现工程 impl_proj                 仿真工程 sim_proj
 rtl.f + 约束 + BD（无 verif）     rtl.f（sources_1）+ verif.f（sim_1）
 create_impl_project.tcl           run_sim.tcl（skip_includes 避免重复）
```

- 实现工程只加 `rtl.f`，绝不包含 `hw/verif`；
- 仿真工程设计源进 `sources_1`，验证文件进 `sim_1`，`run_sim.tcl` 用 `skip_includes=1` 跳过 `verif.f` 里的 `-f rtl.f`，设计源只出现一次；
- 换用其他工具链（Quartus/Diamond/Questa/VCS）时，只需保留 `hw/rtl` 源码与 filelist 重新建工程。

## 5. DFT 三件套如何工作

```
top → pulse_gen_wrap（永远例化它）
        ├─ ENABLE_DFT=1 → pulse_gen_dft（内部例化 pulse_gen + dbg_ 观测/注入总线）
        └─ ENABLE_DFT=0 → pulse_gen（纯核心，dbg 输出 tie off，DFT 整体不综合）
```
- 功能核心唯一，dft 内部例化 core，功能不可能漂移；
- 发布/调试只改一个参数，不改例化名、不改连接；
- `dbg_` 前缀端口是调试总线，不混入功能端口，`check_ports.py` 自动豁免。

## 6. 工具链与版本

| 工具 | 推荐版本 | 用途 |
| --- | --- | --- |
| Vivado | 2021.1+ | PL 综合/实现/仿真 |
| Vitis | 与 Vivado 同版本 | PS 软件开发 |
| Python | 3.8+ | 上位机、脚本、CI 门禁 |
| （可选）Verilator / Questa / VCS | — | 更快的仿真/覆盖率 |

## 7. 后续调整

本模板是起点而非终点，建议随项目演进逐步调整：
- 模块增多后可在 `hw/rtl/` 下按子系统再分一层（如 `hw/rtl/analog/`、`hw/rtl/network/`）；
- 验证成熟后可引入 UVM，`hw/verif/sv/` 的分层已预留；
- CI 可在 `ci/` 下补充 lint、回归、覆盖率汇总脚本；
- 文档模板可按团队评审习惯裁剪。

> 参考规范：AMD/Xilinx Revision Control Methodology、UG894（Tcl 脚本化）、UG896（IP 仓库 per-IP 目录）、NASA PLD 开发规范（需求跟踪与评审门禁）。
