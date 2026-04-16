# Maestro YAML 測試腳本 Best Practices 實戰指南

> **對象**：正在使用 Claude Code Computer Use 自動產生 Maestro 測試腳本的同仁
>
> **目標**：確保產出的腳本可維護、可擴展、可進 CI/CD，不會變成一次性 demo

---

## 一、專案結構：從第一天就做對

Maestro 官方推薦**依功能分目錄**的結構。這是你應該馬上建立的骨架：

```
.maestro/
├── config.yaml              # 全域設定（指定要跑哪些目錄）
├── auth/                    # 認證相關
│   ├── Login.yaml
│   ├── Logout.yaml
│   └── Onboarding.yaml
├── core/                    # 核心業務流程
│   ├── CreateOrder.yaml
│   ├── ViewDashboard.yaml
│   └── EditProfile.yaml
├── settings/                # 設定相關
│   └── ChangeLanguage.yaml
├── subflows/                # 可重用的子流程（不會被獨立執行）
│   ├── login.yaml           # 登入子流程
│   ├── navigate_to_home.yaml
│   └── clear_and_restart.yaml
└── data/                    # 測試資料（如果需要）
    └── test_accounts.yaml
```

`config.yaml` 要明確指定哪些目錄的 Flow 會被執行：

```yaml
# config.yaml
flows:
  - auth/*
  - core/*
  - settings/*
# 注意：subflows/ 不列入，因為它只是被其他 Flow 引用的子流程
```

### 為什麼這麼重要？

Maestro 預設只跑**根目錄**下的 `.yaml` 檔案，子資料夾中的檔案不會自動被執行。如果你把所有檔案平鋪在根目錄，很快就會變成一團混亂——找不到檔案、不知道哪些是獨立測試、哪些是共用子流程。

---

## 二、命名規範：讓檔名自己說話

### 檔案命名

```
✅ 好的命名
Login.yaml
LoginWithInvalidPassword.yaml
CheckoutWithCreditCard.yaml
SearchAndFilterByCategory.yaml

❌ 壞的命名
test1.yaml
flow_a.yaml
new_test.yaml
mytest_final_v2.yaml
```

**規則**：用 PascalCase，名稱要能描述「這個測試驗證什麼場景」。看到檔名就知道測試內容，不需要打開檔案。

### 子流程（Subflows）命名

子流程用 snake_case，加上動作描述：

```
subflows/
├── login_as_standard_user.yaml
├── login_as_admin.yaml
├── navigate_to_settings.yaml
└── clear_state_and_restart.yaml
```

---

## 三、Flow 撰寫的七條鐵律

### 鐵律 1：一個 Flow = 一個測試場景

**絕對不要**把整個 App 的測試寫成一個超長 Flow。

```yaml
# ❌ 錯誤：一個 Flow 測試所有東西
appId: com.example.app
---
- launchApp
- tapOn: "登入"
# ... 50 行登入流程 ...
- tapOn: "首頁"
# ... 30 行首頁驗證 ...
- tapOn: "設定"
# ... 40 行設定驗證 ...
```

```yaml
# ✅ 正確：拆成獨立的 Flow，引用共用子流程
# auth/Login.yaml
appId: com.example.app
---
- launchApp
- runFlow: ../subflows/login_as_standard_user.yaml
- assertVisible: "首頁"
```

**原因**：任何一步失敗就會中斷整個測試，你不會知道後面的功能是否正常；無法平行執行；測試報告只會顯示一個結果。

### 鐵律 2：善用 subflow + 參數化，消滅重複

登入是最典型的共用流程。寫一次，到處引用：

```yaml
# subflows/login.yaml
appId: com.example.app
env:
  USERNAME: ${USERNAME || "default_test_user"}
  PASSWORD: ${PASSWORD || "Test1234!"}
---
- launchApp:
    clearState: true
- tapOn: "帳號"
- inputText: ${USERNAME}
- tapOn: "密碼"
- inputText: ${PASSWORD}
- tapOn: "登入"
- assertVisible: "首頁"
```

在主 Flow 中引用，可傳入不同角色：

