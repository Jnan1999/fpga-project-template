# docs/refs/xilinx —— Xilinx 官方手册地图

> RTL 编码、时钟/IO 设计、时序收敛前**必读对应手册章节**。
> 手册是解决"怎么写才正确"的**最高权威**——优先于模型记忆、博客、Stack Overflow。

## ⚠️ 版本绑定
本模板 `project.yaml` 锁定 **Vivado 2021.1**。查手册必须对应 2021.1（或核实差异）：
- 原语端口/参数、IP 配置界面在版本间有差异
- 引用任何手册内容必须注明：**UG 编号 + 章节 + 文档版本**（如 "UG953 v2021.1, IDELAYE2 §Port Descriptions"）

## 手册速查（按任务）

| 任务 | 手册 | 读什么 |
| --- | --- | --- |
| 写任何 RTL 前 | **UG901** Vivado Synthesis / HDL Coding | **推断模板**：BRAM/DSP/SRL/移位寄存器的标准写法（照写综合器就能正确推断）；避免"祈祷综合器看懂"的写法 |
| 例化原语前 | **UG953** 7 Series Libraries Guide | 原语端口/参数：IDELAYE2、BUFG/BUFIO/BUFR、MMCME2/PLLE2、ISERDESE2/OSERDESE2、IDELAYCTRL |
| 时钟架构 | **UG472** 7 Series Clocking | MMCM/PLL 配置、时钟缓冲选型（BUFG vs BUFIO vs BUFR）、时钟切换 |
| SelectIO / 采样 | **UG471** 7 Series SelectIO | IDELAY/ISERDES、DDR 采样、I/O 标准、DCI |
| 用官方 IP | **PG 系列**（per-IP Product Guide） | FIFO Generator(PG057)、AXI DMA(PG021)、CLK Wizard(PG065)… 用前读对应 PG |
| 时序收敛 | **UG949** UltraFast Methodology、**UG1292** Timing Closure | 约束先行、基线化实现、失败路径分析方法（见 workflow/P5） |
| CDC 设计 | **UG906** CDC Methodology | 跨时钟域的约束与检查 |
| Tcl 脚本 | **UG894** Vivado Tcl Scripting | 工程重建、批处理（本模板脚本的依据） |
| 版本管理 | **UG994** Vivado Revision Control | 源文件外置、write_project_tcl（本模板铁律 1 的依据） |

## 检索方式（ADR 0002；MCP 层默认不启用，见 ADR 0007）
1. **本地图（当前主用）**：决定"该查哪本哪章"
2. **提示词引用规范（兜底）**：见 `CLAUDE.md` 行为总纲第 7 条——引用手册须注明 UG号+章节+版本；未接 MCP 时凭已知权威写法作答并**标注"待核实"**
3. **amd-doc-search MCP（备选，⏸️ 默认不启用）**：官方文档检索服务，接入方式见 `.claude/README.md`；为防上下文污染暂不启用，需要时由用户显式开启

## 放置约定
官方 PDF 下载后放本目录（git-lfs 管理大文件），命名 `<UG编号>_<名称>_v<版本>.pdf`，如 `UG953_7series_libraries_v2021_1.pdf`。
