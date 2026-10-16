# =============================================================================
# rtl.f —— 可综合设计源文件清单（Design Source File List）
#
# 这是“唯一可信源”的文件清单：实现工程(impl)与仿真工程(sim)都引用本文件。
# 路径相对【仓库根目录】（构建脚本统一在仓库根执行）。
#
# 铁律：
#   1) 本清单只能出现【可综合】文件（.v/.sv 可综合子集、.xci 由脚本另加）；
#   2) 严禁出现 testbench、interface/class、$dump、initial、force 等仿真内容；
#      仿真专用代码一律放在 hw/verif/，列入 verif.f；
#   3) 每个模块三件套全部编译：core + dft_wrap + wrap；
#      top 永远只例化 <mod>_wrap，发布/调试由参数 ENABLE_DFT（0/1）选择；
#      ENABLE_DFT=0 时 dft_wrap 不被例化，综合器自动丢弃，零逻辑开销。
#   4) 功能核心与 DFT 包装的功能端口必须一致，由 scripts/check_ports.py 门禁。
#
# 行首 # 为注释；-f 可包含其他清单。
# =============================================================================

# --- 通用组件（复位同步、CDC、异步 FIFO 等）---
# 注意：以下三个组件属于规划中的可信积木库，模板暂未附带源文件。
# 取消注释前必须先落盘对应文件，否则建工程/elaboration 会因文件缺失失败（fail-closed）。
# hw/rtl/common/sync_reset.v
# hw/rtl/common/cdc_2ff_sync.v
# hw/rtl/common/async_fifo.v

# --- 示例模块：pulse_gen（core/dft/wrap 三件套，新建模块时照此模板复制）---
#   功能核心（唯一可信源）/ 可测性包装（内部例化核心）/ 顶层统一入口（ENABLE_DFT 二选一）
#   注意：清单条目禁止行尾注释——注释须单独成行，否则会被当作路径一部分（ADR 0013）。
hw/rtl/pulse_gen/rtl/pulse_gen.v
hw/rtl/pulse_gen/dft_wrap/pulse_gen_dft.v
hw/rtl/pulse_gen/pulse_gen_wrap.v

# --- 新增模块在此处按三件套追加（示例：your_module）---
# hw/rtl/your_module/rtl/your_module.v
# hw/rtl/your_module/dft_wrap/your_module_dft.v
# hw/rtl/your_module/your_module_wrap.v

# --- 系统顶层（只做例化与互连）---
hw/rtl/top/top.v

# --- 自研 IP 的 .xci 由实现工程脚本单独 add（IP 产物不进本清单）---
# add_files hw/ip_repo/...
