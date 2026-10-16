---
description: 模块级端口一致性检查——core 与 dft_wrap 功能端口逐字比对，只报告差异、不改源码
argument-hint: "<模块名>"
---

对模块 `$ARGUMENTS` 执行端口一致性检查（信任模型的 verification 类检查，ADR 0010）：

```bash
uv run python scripts/check_ports.py hw/rtl/$ARGUMENTS/rtl/$ARGUMENTS.v hw/rtl/$ARGUMENTS/dft_wrap/${ARGUMENTS}_dft.v
```

> 说明：`$ARGUMENTS` 是 Claude Code 命令的参数占位符（官方语法）；上面 Bash 代码块里若出现 `$ARGUMENTS`/`${ARGUMENTS}` 未被替换的形式，请先替换为实际模块名再执行——占位符不会被 shell 当作命令参数。

**本命令只做检查、不做修复**（检查权限不隐含修复权限，ADR 0020）：

- 退出码 0 → 报告 PASS；
- 退出码非 0（端口不一致）→ **原样出示差异，不改动任何源文件**。端口不一致本身不能说明该改哪一侧——正确一侧应以已批准的接口契约（`contracts/interfaces.yaml` / ICD）为准。把差异报告给用户，由用户决定是否、以及修哪一侧；修复由后续明确的修复请求发起（自然语言即可），不在本检查内自动进行。
- 脚本报错（fail-closed 解析失败）→ **这暴露的是"检查能力不足"，不是"设计错误"**。出示报错与该处 RTL 写法，说明 check_ports 的解析边界；优先扩展/修正解析器，而不是为了让简化检查器通过而修改合法设计。确需用户裁决时停下来问。

边界提醒：本检查只证明 core/dft **端口名/方向/位宽一致**，不能证明参数默认值相同、信号接对、功能正确（ADR 0010 能力边界表）。