```yaml
# core/AdminDashboard.yaml
appId: com.example.app
---
- runFlow:
    file: ../subflows/login.yaml
    env:
      USERNAME: "admin_user"
      PASSWORD: "Admin1234!"
- assertVisible: "管理後台"
- tapOn: "用戶管理"
- assertVisible: "用戶列表"
```

### 鐵律 3：優先用文字和 testID 定位，避免座標

```yaml
# ✅ 最佳：用可見文字（最直覺，但多語系要注意）
- tapOn: "登入"

# ✅ 推薦：用 testID / accessibilityIdentifier（最穩定）
- tapOn:
    id: "login-button"

# ✅ 也可以：用 accessibility label
- tapOn:
    label: "登入按鈕"

# ⚠️ 備用：當有多個相同文字時，用 index
- tapOn:
    text: "確認"
    index: 0       # 第一個匹配的元素

# ❌ 盡量避免：座標定位（螢幕尺寸不同就壞了）
- tapOn:
    point: "50%,80%"
```

**給開發同仁的請求**：在 App 的關鍵 UI 元素上加 `testID`（React Native）或 `accessibilityIdentifier`（iOS）/ `content-desc`（Android）。這是測試穩定性的最大保障。

### 鐵律 4：讓 Maestro 處理等待，不要手動 sleep

```yaml
# ❌ 錯誤：硬性等待
- tapOn: "載入資料"
- swipe:          # 用 swipe 來「等」？不要。
    direction: "DOWN"
    duration: 3000

# ✅ 正確：Maestro 自動等待元素出現
- tapOn: "載入資料"
- assertVisible:
    text: "資料已載入"
    timeout: 10000    # 最多等 10 秒，通常不需要設定
```

Maestro 內建智慧等待機制——它會自動重試直到元素出現。只有在網路請求特別慢的場景才需要手動設 timeout。

### 鐵律 5：每個 Flow 開頭都要有 clearState

```yaml
appId: com.example.app
---
- launchApp:
    clearState: true    # 清除 App 資料，確保乾淨狀態
```

這確保每個測試都從乾淨狀態開始，不會因為前一個測試留下的登入狀態或快取而產生不可預測的結果。

### 鐵律 6：用 Tags 區分煙霧測試和完整測試

```yaml
# auth/Login.yaml
appId: com.example.app
tags:
  - smoke       # 標記為煙霧測試（每次 PR 都跑）
  - auth        # 標記功能類別
---
- launchApp:
    clearState: true
- runFlow: ../subflows/login_as_standard_user.yaml
- assertVisible: "首頁"
```

執行時可以依 tag 篩選：

```bash
# PR 觸發：只跑煙霧測試（快，3-5 分鐘）
maestro test --includeTags smoke .maestro/

# 每日排程：跑完整測試（慢，20-30 分鐘）
maestro test .maestro/

# 只跑特定功能
maestro test --includeTags auth .maestro/
```

### 鐵律 7：善用條件式處理動態 UI

App 中經常有彈窗、更新提示等不確定是否出現的元素：

```yaml
# 如果出現「有新版本」彈窗，就關掉它
- runFlow:
    when:
      visible: "稍後再說"
    commands:
      - tapOn: "稍後再說"

# 繼續正常流程
- tapOn: "開始使用"
```

---

## 四、使用 Claude Code Computer Use 產生腳本的注意事項

Claude Code 透過 Computer Use 觀察模擬器螢幕來產生 Maestro YAML，這非常強大但有幾個要注意的地方：

### 產生後一定要 Review

AI 產生的腳本傾向使用**可見文字**來定位元素（因為它看到的就是畫面）。這在單一語系下沒問題，但如果 App 有多語系支援，應該把關鍵定位改成 `id` 或 `label`。

### 引導 Claude 遵循你的規範

在讓 Claude Code 產生測試時，給它明確的指令：

```
請為我們的 App 登入流程產生 Maestro YAML 測試腳本。
要求：
1. 遵循我們的專案結構，登入子流程放在 subflows/login.yaml
2. 主測試放在 auth/Login.yaml，引用 subflow
3. 用 testID（id: "xxx"）定位元素，不要用座標
4. 開頭要 clearState: true
5. 加上 tags: [smoke, auth]
6. 用參數化處理帳號密碼，不要寫死
```

