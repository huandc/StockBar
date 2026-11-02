#!/usr/bin/env bash
# 用项目统一的 swift-format 配置格式化全部 Swift 源码。
# 用法: ./scripts/format.sh          # 原地格式化
#       ./scripts/format.sh --lint   # 只检查,不修改(CI 用)
set -euo pipefail
cd "$(dirname "$0")/.."

FORMATTER=$(xcrun --find swift-format 2>/dev/null || true)
if [[ -z "${FORMATTER}" ]]; then
  echo "未找到 swift-format:请安装完整 Xcode(16+)或 Command Line Tools 16+" >&2
  exit 1
fi

if [[ "${1:-}" == "--lint" ]]; then
  exec "${FORMATTER}" lint --strict --recursive Sources Tests
fi

"${FORMATTER}" format --in-place --recursive Sources Tests
echo "已格式化 Sources/ 与 Tests/"
