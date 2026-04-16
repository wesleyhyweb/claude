#!/bin/bash
# TC-AI-014 執行腳本
# 解決 Maestro 2.x 不支援中文輸入（Android 15 限制）的問題：
# 由 Python/uiautomator2 負責導航和中文搜尋，Maestro 負責驗證後續流程。

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== TC-AI-014: AIBookDetailBorrowInfo ==="

# Step 1: 用 Python/uiautomator2 導航至 AI 找書、執行搜尋、並點入第一本書
echo "[Setup] Navigating to AI找書, inputting search query, and opening book detail..."
SUBFLOWS_DIR="$SCRIPT_DIR/subflows" \
python3 - <<'PYEOF'
import sys, os
sys.path.insert(0, os.environ['SUBFLOWS_DIR'])
import ai_search_setup
import subprocess, time

d = ai_search_setup.connect()
ai_search_setup.launch_and_navigate(d)
ai_search_setup.search(d, '歐洲歷史，推薦我小說')

# 截圖供除錯
subprocess.run(['adb', 'exec-out', 'screencap', '-p'],
               stdout=open('/tmp/debug_after_search.png', 'wb'))

# 等待搜尋結果
if not ai_search_setup.wait_for_results(d):
    subprocess.run(['adb', 'exec-out', 'screencap', '-p'],
                   stdout=open('/tmp/debug_no_result.png', 'wb'))
    print('ERROR: Search results (含「共」) not found', file=sys.stderr)
    sys.exit(1)
print('[Setup] OK: Search results loaded')

# 點入第一本書封，開啟預覽彈窗
d(resourceId='com.hyread.reader.v3:id/ai_item_cover', instance=0).click()
time.sleep(1.5)

# 點擊「查看」進入書籍詳情頁
d(text='查看').click()
time.sleep(2)

print('[Setup] OK: Book detail page opened')
PYEOF

echo "[Maestro] Running verification flow..."

# Step 2: 用 Maestro 驗證書籍詳情頁借閱資訊
maestro test "$SCRIPT_DIR/ai_book_finder/AIBookDetailBorrowInfo.yaml"

echo "=== TC-AI-014 PASSED ==="
