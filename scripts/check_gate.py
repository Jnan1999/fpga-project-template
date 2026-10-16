#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_gate.py —— 阶段门禁契约检查器（CI 可调用）

数据源：workflow/gates.yaml（验收标准，修改须经用户评审）+ project.yaml（流程状态）。

用法（仓库根目录）：
  uv run python scripts/check_gate.py status          # 总览：所有 gate 的机器检查结果
  uv run python scripts/check_gate.py entry P3        # 检查进入 P3 的前置条件
  uv run python scripts/check_gate.py exit  P3        # 检查 P3 出口 gate（也可直接给 gate 名：exit G3）
  加 --slow 执行慢检查（evidence 带 run 的项会真正调用 Vivado 等工具重跑）

结果三值（fail-closed）：
  PASS    机器可查项全部通过（若含 manual 项则永远到不了 PASS，需用户确认）
  FAIL    有机器检查明确不通过
  UNKNOWN 证据缺失/歧义/慢检查未执行/仅剩人工项 —— 不放行，也不是失败
退出码：0=PASS，1=FAIL，2=UNKNOWN（含用法错误）。

边界：本脚本只回答"契约项是否被满足"，不能证明契约本身正确、不能代替人工 gate 评审
（信任模型见 workflow/README.md）。脚本不修改 project.yaml——gate 确认后由用户授权更新。
"""
import argparse
import glob
import re
import subprocess
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
GATES_YAML = ROOT / "workflow" / "gates.yaml"
PROJECT_YAML = ROOT / "project.yaml"
CHECK_PORTS = ROOT / "scripts" / "check_ports.py"

PASS, FAIL, UNKNOWN = "PASS", "FAIL", "UNKNOWN"

# 同一次调用内相同的 run 命令只执行一次（如 elab_clean / methodology_clean 共用 check_elab.tcl）
_EXECUTED_RUNS = set()

# file_filled 的默认占位符模式：命中即视为"未填写"
DEFAULT_FORBID = [r"<PROJECT_NAME>", r"<BOARD_NAME>", r"<MOD>", r"待填写"]


def load_yaml(path):
    with open(path, encoding="utf-8") as f:
        return yaml.safe_load(f)


def git_head():
    """当前 git 短 hash；失败返回 None（调用方按 UNKNOWN 处理）。"""
    try:
        proc = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            cwd=ROOT, capture_output=True, text=True,
        )
        return proc.stdout.strip() if proc.returncode == 0 else None
    except OSError:
        return None


def parse_summary(path):
    """解析日志末尾 === SUMMARY === 段的 KEY: VALUE 对；找不到返回 None。"""
    try:
        text = Path(path).read_text(encoding="utf-8", errors="replace")
    except OSError:
        return None
    idx = text.rfind("=== SUMMARY ===")
    if idx < 0:
        return None
    fields = {}
    for line in text[idx:].splitlines()[1:]:
        if line.startswith("===") and "SUMMARY" not in line:
            break
        m = re.match(r"^([A-Z][A-Z0-9_]*):\s*(.*)$", line.strip())
        if m:
            fields[m.group(1)] = m.group(2).strip()
    return fields


# ---------------------------------------------------------------- 各检查类型

def check_file_exists(c):
    p = ROOT / c["path"]
    if p.exists():
        return PASS, f"{c['path']} 存在"
    return FAIL, f"{c['path']} 不存在"


def check_file_filled(c):
    p = ROOT / c["path"]
    if not p.exists():
        return FAIL, f"{c['path']} 不存在"
    text = p.read_text(encoding="utf-8", errors="replace")
    min_bytes = c.get("min_bytes", 64)
    if len(text.encode("utf-8")) < min_bytes:
        return FAIL, f"{c['path']} 内容不足 {min_bytes} 字节，疑似未填写"
    for pat in c.get("forbid_patterns", DEFAULT_FORBID):
        if re.search(pat, text):
            return FAIL, f"{c['path']} 仍含占位符/待填写标记：{pat}"
    return PASS, f"{c['path']} 已填写（{len(text)} 字符）"


def yaml_dotted(data, dotted):
    cur = data
    for part in dotted.split("."):
        if not isinstance(cur, dict) or part not in cur:
            return None, False
        cur = cur[part]
    return cur, True


def check_yaml_value(c):
    data = load_yaml(ROOT / c["file"])
    val, found = yaml_dotted(data, c["key"])
    if not found:
        return UNKNOWN, f"{c['file']} 中不存在键 {c['key']}"
    if str(val) == str(c["equals"]):
        return PASS, f"{c['key']} == {c['equals']}"
    return FAIL, f"{c['key']} == {val!r}，期望 {c['equals']!r}"


def check_gate_done(c, project):
    phase = c["phase"]
    status = (project.get("phases", {}).get(phase) or {}).get("status")
    if status == "done":
        return PASS, f"{phase} status=done"
    return FAIL, f"{phase} status={status!r}，期望 done（gate 确认后由用户授权更新）"


def check_modules_ports(c, project):
    modules = project.get("modules") or {}
    targets = [(name, m) for name, m in modules.items()
               if (m or {}).get("dft_mode") == "three_piece"]
    if not targets:
        return UNKNOWN, "project.yaml 中无 dft_mode=three_piece 的注册模块"
    fails, details = 0, []
    for name, m in targets:
        rtl_dir = (m or {}).get("rtl") or f"hw/rtl/{name}/"
        core = ROOT / rtl_dir / "rtl" / f"{name}.v"
        dft = ROOT / rtl_dir / "dft_wrap" / f"{name}_dft.v"
        if not core.exists() or not dft.exists():
            fails += 1
            details.append(f"{name}: core/dft 文件缺失（{core} / {dft}）")
            continue
        proc = subprocess.run(
            [sys.executable, str(CHECK_PORTS), str(core), str(dft)],
            cwd=ROOT, capture_output=True, text=True, errors="replace",
        )
        if proc.returncode != 0:
            fails += 1
            first = (proc.stdout + proc.stderr).strip().splitlines()[:2]
            details.append(f"{name}: 端口不一致（{'; '.join(first)}）")
        else:
            details.append(f"{name}: OK")
    if fails:
        return FAIL, f"{fails}/{len(targets)} 模块端口不一致：" + "；".join(details)
    return PASS, f"{len(targets)} 个 three_piece 模块端口全部一致"


def check_interfaces_frozen(c, project):
    interfaces = project.get("interfaces") or []
    min_count = c.get("min_count", 0)
    if len(interfaces) < min_count:
        return FAIL, f"interfaces 仅 {len(interfaces)} 条，少于要求的 {min_count} 条"
    unfrozen = [i.get("name", "?") for i in interfaces if not i.get("frozen")]
    if unfrozen:
        return FAIL, f"未冻结接口：{', '.join(unfrozen)}"
    return PASS, f"{len(interfaces)} 条接口全部 frozen"


def check_modules_field_filled(c, project):
    field = c["field"]
    modules = project.get("modules") or {}
    targets = [(n, m) for n, m in modules.items()
               if (m or {}).get("status") != "example"]
    if not targets:
        return UNKNOWN, "无正式注册模块（全是 example）"
    bad = []
    for name, m in targets:
        val = (m or {}).get(field)
        if not val:
            bad.append(f"{name}: {field} 为空")
        elif c.get("file_must_exist") and not (ROOT / str(val)).exists():
            bad.append(f"{name}: {field} 指向的文件不存在（{val}）")
    if bad:
        return FAIL, "；".join(bad)
    return PASS, f"{len(targets)} 个模块的 {field} 均已填写"


def check_evidence(c, slow_enabled):
    """证据核对：glob 定位最新日志 → 绑定 git hash → 核对 SUMMARY 字段。

    多份匹配时取最新一份并显式打印文件名；bind_git_hash 保证证据对应当前源码，
    防止把过期/并行批次的 PASS 当作现在的结果（ADR 0012/0020）。
    """
    if c.get("run"):
        if not slow_enabled:
            return UNKNOWN, f"慢检查未执行（重跑命令：{c['run']}；加 --slow 执行）"
        if c["run"] not in _EXECUTED_RUNS:
            proc = subprocess.run(c["run"], cwd=ROOT, shell=True)
            _EXECUTED_RUNS.add(c["run"])
            if proc.returncode != 0:
                return UNKNOWN, f"重跑命令退出码 {proc.returncode}：{c['run']}（工具未跑完，不能判证据）"

    matches = sorted(glob.glob(str(ROOT / c["glob"])),
                     key=lambda p: Path(p).stat().st_mtime)
    if not matches:
        return UNKNOWN, f"无匹配证据：{c['glob']}（先运行对应工具产生日志）"
    newest = matches[-1]
    fields = parse_summary(newest)
    if fields is None:
        return UNKNOWN, f"{Path(newest).name} 缺少 === SUMMARY === 段，无法机读核对"

    if c.get("bind_git_hash"):
        head = git_head()
        ev = fields.get("GIT_HASH")
        if head is None:
            return UNKNOWN, "无法获取 git hash（非 git 仓库或 git 不可用）"
        if not ev:
            return UNKNOWN, f"{Path(newest).name} 的 SUMMARY 缺少 GIT_HASH 字段，无法绑定源码版本"
        if ev != head:
            return UNKNOWN, f"证据 git hash（{ev}）≠ 当前 HEAD（{head}），证据可能已过期，需重跑"

    for key, expect in (c.get("require") or {}).items():
        actual = fields.get(key)
        if actual is None:
            return UNKNOWN, f"{Path(newest).name} 的 SUMMARY 缺少必需字段 {key}"
        if isinstance(expect, dict):  # {min: x} / {max: y}
            try:
                num = float(actual)
            except ValueError:
                return UNKNOWN, f"字段 {key} 值 {actual!r} 不是数值，无法核对阈值"
            if "min" in expect and num < float(expect["min"]):
                return FAIL, f"{key}={num} < 要求的最小值 {expect['min']}（{Path(newest).name}）"
            if "max" in expect and num > float(expect["max"]):
                return FAIL, f"{key}={num} > 要求的最大值 {expect['max']}（{Path(newest).name}）"
        elif actual != str(expect):
            return FAIL, f"{key}={actual!r} ≠ 期望 {expect!r}（{Path(newest).name}）"
    return PASS, f"证据 {Path(newest).name} 字段核对通过"


def check_manual(c):
    return UNKNOWN, f"人工确认项：{c['question']}"


CHECKERS = {
    "file_exists": lambda c, proj, slow: check_file_exists(c),
    "file_filled": lambda c, proj, slow: check_file_filled(c),
    "yaml_value": lambda c, proj, slow: check_yaml_value(c),
    "gate_done": lambda c, proj, slow: check_gate_done(c, proj),
    "modules_ports_check": lambda c, proj, slow: check_modules_ports(c, proj),
    "interfaces_all_frozen": lambda c, proj, slow: check_interfaces_frozen(c, proj),
    "modules_field_filled": lambda c, proj, slow: check_modules_field_filled(c, proj),
    "evidence": lambda c, proj, slow: check_evidence(c, slow),
    "manual": lambda c, proj, slow: check_manual(c),
}


def run_checks(checks, project, slow_enabled):
    """返回 (总体结果, [(id, status, detail)])。总体：FAIL > UNKNOWN > PASS。"""
    results, overall = [], PASS
    for c in checks:
        ctype = c.get("type")
        checker = CHECKERS.get(ctype)
        if checker is None:
            status, detail = UNKNOWN, f"未知检查类型 {ctype!r}（gates.yaml 契约错误或检查器过旧）"
        else:
            try:
                status, detail = checker(c, project, slow_enabled)
            except Exception as e:  # fail-closed：检查器自身异常不放行
                status, detail = UNKNOWN, f"检查器执行异常：{e!r}"
        results.append((c.get("id", ctype), status, detail))
        if status == FAIL:
            overall = FAIL
        elif status == UNKNOWN and overall != FAIL:
            overall = UNKNOWN
    return overall, results


def print_report(title, overall, results):
    print(f"--- {title} ---")
    for cid, status, detail in results:
        print(f"[{status:7s}] {cid}: {detail}")
    counts = {s: sum(1 for _, st, _ in results if st == s) for s in (PASS, FAIL, UNKNOWN)}
    print()
    print("=== SUMMARY ===")
    print(f"RESULT: {overall}")
    print(f"CHECKS_TOTAL: {len(results)}")
    print(f"CHECKS_PASS: {counts[PASS]}")
    print(f"CHECKS_FAIL: {counts[FAIL]}")
    print(f"CHECKS_UNKNOWN: {counts[UNKNOWN]}")
    print("===============")
    if overall == UNKNOWN:
        print("提示：UNKNOWN 不是失败——补齐证据/加 --slow 执行慢检查/人工确认 manual 项后重查。")


def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(errors="replace")
    ap = argparse.ArgumentParser(description="阶段门禁契约检查器（数据源 workflow/gates.yaml）")
    ap.add_argument("mode", choices=["status", "entry", "exit"])
    ap.add_argument("target", nargs="?", default=None,
                    help="阶段名（P0..P6）或 gate 名（G1/G2/P2_EXIT/G3/P4_EXIT/P5_EXIT/G4）")
    ap.add_argument("--slow", action="store_true", help="执行慢检查（会真正调用 Vivado 等工具）")
    args = ap.parse_args()

    gates_doc = load_yaml(GATES_YAML)
    project = load_yaml(PROJECT_YAML)
    phases = gates_doc.get("phases") or {}
    gates = gates_doc.get("gates") or {}

    if args.mode == "status":
        print(f"当前阶段：{project.get('current_phase')}"
              f"（phases: " + ", ".join(f"{p}={ (v or {}).get('status') }" for p, v in (project.get('phases') or {}).items()) + "）\n")
        worst = PASS
        for gid, gate in gates.items():
            overall, results = run_checks(gate.get("checks") or [], project, args.slow)
            fails = sum(1 for _, s, _ in results if s == FAIL)
            unknowns = sum(1 for _, s, _ in results if s == UNKNOWN)
            print(f"[{overall:7s}] {gid} ({gate.get('name','')}): "
                  f"{len(results)} 项，FAIL={fails}，UNKNOWN={unknowns}")
            if overall == FAIL:
                worst = FAIL
            elif overall == UNKNOWN and worst != FAIL:
                worst = UNKNOWN
        print("\n=== SUMMARY ===")
        print(f"RESULT: {worst}")
        print(f"GATES_TOTAL: {len(gates)}")
        print("===============")
        print("提示：status 是总览；单项明细用 exit <阶段或gate名> 查看。")
        sys.exit({PASS: 0, FAIL: 1, UNKNOWN: 2}[worst])

    if not args.target:
        print(__doc__)
        sys.exit(2)
    target = args.target.upper()

    if args.mode == "entry":
        if target not in phases:
            print(f"未知阶段 {target!r}；可选：{', '.join(phases)}")
            sys.exit(2)
        checks = phases[target].get("entry") or []
        if not checks:
            print(f"{target} 无入口前置条件。")
            sys.exit(0)
        overall, results = run_checks(checks, project, args.slow)
        print_report(f"{target} 入口条件", overall, results)
        sys.exit({PASS: 0, FAIL: 1, UNKNOWN: 2}[overall])

    # exit：target 可以是阶段名（取其 exit_gate）或 gate 名
    gid = target if target in gates else (phases.get(target) or {}).get("exit_gate")
    if gid not in gates:
        print(f"未知阶段/gate {args.target!r}；可选 gate：{', '.join(gates)}")
        sys.exit(2)
    gate = gates[gid]
    overall, results = run_checks(gate.get("checks") or [], project, args.slow)
    print_report(f"exit {target} → gate {gid}（{gate.get('name','')}）", overall, results)
    sys.exit({PASS: 0, FAIL: 1, UNKNOWN: 2}[overall])


if __name__ == "__main__":
    main()
