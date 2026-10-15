# hw/sim_proj —— 仿真工程（Vivado 工程产物）

本目录由 `hw/verif/scripts/run_sim.tcl` 自动生成，是独立于实现工程的仿真专用 Vivado 工程。

- 内容**不入版本库**（见 .gitignore），可随时删除重建。
- 设计源（rtl.f）只读引用 `hw/rtl`，验证代码（verif.f）来自 `hw/verif`，TB 位于 `sim_1` fileset。
- 若使用第三方仿真器（Questa/ModelSim/VCS），可不建本工程，编译产物放 `hw/verif/work/`。
