# =============================================================================
# verif.f —— 仿真专用文件清单（Verification Source File List）
#
# 本清单【只进仿真工程】，严禁加入实现工程。
# 第一行先包含设计源 rtl.f，因此仿真工程 = rtl.f（设计） + 下列验证文件。
#
# 说明：
#   - 第三方仿真器（Questa/ModelSim/VCS/Xcelium）用 -f 直接读取；
#   - Vivado xsim 工程由 hw/verif/scripts/run_sim.tcl 读取本清单（递归处理 -f）。
# =============================================================================

# 先编译设计源（只读引用，不复制）
-f hw/rtl/filelists/rtl.f

# --- 模块级 TB（按模块分目录）---
hw/verif/tb/pulse_gen/tb_pulse_gen.sv
# 新增模块时在此追加：hw/verif/tb/<module>/tb_<module>.sv

# -----------------------------------------------------------------------------
# 以下为规划中的验证环境组件（UVM 式 env / interface / 断言），文件尚未落盘。
# 取消注释前必须先落盘对应文件，否则仿真工程会因文件缺失失败（fail-closed，
# 与 rtl.f 同一原则）。落盘时按需建立目录：
#   hw/verif/sv/interfaces/  hw/verif/sv/env/  hw/verif/sv/agents/
#   hw/verif/sv/sequences/   hw/verif/sv/coverage/  hw/verif/assertions/
# -----------------------------------------------------------------------------
# hw/verif/sv/interfaces/axis_if.sv
# hw/verif/sv/interfaces/axil_if.sv
# hw/verif/sv/env/transaction.sv
# hw/verif/sv/env/generator.sv
# hw/verif/sv/env/driver.sv
# hw/verif/sv/env/monitor.sv
# hw/verif/sv/env/scoreboard.sv
# hw/verif/sv/agents/axis_agent.sv
# hw/verif/sv/sequences/sequences.sv
# hw/verif/sv/coverage/covergroups.sv
# hw/verif/assertions/pulse_gen_assertions.sv
# hw/verif/sv/interfaces/axis_if_sva.sv
# hw/verif/tb/tb_system_top.sv

# 注：激励向量、Golden Model 数据放在 stimulus/、ref_model/，
#     运行时由 $readmemh / 脚本载入，不需要编译进本清单。
