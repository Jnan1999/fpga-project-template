# hw/rtl —— 可综合设计源（Design RTL，只读可信源）

> 本目录只放**可综合**的硬件设计代码，是实现工程和仿真工程共同引用的唯一来源。
> **禁止**在本目录放 testbench、断言 bind、$dump 等纯仿真内容——这些一律放 `hw/verif/`。
> 说明（评审#9）："SV interface/class/initial 不可综合"是**本项目的风格限制**，非普遍语言事实——
> SystemVerilog 有可综合子集。本项目为清晰与保险，规定可综合代码只用 Verilog/SV 可综合子集，
> interface/class/UVM/initial-for-sim 等验证构造一律归 `hw/verif/`。

## 1. 模块目录规范：按模块（per-module）组织 + 三件套

> 已提供可直接参考的示例模块 `pulse_gen/`（core / dft_wrap / wrap 三个文件 + 端口门禁脚本）。

```
<module_name>/
├── <module_name>_wrap.v   # 【对外统一入口】top 永远只例化它；parameter ENABLE_DFT 二选一
├── rtl/
│   └── <module_name>.v        # 功能核心：资源最少的纯功能，无任何调试代码（唯一可信源）
└── dft_wrap/
    └── <module_name>_dft.v    # 可测性包装：内部例化核心，功能端口透传 + dbg_ 调试总线
```
- 模块的 testbench 统一放在 `hw/verif/tb/<module_name>/`，按模块名对应，本目录无 tb。
- 通用组件（CDC 同步、异步 FIFO、复位同步器）放 `common/`；系统顶层只做例化放 `top/`。

### 1.1 三层职责（pulse_gen 已落地）
1. **`pulse_gen.v`（core）**：纯功能，禁止 dbg_ 端口和调试逻辑；功能只存在这一份。
2. **`pulse_gen_dft.v`（dft_wrap）**：**内部例化 core**，功能端口逐字透传；观测/注入全部走 `dbg_` 前缀的独立调试总线（`dbg_force_pulse`/`dbg_block_en`/`dbg_pulse_cnt` 等）。
3. **`pulse_gen_wrap.v`（wrap）**：top 唯一例化对象；`generate if(ENABLE_DFT)` 在内部分别例化 dft 或 core，`ENABLE_DFT=0` 时调试输出 tie off、DFT 整体不综合（零开销）。

> ⚠️ **精确的保证（评审#7b）**：不能说"DFT 内部例化 core 所以功能不可能漂移"——dft 本就**故意**在边界注入故障（如示例门控 `cfg_en`、强制 `pulse_out`）。正确保证是：
> - **注入关闭（dbg_force_pulse=0、dbg_block_en=0）时**，dft 的功能行为与 core 满足规定等价关系；
> - **注入开启时**，行为符合明确的故障模型；
> - **`ENABLE_DFT=0`（发布配置）时**，注入逻辑确实不存在/不可启用，零开销；
> - 两种配置都应分别验证，而不仅是核对端口表。

### 1.2 为什么不顶层平铺成 rtl/ 和 dft/ 两个大目录
- **官方/业界按 IP（模块）组织，不按文件类型平铺**：AMD/Xilinx IP 仓库规范为 `<company>/<IP名_版本>/` 一个自包含目录；Xilinx IP Packager 的 file group、CERN 的 Vivado CI 框架 Hog 也要求每个 IP 放同名子目录。
- **模块是复用、打包、验证、review 的最小单元**：一个模块的 core/dft/wrap/tb 放在一起，打包成 IP、做模块验证、改动检查时一次看全；顶层平铺几十个文件后，一个模块的文件散在 rtl/、dft/、tb/ 三处，反而更难检查。
- 模块越多，per-module 越清晰；真正的“类型分离”在顶层用 `hw/rtl`（可综合）与 `hw/verif`（不可综合）两大目录已经完成，rtl 内部不需要再按 rtl/dft 平铺。

### 1.3 为什么不能靠“两个平级模块 + 手改 top 例化名”
- 手改例化名：模块多了要改 N 处，容易漏；
- 手工维护两份端口表：改了 core 忘改 dft 会**静默漂移**，直到 release 版例化才报错。
- 本方案把“接口相等”从“人肉保证”升级为**编译期/CI 强制保证**：
  - dft 内部例化 core → 功能唯一，不可能功能漂移；
  - wrap 透传功能端口 → 三者端口不匹配直接编译失败；
  - `scripts/check_ports.py` 对比 core 与 dft 的功能端口（名/方向/位宽），dbg_ 端口豁免，不一致即退出非 0，接入 CI 门禁。

## 2. 唯一对外接口：filelist
- 本目录对工程的唯一入口是 `filelists/rtl.f`（可综合源清单）。
- **实现工程**：`hw/scripts/create_impl_project.tcl` 读取 `rtl.f` + 约束 + BD。
- **仿真工程**：`hw/verif/filelists/verif.f` 顶部 `-f rtl.f` 复用同一份设计源。
- 新增/删除设计文件时，**只改 rtl.f**，两个工程自动同步，无需在 GUI 里手动加文件。

## 3. 为什么不能把 TB 和 RTL 放一起
- TB 含不可综合结构，误加进综合工程会报错或静默异常；
- 设计与验证的生命周期、评审、负责人、回归节奏不同；
- 工业界（ASIC/IC 与规范 FPGA 团队）统一采用 rtl 与 verif 物理分离。

## 4. DFT 代码的归属判定（按“可不可综合”）
| 类型 | 目录 | 进实现工程？ | 进仿真工程？ |
| --- | --- | --- | --- |
| 可综合观测/计数/故障注入（dft_wrap） | hw/rtl/<mod>/dft_wrap | 是（调试版；发布版 ENABLE_DFT=0 裁掉） | 是 |
| SV interface/class、scoreboard、covergroup、bind 断言、force 注入 | hw/verif/ | 否 | 是 |
