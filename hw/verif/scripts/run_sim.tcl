# =============================================================================
# run_sim.tcl —— 创建【仿真工程】并运行仿真（独立于实现工程）
#
# 在【仓库根目录】执行：
#   vivado -mode batch -source hw/verif/scripts/run_sim.tcl -tclargs tb_adc_frontend
#
# 关键：仿真工程 = rtl.f（设计，只读）+ verif.f（验证代码）。
# 设计源进 sources_1，验证代码进 sim_1 fileset；Vivado 保证 sim_1 不参与综合。
# 仿真工程产物在 hw/sim_proj，已被 git 忽略。
#
# 若使用 Questa/ModelSim/VCS 等第三方仿真器，则不用本脚本，直接用命令行：
#   vlog -f hw/verif/filelists/verif.f   （VCS 用 vlogan，按工具语法调整）
# =============================================================================

# ---- 1. 读取 filelist（支持 # 注释、行尾 # 注释与 -f 嵌套）----
#   skip_includes=1 时跳过所有 -f 行（用于 sim_1：设计源已在 sources_1 单独加入，
#   避免把 verif.f 里的 -f rtl.f 重复塞进 sim_1）。
#   注意：行尾 # 注释会被剥离，否则会被当作文件路径的一部分（ADR 0013 / 评审#5）。
proc read_filelist {flist {skip_includes 0}} {
    set files {}
    set fh [open $flist r]
    while {[gets $fh line] >= 0} {
        set hash [string first "#" $line]
        if {$hash >= 0} { set line [string range $line 0 [expr {$hash - 1}]] }
        set line [string trim $line]
        if {$line eq ""} { continue }
        if {[string match {-f *} $line]} {
            if {$skip_includes} { continue }
            set sub [string trim [string range $line 2 end]]
            foreach f [read_filelist $sub 0] { lappend files $f }
        } else {
            lappend files $line
        }
    }
    close $fh
    return $files
}

# ---- 2. 配置（按实际器件/测试名）----
set PART       "xc7z020clg400-1"
set PROJ_DIR   "hw/sim_proj"
set PROJ_NAME  "sim_proj"
set TEST_TOP   [lindex $argv 0]
if {$TEST_TOP eq ""} { set TEST_TOP "tb_system_top" }

# ---- 3. 创建独立仿真工程 ----
create_project $PROJ_NAME $PROJ_DIR -part $PART -force
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

# ---- 4. 设计源 → sources_1（只读引用，不复制；全工程只加这一次）----
add_files [read_filelist "hw/rtl/filelists/rtl.f"]

# ---- 5. 验证代码 → sim_1（interface/env/tb/断言，不可综合）----
# 关键：skip_includes=1，跳过 verif.f 顶部的 -f rtl.f，
# 设计源只在 sources_1 出现一次，sim_1 只放验证文件，不重复。
# Vivado 仿真时自动编译 sources_1（设计）+ sim_1（TB）。
add_files -fileset sim_1 [read_filelist "hw/verif/filelists/verif.f" 1]

# ---- 6. 设置仿真顶层、编译选项（覆盖率、断言）----
set_property top $TEST_TOP [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {0} -objects [get_filesets sim_1]
set_property -name {xsim.elaborate.debug_level} -value {all} -objects [get_filesets sim_1]
# 覆盖率（xsim 用 cc 开关，按版本调整）
set_property -name {xsim.elaborate.more_options} -value {-coverage all} -objects [get_filesets sim_1]

update_compile_order -fileset sim_1

# ---- 7. 启动仿真（行为仿真）----
launch_simulation

# ---- 8. 运行并导出覆盖率（run_all 或按用例脚本）----
# run_all
# exec /bin/sh -c "xcov ..." ;# 或在 GUI/Tcl 中 report_coverage

puts "INFO: Simulation launched for top=$TEST_TOP. RTL and verif are separate filelists."
