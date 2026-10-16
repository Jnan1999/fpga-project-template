# =============================================================================
# create_impl_project.tcl —— 创建【实现工程】（只做综合/实现/比特流）
#
# 在【仓库根目录】执行：
#   vivado -mode batch -source hw/scripts/create_impl_project.tcl
#
# 关键：实现工程只引用 rtl.f（可综合源）+ 约束 + BD，绝不引用 hw/verif。
# 源文件保持在工程外部（不勾选 Copy sources into project），工程可随时删除重建。
#
# 结构（ADR 0020 两段分离）：
#   【驱动段】建工程的全部操作 —— agent 可自由改造（方法自由）
#   【汇总判读段】脚本末尾 SUMMARY 的生成与 PASS 口径 —— 属验收口径，改动需用户审核
# =============================================================================

# ======================= 驱动段（agent 可自由改造） =======================

# ---- 1. 读取 filelist 的通用过程（支持 # 注释、行尾 # 注释与 -f 嵌套）----
#   skip_includes=1 时跳过 -f 行（实现工程一般用默认 0）。
#   注意：行尾 # 注释会被剥离，否则会被当作文件路径的一部分（ADR 0013 / 评审#5）。
proc read_filelist {flist {skip_includes 0}} {
    set files {}
    set fh [open $flist r]
    while {[gets $fh line] >= 0} {
        # 先剥离行尾注释（# 及其后内容），再去空白
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

# ---- 2. 工程配置（按实际器件修改）----
set PART        "xc7z020clg400-1"
set PROJ_DIR    "hw/impl_proj"
set PROJ_NAME   "impl_proj"
set RTL_FLIST   "hw/rtl/filelists/rtl.f"

# ---- 3~7. 建工程主流程（catch 包裹：失败也要落 SUMMARY，fail-closed）----
set RUN_ID [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
set rc [catch {
    # 3. 创建工程（-force 可重复重建；工程产物在 hw/impl_proj，已被 git 忽略）
    create_project $PROJ_NAME $PROJ_DIR -part $PART -force
    set_property target_language Verilog [current_project]
    set_property simulator_language Mixed [current_project]

    # 4. 只加入可综合 RTL（引用 rtl.f，不复制）
    set rtl_files [read_filelist $RTL_FLIST]
    add_files $rtl_files

    # 5. 自研 IP 仓库与 Block Design（BD 由 tcl 重建）
    # set_property ip_repo_paths [list hw/ip_repo] [current_project]
    # update_ip_catalog
    # source hw/bd/design_1_bd.tcl

    # 6. 约束（综合/实现可分文件）
    add_files -fileset constrs_1 [glob -nocomplain hw/constraints/*.xdc]

    # 7. 指定顶层并检查编译顺序
    set_property top top [current_fileset]
    update_compile_order -fileset sources_1

    # 8.（可选）直接跑综合/实现/比特流
    # launch_runs synth_1 -jobs 8
    # wait_on_run synth_1
    # launch_runs impl_1 -to_step write_bitstream -jobs 8
    # wait_on_run impl_1
} err]

puts "INFO: Implementation project created at $PROJ_DIR (RTL only, no verif files)."

# ================= 汇总判读段（验收口径，改动需用户审核） =================
# PASS 口径：建工程主流程无 Tcl 错误（rc==0）。本 op 是执行类（ADR 0010），
# 其 SUMMARY 只证明"工程建成"，不构成验证证据；G3 的 elaboration/methodology
# 证据由 check_elab.tcl 产生。

proc tool_version {} {
    if {[catch {version} v]} { return "unknown" }
    return [string trim [lindex [split $v "\n"] 0]]
}
proc git_hash {} {
    if {[catch {exec git rev-parse --short HEAD} h]} { return "unknown" }
    return [string trim $h]
}

file mkdir "logs"
set log_file "logs/create_proj_${RUN_ID}.log"
set fh [open $log_file w]
puts $fh "=== SUMMARY ==="
puts $fh "RESULT: [expr {$rc == 0 ? "PASS" : "FAIL"}]"
puts $fh "RUN_ID: $RUN_ID"
puts $fh "GIT_HASH: [git_hash]"
puts $fh "TOOL_VERSION: [tool_version]"
puts $fh "PART: $PART"
puts $fh "RTL_FILES: [expr {[info exists rtl_files] ? [llength $rtl_files] : 0}]"
if {$rc != 0} { puts $fh "ERROR: $err" }
puts $fh "==============="
close $fh
puts "INFO: SUMMARY written to $log_file (RESULT=[expr {$rc == 0 ? "PASS" : "FAIL"}])"

# 退出码统一口径（ADR 0013）：0=PASS，非 0=FAIL
if {$rc != 0} { puts "ERROR: $err"; exit 1 }
exit 0
