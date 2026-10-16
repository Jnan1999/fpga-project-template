# =============================================================================
# check_elab.tcl —— elaboration + methodology 检查（检查类 op，G3 证据来源）
#
# 在【仓库根目录】执行：
#   vivado -mode batch -source hw/scripts/check_elab.tcl
#
# 非工程模式：直接读 rtl.f 做 RTL elaboration（synth_design -rtl），再报
# report_methodology。证据落 logs/elab_<run_id>.log（末尾 SUMMARY 机读段），
# 供 scripts/check_gate.py 的 G3 检查核对（绑定 GIT_HASH 防过期证据）。
#
# 结构（ADR 0020 两段分离）：驱动段可自由改造；末尾汇总判读段属验收口径。
# =============================================================================

# ======================= 驱动段（agent 可自由改造） =======================

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

set PART      "xc7z020clg400-1"
set TOP       "top"
set RTL_FLIST "hw/rtl/filelists/rtl.f"

set RUN_ID [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
file mkdir "logs"
set rpt_file "logs/elab_${RUN_ID}.methodology.rpt"

set rc [catch {
    read_verilog [read_filelist $RTL_FLIST]
    # elaboration（只做 -rtl 级，不综合映射）
    synth_design -rtl -top $TOP -part $PART
    report_methodology -file $rpt_file
} err]

# ================= 汇总判读段（验收口径，改动需用户审核） =================
# PASS 口径：elaboration 无 Tcl 错误（ERRORS==0）且 methodology 无 critical。
# methodology critical 计数是启发式：报告含 "no critical warnings" 则 0，
# 否则按 "Critical" 出现行数估计 —— 数值口径改动需用户审核。

proc tool_version {} {
    if {[catch {version} v]} { return "unknown" }
    return [string trim [lindex [split $v "\n"] 0]]
}
proc git_hash {} {
    if {[catch {exec git rev-parse --short HEAD} h]} { return "unknown" }
    return [string trim $h]
}

set errors [expr {$rc == 0 ? 0 : 1}]
set meth_critical -1   ;# -1 = 报告缺失（未知 → fail-closed）
if {[file exists $rpt_file]} {
    set rf [open $rpt_file r]
    set rpt [read $rf]
    close $rf
    if {[regexp -nocase {no critical warnings} $rpt]} {
        set meth_critical 0
    } else {
        set meth_critical [regexp -all -nocase {critical} $rpt]
    }
}

set passed [expr {$errors == 0 && $meth_critical == 0}]

set log_file "logs/elab_${RUN_ID}.log"
set fh [open $log_file w]
puts $fh "=== SUMMARY ==="
puts $fh "RESULT: [expr {$passed ? "PASS" : "FAIL"}]"
puts $fh "RUN_ID: $RUN_ID"
puts $fh "GIT_HASH: [git_hash]"
puts $fh "TOOL_VERSION: [tool_version]"
puts $fh "PART: $PART"
puts $fh "TOP: $TOP"
puts $fh "ERRORS: $errors"
puts $fh "METHODOLOGY_CRITICAL: $meth_critical"
if {$rc != 0} { puts $fh "ERROR: $err" }
puts $fh "==============="
close $fh
puts "INFO: SUMMARY written to $log_file (RESULT=[expr {$passed ? "PASS" : "FAIL"}], methodology report: $rpt_file)"

# 退出码统一口径（ADR 0013）：0=PASS，非 0=FAIL
if {!$passed} {
    if {$rc != 0} { puts "ERROR: $err" }
    exit 1
}
exit 0
