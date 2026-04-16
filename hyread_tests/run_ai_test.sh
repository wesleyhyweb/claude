#!/bin/bash
# 通用 AI 搜尋測試執行腳本
# 解決 Maestro 2.x 不支援中文輸入（Android 15 限制）的問題：
# 由 Python/uiautomator2 負責導航和中文搜尋，Maestro 負責驗證後續流程。
#
# 用法：./run_ai_test.sh <yaml_path> <search_query> [no_results]
#   <yaml_path>     — 要執行的 Maestro YAML 測試檔路徑
#   <search_query>  — 中文搜尋查詢字串
#   [no_results]    — 若第三個參數為 "no_results"，等待無結果頁面；否則等待搜尋結果

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

YAML_PATH="$1"
SEARCH_QUERY="$2"
EXPECT_MODE="${3:-results}"

if [ -z "$YAML_PATH" ] || [ -z "$SEARCH_QUERY" ]; then
    echo "Usage: $0 <yaml_path> <search_query> [no_results]"
    exit 1
fi

echo "=== AI 搜尋測試: $(basename "$YAML_PATH" .yaml) ==="

# Step 1: 用 Python/uiautomator2 導航至 AI 找書並執行搜尋
echo "[Setup] Navigating to AI找書 and inputting search query..."
SUBFLOWS_DIR="$SCRIPT_DIR/subflows" \
python3 - <<PYEOF
import sys, os
sys.path.insert(0, os.environ['SUBFLOWS_DIR'])
import ai_search_setup
import subprocess

query = """$SEARCH_QUERY"""
expect_mode = """$EXPECT_MODE"""

d = ai_search_setup.connect()
ai_search_setup.launch_and_navigate(d)
ai_search_setup.search(d, query)

# 截圖供除錯
subprocess.run(['adb', 'exec-out', 'screencap', '-p'],
               stdout=open('/tmp/debug_after_search.png', 'wb'))

if expect_mode == 'no_results':
    if not ai_search_setup.wait_for_no_results(d):
        subprocess.run(['adb', 'exec-out', 'screencap', '-p'],
                       stdout=open('/tmp/debug_no_noresult.png', 'wb'))
        print('ERROR: "沒找到相關書籍" not found', file=sys.stderr)
        sys.exit(1)
    print('[Setup] OK: No-results page loaded')
else:
    if not ai_search_setup.wait_for_results(d, timeout=30):
        subprocess.run(['adb', 'exec-out', 'screencap', '-p'],
                       stdout=open('/tmp/debug_no_result.png', 'wb'))
        print('ERROR: Search results (含「共」) not found', file=sys.stderr)
        sys.exit(1)
    print('[Setup] OK: Search results loaded')
PYEOF

echo "[Maestro] Running verification flow..."

# Step 2: 用 Maestro 驗證
maestro test "$YAML_PATH"

echo "=== PASSED: $(basename "$YAML_PATH" .yaml) ==="
