#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
run_tests.py —— check_ports.py 的零依赖自测运行器（不依赖 pytest）

设计原则（见本目录 README.md）：门禁脚本必须自带反例测试——
构造已知错误的输入，断言检查器必须报错（退出码非 0），
防止"门禁脚本本身失效却显示 PASS"的虚假绿灯。

用法（仓库根目录）：
  uv run python scripts/tests/run_tests.py
退出码：0=全部用例符合预期；1=存在不符合预期的用例。
"""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]  # 仓库根目录
CHECKER = ROOT / "scripts" / "check_ports.py"
CASES = ROOT / "scripts" / "tests" / "cases"


def run_checker(*args):
    """以当前解释器运行 check_ports.py，返回 (退出码, 合并输出)。

    子进程按系统区域设置编码输出中文（Windows 为 GBK），这里不指定 encoding
    即按同一区域设置解码，保证中英文都能正确还原。
    """
    proc = subprocess.run(
        [sys.executable, str(CHECKER), *[str(a) for a in args]],
        cwd=ROOT,
        capture_output=True,
        text=True,
        errors="replace",
    )
    return proc.returncode, proc.stdout + proc.stderr


def case_pulse_gen_positive():
    """正例：仓库自带的 pulse_gen core/dft 必须一致（退出 0）。"""
    rc, out = run_checker(
        "hw/rtl/pulse_gen/rtl/pulse_gen.v",
        "hw/rtl/pulse_gen/dft_wrap/pulse_gen_dft.v",
    )
    return rc == 0, f"exit={rc}，期望 0。输出：{out.strip()}"


def case_grouped_decl_mismatch():
    """反例：分组声明 `input wire a, b` 中 b vs c 不同 → 必须退出 1。"""
    rc, out = run_checker(CASES / "case2_group_core.v", CASES / "case2_group_dft.v")
    ok = rc == 1 and "FAIL" in out
    return ok, f"exit={rc}，期望 1 且输出含 FAIL。输出：{out.strip()}"


def case_width_expr_mismatch():
    """反例：位宽表达式不同（CNT_W vs W）→ 必须退出 1。"""
    rc, out = run_checker(CASES / "case3_width_core.v", CASES / "case3_width_dft.v")
    ok = rc == 1 and "FAIL" in out
    return ok, f"exit={rc}，期望 1 且输出含 FAIL。输出：{out.strip()}"


def case_direction_mismatch():
    """反例：方向不同（input vs output）→ 必须退出 1。"""
    rc, out = run_checker(CASES / "case4_dir_core.v", CASES / "case4_dir_dft.v")
    ok = rc == 1 and "FAIL" in out
    return ok, f"exit={rc}，期望 1 且输出含 FAIL。输出：{out.strip()}"


def case_unparseable_fail_closed():
    """反例：宏端口无法解析 → 必须 fail-closed 报错（退出非 0 且含报错信息），不得放行。"""
    rc, out = run_checker(CASES / "case5_macro.v", CASES / "case5_macro.v")
    ok = rc != 0 and "无法识别" in out
    return ok, f"exit={rc}，期望非 0 且输出含'无法识别'。输出：{out.strip()}"


def case_dbg_prefix_exempt():
    """正例：dft 多出的 dbg_ 前缀端口应豁免（退出 0）。"""
    rc, out = run_checker(CASES / "case6_dbg_core.v", CASES / "case6_dbg_dft.v")
    ok = rc == 0 and "OK" in out
    return ok, f"exit={rc}，期望 0 且输出含 OK。输出：{out.strip()}"


ALL_CASES = [
    ("pulse_gen 正例（仓库自带）", case_pulse_gen_positive),
    ("分组声明差异（b vs c）", case_grouped_decl_mismatch),
    ("位宽表达式不同（CNT_W vs W）", case_width_expr_mismatch),
    ("端口方向不同（input vs output）", case_direction_mismatch),
    ("宏端口 fail-closed", case_unparseable_fail_closed),
    ("dbg_ 前缀豁免正例", case_dbg_prefix_exempt),
]


def main():
    # 控制台编码兜底：无法编码的字符替换而不是崩溃（Windows GBK 控制台）
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(errors="replace")
    passed = failed = 0
    for name, fn in ALL_CASES:
        ok, detail = fn()
        tag = "PASS" if ok else "FAIL"
        if ok:
            passed += 1
        else:
            failed += 1
        print(f"[{tag}] {name}")
        if not ok:
            print(f"       {detail}")
    print()
    print("=== SUMMARY ===")
    print(f"RESULT: {'PASS' if failed == 0 else 'FAIL'}")
    print(f"CASES_TOTAL: {len(ALL_CASES)}")
    print(f"CASES_PASSED: {passed}")
    print(f"CASES_FAILED: {failed}")
    sys.exit(0 if failed == 0 else 1)


if __name__ == "__main__":
    main()
