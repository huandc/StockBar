#!/usr/bin/env bash
# 校验 Casks/stockbar.rb:语法、版本与 sha256 是否与 GitHub Release 产物一致。
# 用法: ./scripts/check-cask.sh
set -euo pipefail
cd "$(dirname "$0")/.."
CASK="Casks/stockbar.rb"

[[ -f "${CASK}" ]] || { echo "找不到 ${CASK}" >&2; exit 1; }
ruby -c "${CASK}" >/dev/null

VERSION=$(sed -n 's/^  version "\(.*\)"$/\1/p' "${CASK}")
SHA=$(sed -n 's/^  sha256 "\(.*\)"$/\1/p' "${CASK}")
[[ -n "${VERSION}" && -n "${SHA}" ]] || { echo "无法从 ${CASK} 解析 version/sha256" >&2; exit 1; }

URL="https://github.com/huandc/StockBar/releases/download/v${VERSION}/StockBar-${VERSION}-macOS.zip"
TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT

echo "下载 ${URL}"
curl -fsSL -o "${TMP}/app.zip" "${URL}"
ACTUAL=$(shasum -a 256 "${TMP}/app.zip" | awk '{print $1}')
if [[ "${ACTUAL}" != "${SHA}" ]]; then
  echo "sha256 不匹配:" >&2
  echo "  cask:   ${SHA}" >&2
  echo "  产物:   ${ACTUAL}" >&2
  echo "运行 ./scripts/update-cask.sh ${VERSION} 重新生成" >&2
  exit 1
fi

unzip -q -l "${TMP}/app.zip" | grep -q 'StockBar.app/Contents/MacOS/StockBar' \
  || { echo "压缩包里没有 StockBar.app/Contents/MacOS/StockBar" >&2; exit 1; }

echo "ok: stockbar ${VERSION} sha256 与产物一致"
