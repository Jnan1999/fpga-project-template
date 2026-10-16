---
description: 模块级端口一致性检查——core 与 dft_wrap 功能端口逐字比对（check_ports 的机器门禁）
argument-hint: "<模块名>"
---

对模块 `$ARGUMENTS` 执行端口一致性检查（信任模型的 verification 类检查，ADR 0010）：

```bash
python scripts/check_ports.py hw/rtl/$ARGUMENTS/rtl/$ARGUMENTS.v hw/rtl/$ARGUMENTS/dft_wrap/${ARGUMENTS}_dft.v
```

- 退出码 0 → 报告 PASS；
- 非 0 → 原样出示差异输出，按 `.claude/rules/rtl-style.md` 的端口一致规则修复 core 或 dft_wrap（使功能端口逐字一致，`dbg_` 前缀豁免），然后重跑直到通过；
- 脚本报错（fail-closed 解析失败）→ 出示报错并检查 RTL 声明写法是否超出解析器支持的写法，优先改 RTL 写法；确属解析器缺陷时报告用户，不得绕过。

边界提醒：本检查只证明 core/dft **端口名/方向/位宽一致**，不能证明参数默认值相同、信号接对、功能正确（ADR 0010 能力边界表）。
