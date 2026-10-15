# hw/verif —— 验证代码（Verification，不可综合）

> 本目录放所有**不可综合**的验证代码：Testbench、SystemVerilog 接口/环境/用例、断言、激励、黄金模型、仿真脚本。
> 这里的代码**只进仿真工程，绝不进入实现工程**。设计源只读引用自 `hw/rtl/`。

## 1. 目录约定（标准分层）
```
hw/verif/
├── tb/            # 测试顶层与用例，按模块分目录：tb/<module>/tb_<module>.sv
├── sv/
│   ├── interfaces/  # SystemVerilog interface（AXIS/AXI-Lite），含时钟块、协议断言
│   ├── env/         # driver / monitor / generator / scoreboard / transaction
│   ├── agents/      # 可复用 agent（driver+monitor+sequencer 的封装）
│   ├── sequences/   # 激励序列库
│   └── coverage/    # covergroup 功能覆盖率
├── assertions/    # 模块级断言 bind 文件（绑定 DUT，不改设计代码）
├── stimulus/      # 测试向量、码型、随机种子
├── ref_model/     # Golden Model 数据/参考逻辑（与 host/golden_model 对齐）
├── filelists/
│   └── verif.f    # 验证清单：-f 引入 rtl.f，再列出本目录验证文件
├── scripts/
│   └── run_sim.tcl  # 创建独立仿真工程并运行
├── work/          # 编译/仿真中间产物（git 忽略）
├── waves/         # 波形（git 忽略）
└── report/        # 覆盖率、回归、结果报告
```

## 2. 两个工程如何共享同一份 RTL
```
                    ┌──────────────────────┐
                    │ hw/rtl（可综合，只读）│
                    └──────────┬───────────┘
                               │ rtl.f
              ┌────────────────┴────────────────┐
              │                                 │
     实现工程 impl_proj                 仿真工程 sim_proj
   rtl.f + 约束 + BD（无 verif）     rtl.f + verif.f（含 tb/sv）
   create_impl_project.tcl           run_sim.tcl
```

## 3. 三种运行方式
1. **Vivado 工程模式（推荐你起步）**：用 `run_sim.tcl` 建独立仿真工程，TB 进 `sim_1` fileset。
2. **Vivado 非工程模式（命令行）**：`xvlog -sv -f hw/verif/filelists/verif.f` → `xelab` → `xsim`，产物进 `work/`。
3. **第三方仿真器（Questa/ModelSim/VCS）**：`vlog -f verif.f`（VCS 为 vlogan），SV/UVM 能力更强。

## 4. 规则
- 用例与 `docs/03_verification/03-02_测试矩阵.md` 一一对应；失败用例凭“用例名+种子”可复现。
- 所有结果自动比对（断言/记分板），禁止人工看波形判对错。
- 断言优先用 `bind` 绑定 DUT，不在 RTL 里写 `ifdef SIM`。
- 回归跑完覆盖率/日志输出到 `report/`，中间产物只放 `work/`。
