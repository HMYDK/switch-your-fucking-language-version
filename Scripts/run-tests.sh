#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")/.."

# 使用 SwiftPM 可执行目标运行 core 校验。
# 这里不用 swift test：当前命令行工具链没有 XCTest/Testing 模块，
# RuntimePilotChecks 是一个无需测试框架的自包含 runner。
exec swift run RuntimePilotChecks
