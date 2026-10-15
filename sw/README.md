# sw —— PS 侧软件（Vitis）

## 目录约定
| 目录 | 内容 |
| --- | --- |
| app/ | 应用主程序：main、主状态机、命令调度、数据通路、watchdog |
| drivers/ | 自定义 IP 的 C 驱动：寄存器地址/位域宏、DMA 封装、SPI 配置（与 docs/01_03 寄存器规格一致） |
| fsbl/ | 定制 FSBL（如需要） |
| scripts/ | 构建、生成 BOOT.BIN、下载脚本 |
| vitis/ | Vitis workspace（工具生成，git 忽略） |

## 规则
- 应用层不直接读写寄存器，一律经 drivers/；工具生成的 BSP/xparameters 不手改
- 环形缓冲、零拷贝、cache 一致性、中断处理按 docs/01_architecture/01-05 实现
- 错误码、日志前缀与寄存器规格、DFT 状态位保持一致
- 纯逻辑（帧解析/环形缓冲）尽量平台无关，便于在 PC 上用 gcc 做单元测试
