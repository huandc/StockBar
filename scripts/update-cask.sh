#!/usr/bin/env bash
# 发布新版本后,把 Casks/stockbar.rb 的 version / sha256 更新到该 Release 的产物。
# 用法: ./scripts/update-cask.sh 1.0.1
set -euo pipefail
cd "$(dirname "$0")/.."
CASK="Casks/stockbar.rb"

VERSION="${1:?用法: ./scripts/update-cask.sh <version>,例如 1.0.1}"
VERSION="${VERSION#v}"

URL="https://github.com/huandc/StockBar/releases/download/v${VERSION}/StockBar-${VERSION}-macOS.zip"
TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT

echo "下载 ${URL}"
curl -fsSL -o "${TMP}/app.zip" "${URL}"
SHA=$(shasum -a 256 "${TMP}/app.zip" | awk '{print $1}')

sed -i '' "s/^  version \".*\"$/  version \"${VERSION}\"/" "${CASK}"
sed -i '' "s/^  sha256 \".*\"$/  sha256 \"${SHA}\"/" "${CASK}"

echo "已更新 ${CASK}: version=${VERSION} sha256=${SHA}"
./scripts/check-cask.sh
