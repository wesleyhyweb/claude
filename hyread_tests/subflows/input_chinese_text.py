#!/usr/bin/env python3
"""
Helper script: use uiautomator2 to input Chinese text into the focused field.
Usage: python3 input_chinese_text.py <text>
"""
import sys
import time
import warnings
warnings.filterwarnings('ignore')

text = sys.argv[1] if len(sys.argv) > 1 else ""

import uiautomator2 as u2
d = u2.connect()

d.set_fastinput_ime(True)
time.sleep(0.3)
d.send_keys(text, clear=True)
time.sleep(0.3)
d.set_fastinput_ime(False)

print("OK: input '" + text + "'")
