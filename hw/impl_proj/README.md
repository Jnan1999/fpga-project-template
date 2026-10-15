# hw/impl_proj —— 实现工程（Vivado 工程产物）

本目录由 `hw/scripts/create_impl_project.tcl` 自动生成，包含 Vivado 工程文件、综合/实现/比特流的中间产物与结果。

- 内容**不入版本库**（见 .gitignore），任何人用脚本可从 `hw/rtl` + `hw/constraints` + `hw/bd` 重建出完全一致的工程。
- 实现工程只包含可综合源（rtl.f）与约束，**不包含 hw/verif**。
- 不要手动在 GUI 里改工程设置；可复现的设置必须写回脚本/约束。
