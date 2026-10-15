# 模块详细设计：adc_frontend（ADC 采样前端）—— 示例

> 本文件是模板的“填写示范”，用 ADC 采样前端做演示；新模块请复制 `docs/templates/_模板_模块详细设计_LLD.md`（Agent 先填 `_模板_LLD_agent精简版.md`，审核后补完整版）。斜体内容为填写提示，正式文档中删除。

| 模块名称 | adc_frontend | 版本 | v0.1 |
| --- | --- | --- | --- |
| 作者 | （姓名） | 日期 | YYYY-MM-DD |
| 上游 HLD 章节 | 01-01 §4、§8；01-04 §1/§2 | 评审人 | （评审人） |
| RTL 路径 | hw/rtl/adc_frontend/rtl/ | DFT 路径 | hw/rtl/adc_frontend/dft_wrap/ |

## 1. 模块概述
- 1.1 功能：接收 ADC 输出的 LVDS DDR 随路时钟与数据，完成 IDELAY 相位对齐、DDR 解串、位序重排、通道映射，输出标准 AXIS 采样流。
- 1.2 指标：__ MSPS、__ 通道、14 bit；采样窗口左右裕量各 ≥ 1/4 UI；输出固定延迟 __ 拍。
- 1.3 不做：不做算法处理（交 signal_processing）；不做 SPI 配置（PS 软件完成）。

## 2. 顶层框图
```
ADC DCO ─IBUFDS→ BUFIO/BUFR ──→ IDELAYCTRL(300MHz ref)
ADC D[13:0] ─IBUFDS→ IDELAYE2 → IDDR → bit_align → ch_map → AXIS out
                         ↑tap                    ↑
                    AXI-Lite 扫眼/VIO 加载     test_mode 测试码校验
```

## 3. 接口定义
| 信号名 | 方向 | 位宽 | 时钟域 | 有效方式 | 含义 |
| --- | --- | --- | --- | --- | --- |
| adc_dco_p/n | in | 差分 | — | — | ADC 随路时钟 |
| adc_data_p/n | in | __ 对 | adc_clk | — | LVDS DDR 数据 |
| delay_ref_clk | in | 1 | 300MHz | — | IDELAYCTRL 参考 |
| m_axis_tdata | out | 16（{chB,chA}） | adc_clk | — | 解串后样本 |
| m_axis_tvalid | out | 1 | adc_clk | 高 | 有效样本 |
| m_axis_tready | in | 1 | adc_clk | 高 | 下游反压 |
| delay_tap | in | 5×N | axi_clk | — | 每通道延迟 tap 值 |
| ctrl_test_mode | in | 2 | axi_clk | — | 0 正常 1 checker 2 PN 3 ramp |
| status_lock | out | 1 | axi_clk | 高 | 码型校验通过 |

### 握手协议
- 连续采样流，默认无气泡；下游不 ready 时允许丢拍，但必须递增 drop 计数并在状态位锁存，禁止静默丢数。
- 复位后完成一次码型校验，status_lock=1 才允许输出。

## 4. 微架构设计
### 4.1 数据通路（固定延迟）
| 流水级 | 功能 | 延迟 |
| --- | --- | --- |
| S1 | IDELAY 延迟（每 bit 独立 tap） | 1 |
| S2 | IDDR 上下沿解串 | 1 |
| S3 | bitslip 位序重排（按 frame pattern） | 2 |
| S4 | 通道映射 + 拼接 + 测试码校验 | 1 |
### 4.2 控制状态机
- IDLE → WAIT_PATTERN（连续 __ 拍匹配 frame）→ LOCKED →（失配超阈值）→ RECALIBRATE
### 4.3 存储单元：无大数据缓存；通道映射使用寄存器组。
### 4.4 标定算法：上电扫眼（0~31 tap 步进，记录每个 tap 的校验结果），取连续通过窗口中点作为最佳 tap；结果可由寄存器/VIO 固化。

## 5. 参数化配置
| 参数 | 默认 | 含义 |
| --- | --- | --- |
| CHANNEL_NUM | 2 | 通道数 |
| ADC_DATA_WIDTH | 14 | 样本位宽 |
| IDELAY_TAP_MAX | 31 | 扫眼最大 tap |
| ENABLE_DFT | 0 | 可测性包装开关 |

## 6. 异常处理与可测性
| 异常 | 检测 | 行为 | 状态/错误码 |
| --- | --- | --- | --- |
| 位序失配 | frame pattern 连续错误 | 进入 RECALIBRATE | ERR_ALIGN=0x11 |
| 相位漂移 | 运行中校验失败计数超阈值 | 保持输出但置告警 | ERR_DRIFT=0x15 |
| 下游反压丢拍 | ~ready 计数 | 锁存计数 | drop_cnt |
| IDELAYCTRL 未就绪 | rdytap 低 | 不允许锁定 | status_lock=0 |
- DFT 观测：每通道当前 tap、扫眼窗口位图、输入/输出计数、错误计数；注入：tap 强制偏移、相位抖动。

## 7. 时序与约束
- 随路时钟源同步约束：create_clock + set_input_delay（时钟用 t_PD=__ ns，数据 t_SKEW=__ ns，来自 ADC 手册与板级测量）
- IDELAYCTRL 参考时钟 300 MHz；adc_clk 与系统时钟跨域走异步 FIFO（见 CDC#1）

## 8. 验证要求
| 验证点 | 方法 | 期望 | 用例 |
| --- | --- | --- | --- |
| 全 0/全 1/AA/55/walking 1 | 测试码逐 bit 比对 | 100% 正确 | tb_adc_001~005 |
| 扫眼单调性 | 遍历 tap | 连续通过窗口、取中点 | tb_adc_006 |
| 温度/相位漂移 | DFT 注入 tap 偏移 | 裕量内不告警、越界告警 | tb_adc_007 |
| 随机反压 | ready 随机 10 万拍 | 计数差=固定延迟 | tb_adc_008 |
| 任意时刻复位 | 复位插入 | 重新锁定，无残留 | tb_adc_009 |
- 覆盖率目标：行≥95%、分支≥90%。

## 9. 资源估算
*（按实际综合填写，例：IDELAY/IDDR 与通道数线性相关，无 BRAM/DSP）*

## 10. 设计检查清单
- [x] 随路源同步输入延迟约束已写明数值来源
- [x] 跨域数据走异步 FIFO，不做多 bit 直接同步
- [x] 失锁/丢拍均有状态位和计数器，无静默错误
- [x] 扫眼与固定 tap 两种模式可切换，结果可寄存器读取

## 11. 待决问题
| 编号 | 问题 | 结论 | 责任人 | 日期 |
| --- | --- | --- | --- | --- |
| Q1 | 扫眼是上电一次还是周期重标 | 待定（温度漂移指标决定） |  |  |
