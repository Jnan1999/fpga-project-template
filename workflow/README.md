# workflow/ —— Agent 阶段操作规程

> 每个阶段一个 playbook。Agent 进入项目后：读 `project.yaml` 的 `current_phase` → 打开对应 playbook → 严格按其执行。
> 每个 playbook 固定 6 节：**入口条件 / Agent 输入 / Agent 任务 / 验证命令 / 出口标准(Gate) / 常见失败模式**。

## 阶段模型（V 模型 + UltraFast 方法论）

```
P0 需求捕获 ─G1→ P1 系统架构 ─G2→ P2 模块设计 ─接口冻结→ P3 并行实现 ─G3→ P4 功能验证 → P5 时序收敛 → P6 集成上板 ─G4→ Release
                                                              ├─ RTL 三件套（rtl-engineer）
                                                              ├─ Golden Model（golden-modeler）
                                                              └─ 验证环境（verification 骨架）
```

| Gate | 名称 | 机读判据 | 确认人 |
| --- | --- | --- | --- |
| G1 | spec review | 需求确认清单全部 ✅；SRS 每条需求量化可衡量；RTM 每行验证方法非空 | 用户 + 部门领导 |
| G2 | architecture review | 每个 SRS 功能需求有模块承接；每个接口在 ICD 有章节并登记 interfaces 表；每条 CDC 在 01-04 清单 | 用户 |
| — | 接口冻结（P2 出口） | `project.yaml` interfaces 全部 `frozen: true`；每模块 LLD 评审通过 | 用户 |
| G3 | pre-commitment review | `check_ports.py` 全模块退出码 0；elaboration 无 error；`report_methodology` 无 critical warning | 用户 |
| — | P4 出口 | 功能覆盖率 100% + 行覆盖率 ≥95% + 分支 ≥90%；全回归 PASS；RTM 验证状态回填 | 用户 |
| — | P5 出口 | post-route WNS ≥ 0；`report_methodology`/`report_drc` 无 critical；资源 < HLD 预算 | 用户 |
| G4 | release review | 板级用例全过；三路比对差异在量化误差内；Release 包（比特流嵌 git hash） | 用户 |

## 状态更新规则
1. Agent 完成某阶段全部任务 + 验证命令全绿 → 向用户出示结果，申请 gate 评审
2. 用户确认通过 → 更新 `project.yaml`：该阶段 `status: done`，下一阶段 `status: in_progress`，`current_phase` 前进
3. **Gate 未通过时禁止推进**；第二批的 `scripts/check_gate.py` 将对此机械强制

## 人机分工总原则
| Agent 做 | 用户做 |
| --- | --- |
| 生成文档/代码/TB/Golden Model 草稿 | 审核、与领导对齐、理解计算流程 |
| 跑验证命令、读日志、分析失败、修 bug | 审核修复方案（diff） |
| 回填状态（测试矩阵/RTM/调试记录） | gate 确认、更新 project.yaml 阶段状态 |
| 列出决策选项 + 推荐 | 做最终决策 |
