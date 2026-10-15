# P2 模块设计（Module Design）

> 阶段目标：每个模块一份 LLD（微架构规格）+ 验证计划，并把 P1 登记的接口**最终冻结**。
> 本阶段出口后，接口不再修改——P3 三条并行线（RTL / Golden Model / 验证环境）依赖此冻结。

## 1. 入口条件
- G2 通过：`project.yaml` 中 `P1.status: done`

## 2. Agent 输入（必读，按模块）
| 输入 | 路径 |
| --- | --- |
| 该模块在 HLD 中的划分条目 | `docs/01_architecture/01-01_HLD.md` §4 |
| 该模块相关接口章节 | `docs/01_architecture/01-02_ICD.md` |
| 时钟/CDC 约束 | `docs/01_architecture/01-04_时钟与复位架构.md` |
| LLD 模板（Agent 先填精简版） | `docs/templates/_模板_LLD_agent精简版.md` |
| LLD 模板（完整版，审核后补） | `docs/templates/_模板_模块详细设计_LLD.md` |
| Vplan 模板 | `docs/03_verification/03-01_验证计划_Vplan.md` |

## 3. Agent 任务
1. **逐模块生成 LLD**：`docs/02_module_design/<mod>/LLD_<mod>.md`
   - 第一步：填**精简版**（8 节：概述/接口信号表/握手与复位/数据通路逐级表/状态机/参数表/异常与 DFT 观测点/验证点对应表）
   - 数据通路必须逐级写明：位宽变化、定点格式 Qm.n、截位/舍入/饱和规则、延迟拍数——**这是 Golden Model 与 RTL 对齐的唯一依据**
   - 提交用户审核（用户借此理解计算流程）→ 审核通过后补完完整版（资源估算、时序约束、检查清单等）
2. 生成模块验证计划：更新 `03-01_Vplan`（验证点清单，每点有唯一编号 VF-XXX-NN 与优先级）与 `03-02_测试矩阵.md`（模块级用例初稿，用例与验证点一一对应）
3. **接口最终冻结**：全部模块 LLD 评审通过后，把 `project.yaml` 的 `interfaces` 全部置 `frozen: true`，并提示用户确认
4. 确认 `modules:` 各模块 `lld:` 字段指向实际 LLD 路径

## 4. 验证命令
本阶段无代码命令。完工自查项：
- [ ] 每模块 LLD 接口信号表与 `project.yaml` interfaces 冻结表**逐字一致**（信号名/方向/位宽）
- [ ] LLD 数据通路节含完整定点格式定义（Qm.n、舍入、饱和），Golden Model 可据此独立实现
- [ ] Vplan 验证点覆盖 LLD 全部功能与异常场景；测试矩阵用例与验证点编号对应
- [ ] interfaces 全部 `frozen: true`

## 5. 出口标准（接口冻结 gate）
- 用户逐模块审核 LLD 通过（理解并认可计算流程）
- 用户确认接口冻结后更新 `project.yaml`：`P2.status: done`、`P3.status: in_progress`、`current_phase: P3`

## 6. 常见失败模式
| 失败模式 | 规避 |
| --- | --- |
| LLD 接口与 ICD/interfaces 表不一致 | 接口以 interfaces 表为准逐字复制；不一致先查是不是该走变更流程 |
| 定点格式（Qm.n）未定义或含糊 | 每级数据通路写清位宽与小数点位置；否则 Golden Model 无法对齐，P3 返工 |
| 异常场景缺失（FIFO 溢出/反压/复位中输入） | 对照 LLD 模板第 6 节逐类排查；每类给出检测方式与对外指示 |
| 验证点与测试矩阵脱节 | 验证点编号 VF-XXX-NN 在测试矩阵"覆盖验证点"列出现 |
| 接口冻结后悄悄改接口 | frozen 接口改动必须走变更流程：解冻 → 改 ICD+interfaces+所有相关 LLD → 用户确认 → 重新冻结 |
