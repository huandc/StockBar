#!/usr/bin/env bash
# 运行 swift-testing 测试套件。
#
# 完整 Xcode 环境下 `swift test` 开箱可用;但只安装 Command Line Tools 时,
# Testing.framework、宏插件与 lib_TestingInterop 都不在编译器/链接器默认搜索路径中,
# 需要显式传入 -F / -load-plugin-library / rpath,否则 `import Testing`、`#expect`
# 无法解析,或测试 bundle 在 dlopen 阶段找不到 lib_TestingInterop.dylib。
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

SWIFT_BIN_DIR="$(dirname "$(xcrun --find swift 2>/dev/null || command -v swift)")"
SWIFT_TC="$(dirname "$(dirname "$SWIFT_BIN_DIR")")"
TESTING_FRAMEWORK="$SWIFT_TC/Library/Developer/Frameworks/Testing.framework"
TESTING_MACROS="$SWIFT_TC/usr/lib/swift/host/plugins/testing/libTestingMacros.dylib"
TESTING_INTEROP_DIR="$SWIFT_TC/Library/Developer/usr/lib"

if [[ -d "$TESTING_FRAMEWORK" && -f "$TESTING_MACROS" ]]; then
    FRAMEWORKS_DIR="$(dirname "$TESTING_FRAMEWORK")"
    RPATH_FLAGS=(-Xlinker -rpath -Xlinker "$FRAMEWORKS_DIR")
    if [[ -f "$TESTING_INTEROP_DIR/lib_TestingInterop.dylib" ]]; then
        RPATH_FLAGS+=(-Xlinker -rpath -Xlinker "$TESTING_INTEROP_DIR")
    fi
    exec swift test \
        -Xswiftc -F -Xswiftc "$FRAMEWORKS_DIR" \
        -Xlinker -F -Xlinker "$FRAMEWORKS_DIR" \
        "${RPATH_FLAGS[@]}" \
        -Xswiftc -load-plugin-library -Xswiftc "$TESTING_MACROS" \
        "$@"
fi

exec swift test "$@"
