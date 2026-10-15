# =============================================================================
# create_impl_project.tcl —— 创建【实现工程】（只做综合/实现/比特流）
#
# 在【仓库根目录】执行：
#   vivado -mode batch -source hw/scripts/create_impl_project.tcl
#
# 关键：实现工程只引用 rtl.f（可综合源）+ 约束 + BD，绝不引用 hw/verif。
# 源文件保持在工程外部（不勾选 Copy sources into project），工程可随时删除重建。
# =============================================================================

# ---- 1. 读取 filelist 的通用过程（支持 # 注释与 -f 嵌套）----
#   skip_includes=1 时跳过 -f 行（实现工程一般用默认 0）。
proc read_filelist {flist {skip_includes 0}} {
    set files {}
    set fh [open $flist r]
    while {[gets $fh line] >= 0} {
        set line [string trim $line]
        if {$line eq "" || [string index $line 0] eq "#"} { continue }
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

# ---- 3. 创建工程（-force 可重复重建；工程产物在 hw/impl_proj，已被 git 忽略）----
create_project $PROJ_NAME $PROJ_DIR -part $PART -force
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

# ---- 4. 只加入可综合 RTL（引用 rtl.f，不复制）----
add_files [read_filelist $RTL_FLIST]

# ---- 5. 自研 IP 仓库与 Block Design（BD 由 tcl 重建）----
# set_property ip_repo_paths [list hw/ip_repo] [current_project]
# update_ip_catalog
# source hw/bd/design_1_bd.tcl

# ---- 6. 约束（综合/实现可分文件）----
add_files -fileset constrs_1 [glob -nocomplain hw/constraints/*.xdc]

# ---- 7. 指定顶层并检查编译顺序 ----
set_property top top [current_fileset]
update_compile_order -fileset sources_1

# ---- 8.（可选）直接跑综合/实现/比特流 ----
# launch_runs synth_1 -jobs 8
# wait_on_run synth_1
# launch_runs impl_1 -to_step write_bitstream -jobs 8
# wait_on_run impl_1

puts "INFO: Implementation project created at $PROJ_DIR (RTL only, no verif files)."
