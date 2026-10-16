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
#
# 结构（ADR 0020 两段分离）：
#   【驱动段】建工程/启仿真 —— agent 可自由改造（方法自由）
#   【汇总判读段】末尾 SUMMARY 的生成与 PASS 口径 —— 属验收口径，改动需用户审核
# =============================================================================

# ======================= 驱动段（agent 可自由改造） =======================

# 环境硬化变量兼容（2026-10-16 实证）：若用户环境设置了
# NoDefaultCurrentDirectoryInExePath=1（安全基线），cmd 不再搜索当前目录，
# Vivado launch_simulation 以相对名 spawn 生成的 compile.bat 会立即失败
# （Spawn failed: Broken pipe）。仅在本进程环境内摘除，不影响用户全局配置。
unset -nocomplain env(NoDefaultCurrentDirectoryInExePath)

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

set RUN_ID "[clock format [clock seconds] -format "%Y%m%d_%H%M%S"]_${TEST_TOP}"

# ---- 3~7. 仿真主流程（catch 包裹：失败也要落 SUMMARY，fail-closed）----
set rc [catch {
    # 3. 创建独立仿真工程
    create_project $PROJ_NAME $PROJ_DIR -part $PART -force
    set_property target_language Verilog [current_project]
    set_property simulator_language Mixed [current_project]

    # 4. 设计源 → sources_1（只读引用，不复制；全工程只加这一次）
    add_files [read_filelist "hw/rtl/filelists/rtl.f"]

    # 5. 验证代码 → sim_1（interface/env/tb/断言，不可综合）
    # 关键：skip_includes=1，跳过 verif.f 顶部的 -f rtl.f，
    # 设计源只在 sources_1 出现一次，sim_1 只放验证文件，不重复。
    add_files -fileset sim_1 [read_filelist "hw/verif/filelists/verif.f" 1]

    # 6. 设置仿真顶层、编译选项（覆盖率、断言）
    set_property top $TEST_TOP [get_filesets sim_1]
    set_property top_lib xil_defaultlib [get_filesets sim_1]
    # runtime=all：生成的 xsim tcl 为 `run all`——仿真寿命由 TB 的 $finish 决定。
    # 禁用 0：会生成 `run 0`（仿真一步不走，TB 从未执行 → 日志无 FAIL → 假 PASS，
    # fail-open，2026-10-16 实测生成的 tb_pulse_gen.tcl 即为 `run 0`）。
    set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]
    set_property -name {xsim.elaborate.debug_level} -value {all} -objects [get_filesets sim_1]
    # 覆盖率开关（2026-10-16 实证修复，三轮实测收敛）：
    #   ① `-coverage all` 是新版语法——xelab 2021.1 无 --coverage 选项（`xelab --help` 实测）；
    #   ② 属性名 xsim.elaborate.more_options 在 2021.1 不存在（list_property 实测），
    #     正确名为 xsim.elaborate.xelab.more_options；
    #   ③ 专用属性 COVERAGE.TYPE 的取值是单词不是字母——合法值
    #     "line branch condition 或 all"（USF-XSim-20 实测），字母式 "sbc" 被拒。
    set_property -name {xsim.elaborate.coverage.type} -value {all} -objects [get_filesets sim_1]

    update_compile_order -fileset sim_1

    # 7. 启动仿真（行为仿真）
    launch_simulation

    # 8. 仿真寿命由 TB 的 $finish 决定（runtime=all 见上）；覆盖率数据在
    #    ./xsim.codecov（COVERAGE.TYPE=all），需要报表时用 xcrg 另行导出。
    #    注意：run_all/close_sim 是 xsim 命令，不是 Vivado 工程 tcl 命令——
    #    在 launch_simulation 之外调用会报 invalid command name（已实测）。
} err]

puts "INFO: Simulation launched for top=$TEST_TOP. RTL and verif are separate filelists."

# ================= 汇总判读段（验收口径，改动需用户审核） =================
# PASS 口径（与 ops.yaml run_sim 的退出码口径一致："仿真运行完成且用例全过"）：
#   rc==0（脚本与仿真器无 Tcl/启动错误）且仿真日志中无 Error/Fatal/FAIL 计数。
# 注意：本段只判定"哪些结果被算进 PASS"；"测什么、怎么判对错"属验证计划（hw/verif/），
# TB 必须自检（scoreboard/断言），本段的关键字扫描是最后一道兜底，不能替代 TB 自检。

proc tool_version {} {
    if {[catch {version} v]} { return "unknown" }
    return [string trim [lindex [split $v "\n"] 0]]
}
proc git_hash {} {
    if {[catch {exec git rev-parse --short HEAD} h]} { return "unknown" }
    return [string trim $h]
}

# 扫描 xsim 日志的错误计数（判读口径的一部分）
set sim_errors -1   ;# -1 = 日志缺失（结果未知 → fail-closed 判 FAIL）
foreach cand [list \
    "$PROJ_DIR/$PROJ_NAME.sim/sim_1/behav/xsim/xsim.log" \
    "$PROJ_DIR/$PROJ_NAME.sim/sim_1/behav/xsim/simulate.log"] {
    if {[file exists $cand]} {
        set sim_errors 0
        set lf [open $cand r]
        while {[gets $lf line] >= 0} {
            if {[regexp {(^|[^a-zA-Z])(Error|Fatal|FATAL|FAIL)[: ]} $line]} { incr sim_errors }
        }
        close $lf
        break
    }
}

set passed [expr {$rc == 0 && $sim_errors == 0}]

file mkdir "logs"
set log_file "logs/sim_${RUN_ID}.log"
set fh [open $log_file w]
puts $fh "=== SUMMARY ==="
puts $fh "RESULT: [expr {$passed ? "PASS" : "FAIL"}]"
puts $fh "RUN_ID: $RUN_ID"
puts $fh "GIT_HASH: [git_hash]"
puts $fh "TOOL_VERSION: [tool_version]"
puts $fh "TEST_TOP: $TEST_TOP"
puts $fh "SIM_ERRORS: $sim_errors"
if {$rc != 0} { puts $fh "ERROR: $err" }
puts $fh "==============="
close $fh
puts "INFO: SUMMARY written to $log_file (RESULT=[expr {$passed ? "PASS" : "FAIL"}])"

# 退出码统一口径（ADR 0013 / ops.yaml）：0=仿真运行完成且用例全过，非 0=否则
if {!$passed} {
    if {$rc != 0} { puts "ERROR: $err" }
    exit 1
}
exit 0
