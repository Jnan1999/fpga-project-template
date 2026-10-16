# ADR 0008：Python 工具链由 uv 锁定（3.12 + uv.lock），脚本统一 `uv run python` 入口

- 日期：2026-10-16
- 状态：已确认（第二批落地）

## 背景
第二批要落地 check_gate.py 等 Python 检查器，需要 YAML 解析等依赖。此前 `project.yaml`
写着 `python: "3.8"`，但"用户机器上恰好有个 Python 3.x 且装了 pyyaml"不是可复现的前提——
检查器是 gate 证据链的一环，其运行环境本身也属于证据绑定（ADR 0012）的一部分。

## 决策
1. **uv 管理 Python 与依赖**：`.python-version` 锁 3.12，`pyproject.toml` 声明依赖（pyyaml），
   `uv.lock` 提交入库；`.venv/` 入 .gitignore。
2. **统一入口**：所有文档/命令/agent 定义中的 `python scripts/...`、`python host/...`
   一律改为 `uv run python ...`（uv 自动按 lock 选解释器与依赖）。
3. `project.yaml` 的 `tool_version.python` 同步为 "3.12" 并注明由 uv 锁定。
4. `.claude/settings.example.json` 同时保留 `python ...` 与 `uv run python ...` 两种
   授权形式（过渡期兼容；settings.json 为用户本地文件，由用户自行同步）。

## 理由
- 可复现：换机器/换项目成员时 `uv sync` 一键得到同一解释器+依赖，与"脚本即可移植资产"（0019）同一条证据链逻辑
- 零全局污染：不动用户系统 Python；uv 单文件安装，Windows 友好
- 依赖显式化：pyyaml 进 lock 而非"假设已装"

## 后果
- 新增：`pyproject.toml`（package=false）、`.python-version`、`uv.lock`；`.gitignore` 加 `.venv/`
- 全仓 `python xxx.py` 调用点统一为 `uv run python xxx.py`（CLAUDE.md/README/workflow/agents/commands）
- 检查器自测运行器（scripts/tests/run_tests.py）零依赖设计保持有效：uv 只负责解释器，运行器不引第三方库
