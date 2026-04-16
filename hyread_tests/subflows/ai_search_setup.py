#!/usr/bin/env python3
"""
共用模組：uiautomator2 導航至 AI 找書並執行中文搜尋。
供各個 run_*.sh 腳本呼叫，解決 Maestro 2.x 不支援中文輸入（Android 15 限制）的問題。
"""

import warnings
warnings.filterwarnings('ignore')

import subprocess
import sys
import time

import uiautomator2 as u2


def connect():
    """連線到裝置，回傳 uiautomator2 Device 物件。"""
    return u2.connect()


def launch_and_navigate(d):
    """
    強制停止並重啟 App，等待書櫃出現，
    處理 Onboarding（下一頁×2→關閉），然後切換至 AI 找書分頁。
    """
    # 喚醒螢幕並回到主畫面（防止鎖屏或其他遮擋）
    subprocess.run(['adb', 'shell', 'input', 'keyevent', 'KEYCODE_WAKEUP'], capture_output=True)
    time.sleep(0.5)
    subprocess.run(['adb', 'shell', 'input', 'keyevent', 'KEYCODE_HOME'], capture_output=True)
    time.sleep(0.5)

    # 強制停止並重啟 App
    subprocess.run(
        ['adb', 'shell', 'am', 'force-stop', 'com.hyread.reader.v3'],
        capture_output=True
    )
    time.sleep(2)
    subprocess.run(
        ['adb', 'shell', 'am', 'start', '-n',
         'com.hyread.reader.v3/com.hyread.hyread3.StoreAssetBoxActivity'],
        capture_output=True
    )

    # 等待 App 完全載入（最多 30 秒，冷啟動需要較長時間）
    print('[Setup] Waiting for app to load...')
    if not d(text='書櫃').exists(timeout=30):
        subprocess.run(
            ['adb', 'exec-out', 'screencap', '-p'],
            stdout=open('/tmp/debug_launch.png', 'wb')
        )
        print('ERROR: 書櫃 not found after launch', file=sys.stderr)
        sys.exit(1)

    # 處理 Onboarding（如果出現）
    if d(text='下一頁').exists(timeout=3):
        d(text='下一頁').click()
        time.sleep(0.5)
        d(text='下一頁').click()
        time.sleep(0.5)
        d(text='關閉').click()
        time.sleep(1)

    # 切換至 AI 找書
    d(text='AI找書').click()
    time.sleep(2)

    # 確認進入 AI 找書頁
    if not d(text='您想找什麼書呢？').exists(timeout=5):
        print('ERROR: AI找書 page not loaded', file=sys.stderr)
        sys.exit(1)


def search(d, query):
    """
    點擊搜尋列，使用 FastInput IME 輸入中文查詢字串，然後按 Enter 送出。
    """
    # 點擊搜尋欄
    d(resourceId='com.hyread.reader.v3:id/search_src_text').click()
    time.sleep(0.5)

    # 使用 FastInput IME 輸入中文（繞過 Android 15 broadcast 限制）
    d.set_fastinput_ime(True)
    time.sleep(0.5)
    d.send_keys(query, clear=True)
    time.sleep(0.5)
    d.set_fastinput_ime(False)
    time.sleep(0.5)

    # 送出搜尋（按 Enter）
    d.press('enter')
    time.sleep(2)


def wait_for_results(d, timeout=15):
    """
    等待搜尋結果出現（畫面上含「共」字的文字）。
    回傳 True 表示找到，False 表示逾時。
    """
    print('[Setup] Waiting for search results...')
    deadline = time.time() + timeout
    while time.time() < deadline:
        # 找任何含「共」字的元素（如「共 200 本」）
        elems = d(textContains='共')
        if elems.exists():
            return True
        time.sleep(0.5)
    return False


def wait_for_no_results(d, timeout=15):
    """
    等待無結果提示（「沒找到相關書籍」）出現。
    回傳 True 表示找到，False 表示逾時。
    """
    print('[Setup] Waiting for no-results page...')
    return d(text='沒找到相關書籍').exists(timeout=timeout)
