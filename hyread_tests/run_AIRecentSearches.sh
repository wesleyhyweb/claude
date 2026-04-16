#!/bin/bash
# TC-AI-011 執行腳本
# 解決 Maestro 2.x 不支援中文輸入（Android 15 限制）的問題：
# 由 Python/uiautomator2 負責導航和首次中文搜尋（建立搜尋紀錄），
# Maestro 負責驗證近期搜尋紀錄顯示及重搜流程。

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== TC-AI-011: AIRecentSearches ==="

# Step 1: 用 Python/uiautomator2 導航至 AI 找書並執行首次搜尋（建立搜尋紀錄）
echo "[Setup] Navigating to AI找書 and performing initial search to create history..."
SUBFLOWS_DIR="$SCRIPT_DIR/subflows" \
python3 - <<'PYEOF'
import sys, os
sys.path.insert(0, os.environ['SUBFLOWS_DIR'])
import ai_search_setup
import subprocess

d = ai_search_setup.connect()
ai_search_setup.launch_and_navigate(d)
ai_search_setup.search(d, '推薦適合通勤時閱讀的書')

# 截圖供除錯
subprocess.run(['adb', 'exec-out', 'screencap', '-p'],
               stdout=open('/tmp/debug_after_search.png', 'wb'))

# 等待搜尋結果
if not ai_search_setup.wait_for_results(d):
    subprocess.run(['adb', 'exec-out', 'screencap', '-p'],
                   stdout=open('/tmp/debug_no_result.png', 'wb'))
    print('ERROR: Search results (含「共」) not found', file=sys.stderr)
    sys.exit(1)
print('[Setup] OK: Search results loaded, history created')
PYEOF

echo "[Maestro] Running verification flow..."

# Step 2: 用 Maestro 驗證近期搜尋紀錄
maestro test "$SCRIPT_DIR/ai_book_finder/AIRecentSearches.yaml"

echo "=== TC-AI-011 PASSED ==="
