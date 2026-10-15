#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_ports.py —— 功能端口一致性门禁（CI 可调用）

作用：
  校验每个模块的“功能核心”与“DFT 包装”的【功能端口】完全一致
  （端口名、方向、位宽都相同）；dbg_ / debug_ 前缀的调试端口不在比较范围内。
  这是对“dft 包装必须与核心可无缝替换”的自动化约束，比人工 review 可靠。

用法（在仓库根目录）：
  python scripts/check_ports.py hw/rtl/pulse_gen/rtl/pulse_gen.v hw/rtl/pulse_gen/dft_wrap/pulse_gen_dft.v
  # 可一次传多对，参数顺序：core1 dft1 core2 dft2 ...

退出码：0=全部一致；1=存在不一致（可用于 CI 门禁）。

注意：
  本脚本解析 ANSI 风格的 Verilog/SystemVerilog 端口声明，满足常规代码风格；
  复杂宏展开端口不做处理（这类端口本就应避免）。
"""
import re
import sys
from pathlib import Path


def strip_comments(text: str) -> str:
    text = re.sub(r"//.*", "", text)
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return text


def extract_ports(path: str):
    """返回 (模块名, {端口名: (方向, 位宽)})。"""
    text = strip_comments(Path(path).read_text(encoding="utf-8", errors="ignore"))
    # 匹配 module name #(...) (...) ; （参数列表可缺省）
    m = re.search(
        r"\bmodule\s+(\w+)\s*(?:#\s*\(.*?\)\s*)?\((.*?)\)\s*;",
        text,
        flags=re.S,
    )
    if not m:
        raise ValueError(f"无法在 {path} 中解析 module 端口列表")
    name, body = m.group(1), m.group(2)

    ports = {}
    for decl in body.split(","):
        decl = decl.strip()
        # input/output/inout [wire/reg] [位宽] 名字
        dm = re.search(
            r"\b(input|output|inout)\b\s*(?:wire|reg|logic)?\s*(\[[^\]]*\])?\s*(\w+)",
            decl,
        )
        if dm:
            ports[dm.group(3)] = (dm.group(1), dm.group(2) or "")
    return name, ports


def functional_ports(ports: dict) -> dict:
    """剔除调试端口（dbg_ / debug_ 前缀），只保留功能端口。"""
    return {
        k: v
        for k, v in ports.items()
        if not (k.startswith("dbg_") or k.startswith("debug_"))
    }


def compare(core_path: str, dft_path: str) -> bool:
    cn, cp = extract_ports(core_path)
    dn, dp = extract_ports(dft_path)
    cpf, dpf = functional_ports(cp), functional_ports(dp)

    ok = True
    only_core = set(cpf) - set(dpf)
    only_dft = set(dpf) - set(cpf)
    if only_core:
        ok = False
        print(f"[FAIL] {cn} -> {dn}：DFT 缺少功能端口 {sorted(only_core)}")
    if only_dft:
        ok = False
        print(f"[FAIL] {cn} -> {dn}：DFT 多出功能端口 {sorted(only_dft)}（调试端口应加 dbg_ 前缀）")
    for name in sorted(set(cpf) & set(dpf)):
        if cpf[name] != dpf[name]:
            ok = False
            print(f"[FAIL] {cn} -> {dn}：端口 {name} 方向/位宽不一致 core={cpf[name]} dft={dpf[name]}")
    if ok:
        print(f"[OK]   {cn} 与 {dn} 功能端口完全一致（{len(cpf)} 个，调试端口 {len(dp) - len(dpf)} 个已豁免）")
    return ok


def main():
    args = sys.argv[1:]
    if len(args) % 2 != 0 or not args:
        print(__doc__)
        sys.exit(2)
    results = []
    for i in range(0, len(args), 2):
        results.append(compare(args[i], args[i + 1]))
    sys.exit(0 if all(results) else 1)


if __name__ == "__main__":
    main()
