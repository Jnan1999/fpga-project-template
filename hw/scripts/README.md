# hw/scripts —— 实现工程构建脚本（可复现构建）

> 工程（.xpr）只放在 `hw/impl_proj`（git 忽略），入库的是脚本 + filelist，任何人 checkout 后用同一脚本重建出完全一致的工程。仿真工程脚本在 `hw/verif/scripts/run_sim.tcl`，产物在 `hw/sim_proj`。

## 当前脚本（Tcl，由 Vivado 批处理调用）
| 脚本 | 作用 | 工程目录 |
| --- | --- | --- |
| `create_impl_project.tcl` | 建实现工程、加 `rtl.f`（可综合源）+ 约束 + BD，可一键综合/实现/比特流 | `hw/impl_proj` |
| `../verif/scripts/run_sim.tcl` | 建独立仿真工程：设计源进 `sources_1`，验证文件进 `sim_1`（不重复），启动 xsim | `hw/sim_proj` |

## 用法（均在仓库根目录执行）
```bash
# 实现工程
vivado -mode batch -source hw/scripts/create_impl_project.tcl

# 仿真工程（指定测试顶层）
vivado -mode batch -source hw/verif/scripts/run_sim.tcl -tclargs tb_pulse_gen
```

## 原则
- 源文件保持在工程外部（不勾选 Copy sources into project），工程可随时删除重建。
- 设计源的唯一入口是 `hw/rtl/filelists/rtl.f`；实现工程只读它，仿真工程读它 + `hw/verif/filelists/verif.f`。
- Block Design 一律 `write_bd_tcl` 导出为 `hw/bd/*.tcl`，不直接提交 .bd。
- 所有日志输出到 `logs/`，带统一前缀便于检索。
- 综合/实现策略、器件版本固化在脚本里，避免“我电脑上能过”。
- 若换用其他工具链（Quartus/Diamond/第三方仿真器），只需保留 `hw/rtl` 源码与 filelist，重新建工程即可，无需迁移任何工程目录。
