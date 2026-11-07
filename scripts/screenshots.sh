#!/usr/bin/env bash
# 用应用自身的视图离屏渲染文档图片(不是屏幕截图,不需要录屏/辅助功能权限)。
# 用法: ./scripts/screenshots.sh [输出目录]   默认 docs/images
set -euo pipefail
cd "$(dirname "$0")/.."

OUT="${1:-docs/images}"
BIN="$(swift build --show-bin-path)/StockBar"

echo "构建中…"
swift build >/dev/null

echo "渲染到 ${OUT}/"
"${BIN}" --render-docs-images "${OUT}"