### 截圖驗證

Claude Code 產生腳本後，請它用 Computer Use 實際跑一次驗證：

```
請用 maestro test auth/Login.yaml 跑一次這個測試，
截圖給我看每一步的結果。如果有失敗就修正腳本。
```

---

## 五、CI/CD 整合 Cheat Sheet

### GitHub Actions 範例

```yaml
name: Maestro E2E Tests
on:
  pull_request:
    branches: [main]

jobs:
  smoke-test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Maestro
        run: curl -fsSL "https://get.maestro.mobile.dev" | bash
      
      - name: Build APK
        run: ./gradlew assembleDebug
      
      - name: Start Android Emulator
        uses: reactivecircus/android-emulator-runner@v2
        with:
          api-level: 34
          script: |
            adb install app/build/outputs/apk/debug/app-debug.apk
            maestro test --includeTags smoke --format junit \
              --output report.xml .maestro/
      
      - name: Upload Test Report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: maestro-report
          path: report.xml
```

### 測試報告

```bash
# 產生 JUnit XML 報告（CI 整合用）
maestro test --format junit --output report.xml .maestro/

# 產生 HTML 報告（人類閱讀用）
maestro test --format html --output report.html .maestro/

# AI 分析測試結果（實驗性功能）
maestro test --analyze .maestro/
```

---

## 六、常見踩坑與解法速查

| 問題 | 原因 | 解法 |
|------|------|------|
| 測試有時過有時不過（flaky） | 通常是等待不足或動畫干擾 | 用 `assertVisible` 搭配合理 timeout；在開發者選項中關閉動畫 |
| 找不到元素 | 元素被鍵盤遮住、還沒渲染、或在可視範圍外 | 用 `scrollUntilVisible` 或先 `hideKeyboard` |
| 中文輸入法干擾 | Maestro 的 `inputText` 可能被輸入法攔截 | 確保模擬器使用英文鍵盤；中文輸入可用 `clipboard` 方式 |
| 同一個文字出現多次 | `tapOn: "確認"` 匹配到多個元素 | 用 `index: 0` 指定第幾個，或改用 `id` 定位 |
| subflow 路徑找不到 | 路徑是相對於當前 Flow 檔案的位置 | 用 `../subflows/xxx.yaml` 確認相對路徑正確 |
| config.yaml 沒生效 | 放錯位置或格式錯誤 | `config.yaml` 必須放在 `.maestro/` 根目錄 |

---

## 七、進階技巧（第二階段再導入）

### JavaScript 擴展

當純 YAML 無法表達的邏輯，可以嵌入 JavaScript：

```yaml
- runScript: |
    if (flow.env.USER_ROLE === 'admin') {
      flow.tapOn("管理後台");
    } else {
      flow.tapOn("一般首頁");
    }
```

### MaestroGPT 輔助

Maestro 內建 AI 助手 MaestroGPT，可以在 Maestro Studio 中使用。它能根據你的 App 畫面建議測試指令、找出邊界案例。搭配 Claude Code Computer Use，形成雙 AI 輔助的測試產生流程。

### Maestro MCP Server

Maestro 提供 MCP Server，可以讓 AI 工具（Cursor、VS Code 等）直接讀取你的測試結構、理解 Flow 之間的關係、並建議改善方案。這跟你們正在研究的 MCP 架構完全契合。

---

## 快速行動清單

- [ ] 建立 `.maestro/` 目錄結構（含 config.yaml、subflows/）
- [ ] 把現有腳本依功能分類放入對應目錄
- [ ] 抽取共用的登入流程為 `subflows/login.yaml` 並參數化
- [ ] 為每個 Flow 加上 `tags`（至少區分 smoke / regression）
- [ ] 確認所有 Flow 開頭都有 `clearState: true`
- [ ] 把關鍵元素定位從文字改為 testID（需要開發配合）
- [ ] 設定 `yamllint` 做 YAML 語法檢查
- [ ] 本機跑通全部測試後，設定 GitHub Actions 自動化
