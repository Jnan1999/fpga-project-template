---
paths: ["hw/rtl/**/*.v", "hw/rtl/**/*.sv"]
---

# RTL 编码规范（编辑 hw/rtl/ 下文件时适用）

> 标准写法参考：`hw/rtl/pulse_gen/` 三件套（唯一权威示例，风格以它为准）。

## 可综合子集（硬性）
- 无 `initial`、无 `#delay`、无 `force`；不用 SystemVerilog 中不可综合的结构（项目风格限制，非工具不支持）
- 异步复位**低有效、同步释放**（风格与 pulse_gen.v 一致）：`always @(posedge clk or negedge rst_n)`
- 禁止推断 latch：所有分支补全，组合逻辑 always 块给默认值

## 三件套结构（默认模式，ADR 0014）
- **core**（`rtl/<mod>.v`）：纯功能。禁止 `dbg_` 端口、禁止任何调试/观测/注入代码
- **dft_wrap**（`dft_wrap/<mod>_dft.v`）：**内部例化 core**，功能端口逐字透传，观测/注入全走 `dbg_` 前缀调试总线
- **wrap**（`<mod>_wrap.v`）：`generate if(ENABLE_DFT)` 二选一；top 只例化 `*_wrap`，禁止直接例化 core/dft
- 例外（common/ CDC 同步器、简单组合、官方 IP/原语）不强制三件套，但模块必须在 `project.yaml` 用 `dft_mode` 声明
- core 与 dft **功能端口逐字一致**（名/方向/位宽），`dbg_` 前缀豁免——完工必跑 `scripts/check_ports.py`（或 `/project:module-check <mod>`）

## 官方优先原则（ADR 0002）
- **能用官方 IP 不手搓**：FIFO Generator / AXI DMA / Clocking Wizard 等，用前读对应 PG 手册
- **原语/推断模板照手册写**：时钟（UG472）、SelectIO（UG471）、原语（UG953）照 UG901 推断模板或 UG953 例化，不写"祈祷综合器看懂"的写法
- **引用必注明出处**：UG 编号 + 章节 + 文档版本（对应 project.yaml 的 Vivado 版本）；**禁止凭记忆编造端口/参数/时序数值**
- 手册地图：`docs/refs/xilinx/README.md`（注意器件适用性：7 系列 vs UltraScale+ 手册不同）
- **手册核实纪律**：MCP 未启用期间，引用具体数值/端口/属性前必须查证官方手册；无法查证时**明确告诉用户"此数值需要查 UG/PG 手册确认"**，禁止以"待核实"标注后继续当作事实使用

## 接口与握手
- 握手按 LLD 接口节：valid/ready 同拍传输，valid 置起后数据保持稳定；禁止裸 valid 无反压
- **CDC**：禁止多 bit 信号裸跨时钟域；跨域按 `01-04` 时钟复位清单的同步方式，一律用 `common/` 组件，不自造同步器
- 接口冻结表 `frozen: true` 的接口禁止改动任何属性；需要变更时停下来走变更流程

## 文件登记与注释
- 新增/删除源文件必须同步登记 `hw/rtl/filelists/rtl.f`（注释单独成行，禁止行尾注释——会被解析进路径）
- 注释风格与 pulse_gen.v 一致：文件头块注释（功能/端口/关键设计）+ 端口行注释
