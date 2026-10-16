---
description: 新增模块六步 checklist——复制示例三件套、登记 filelist/注册表、写 TB 与 LLD 草稿
argument-hint: "<模块名>（小写蛇形，如 adc_frontend）"
---

为模块 `$ARGUMENTS` 执行新增模块流程（对应 CLAUDE.md「新增模块 checklist」）。每步完成后报告，遇问题停下来问用户：

1. **复制三件套**：`hw/rtl/pulse_gen/` → `hw/rtl/$ARGUMENTS/`，重命名三个文件与模块名（`<mod>.v` / `<mod>_dft.v` / `<mod>_wrap.v`），逐处替换 `pulse_gen` → `$ARGUMENTS`。遵守 `.claude/rules/rtl-style.md`。
2. **登记 filelist**：`hw/rtl/filelists/rtl.f` 追加三行（注释单独成行，禁止行尾注释）。
3. **建 TB**：`hw/verif/tb/$ARGUMENTS/tb_$ARGUMENTS.sv`（参考 pulse_gen TB 写法），`hw/verif/filelists/verif.f` 追加。遵守 `.claude/rules/tb-style.md`。
4. **端口一致性**：运行 `/project:module-check $ARGUMENTS`，退出码必须为 0。
5. **写 LLD 草稿**：用 `docs/templates/_模板_LLD_agent精简版.md` 填 `docs/02_module_design/$ARGUMENTS/LLD_$ARGUMENTS.md` → 提交用户审核（完整版审核后再补）。
6. **登记注册表**：`project.yaml` 的 `modules:` 追加 `$ARGUMENTS`（status: design，dft_mode 按模块性质填写并给理由；ADR 0014）。

若模块属官方 IP/原语/common 组件（`dft_mode != three_piece`），跳过第 1/2/4 步的三件套部分，但仍需登记注册表与说明理由。
