# P6 集成与上板（Integration & Bring-up）

> 阶段目标：Vitis 裸机软件 + 比特流上板，板级数据与 Golden Model 三路比对，错误归因，直至 Release。
> 比对方法论见 `host/README.md`：板上原始数据 + 板上结果 + GM 期望，三路互比。

## 1. 入口条件
- `project.yaml` 中 `P5.status: done`（比特流时序收敛）

## 2. Agent 输入（必读）
> 以下清单为**最低要求**（下界非上界）。
| 输入 | 路径 |
| --- | --- |
| Bring-up 计划/硬件测试方案 | `docs/05_bringup/05-01`、`05-02` |
| 寄存器映射（驱动依据） | `docs/01_architecture/01-03_寄存器映射规格.md` |
| PS 软件架构 | `docs/01_architecture/01-05_PS软件架构设计.md` |
| 比对基准 | `host/golden_model/` + `host/README.md` |
| P4 缺陷记录（上板问题先查历史） | `docs/05_bringup/05-03_调试记录.md` |

## 3. Agent 任务
1. **Vitis 裸机软件**（`sw/`）：命令解析 / DMA 配置 / 中断处理 / 环形缓冲与 cache 一致性（flush/invalidate 按 01-05）；寄存器访问一律经 `sw/drivers/`，宏定义与 01-03 一致；纯逻辑（帧解析/环形缓冲）平台无关，可用 gcc 在 PC 单测
2. **版本可追溯**：比特流嵌入 `git rev-parse HEAD`（USR_ACCESS 或版本寄存器），板子上跑的每一版可追溯到 commit
3. **板级测试与三路比对**（按 05-02 用例逐项）：
   - `host/scripts/` 采集：板上原始数据 + 板上处理结果，存盘到 `host/data/`
   - Golden Model 对原始数据算期望 → 三路比对（期望 vs 原始一致性、期望 vs 板载），输出逐点差异与统计
   - **失败归因**：差异定位到模块/环节（接口时序？cache 一致性？定点截位？clocking？），先查 05-03 历史缺陷；归因结论须证据支撑（数据文件+差异模式），不猜测
4. 记录与报告：调试过程进 `05-03`；结果进 `05-04_板级测试报告.md`；通过后制作 Release 包（`releases/`：BOOT.BIN/bit/elf + 版本记录）并写 `07-01_Release_Notes.md`

## 4. 验证命令
| 命令 | 机读判据 |
| --- | --- |
| `uv run python host/scripts/<比对脚本>.py --raw <原始> --board <板载> --gm <期望>` | 逐点差异在 LLD 规定的量化误差内 |
| 板级用例逐项（05-02） | 全部通过，结果回填 05-04 |

## 5. 出口标准（G4 release review）
- 板级用例全过 + 三路比对达标 + 05-04 报告用户审核通过 + Release 包含版本信息
- 用户确认后更新 `project.yaml`：`P6.status: done`、模块 status 改 onboard；写 `07-02_项目复盘.md`

## 6. 常见失败模式
| 失败模式 | 规避 |
| --- | --- |
| 比对只看屏幕不存盘 | 原始/板载/期望数据全部落盘 `host/data/`，报告引用文件名 |
| 跳过 Golden Model 直接怀疑硬件 | 三路比对先定位差异在哪两路之间 |
| cache 一致性误判为 RTL bug | DDR 相关异常先做 flush/invalidate 对照实验 |
| release 包无版本信息 | git hash 嵌 USR_ACCESS；Release Notes 记录 commit + 工具版本 |
| 上板问题与仿真缺陷割裂 | 05-03 是同一本台账，仿真期缺陷上板时先回查 |
