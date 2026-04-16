# HyRead App 自動化測試套件

## 執行環境
- 框架：[Maestro](https://maestro.mobile.dev)
- 裝置：Android 模擬器（Pixel_Tablet AVD）
- App：com.hyread.reader.v3

## 安裝 Maestro
```bash
curl -Ls "https://get.maestro.mobile.dev" | bash
```

## 執行單一測試
```bash
maestro test hyread_tests/02_login_success.yaml
```

## 執行全部測試
```bash
maestro test hyread_tests/
```

## 測試清單

| 檔案 | 測試案例 | 說明 |
|------|----------|------|
| 01_launch_app.yaml | TC-001 | App 啟動與首頁驗證 |
| 02_login_success.yaml | TC-002 | 電子書店登入成功 |
| 03_login_failure.yaml | TC-003 | 電子書店登入失敗（錯誤帳號密碼） |
| 04_login_empty_fields.yaml | TC-004 | 登入空白欄位驗證 |
| 05_bookshelf_tabs.yaml | TC-005 | 書櫃各分頁切換 |
| 06_sync.yaml | TC-006 | 同步功能 |
| 07_menu_settings.yaml | TC-007 | 選單設定頁面 |
| 08_add_library.yaml | TC-008 | 新增圖書館入口 |
| 09_go_to_store.yaml | TC-009 | 前往電子書店 |
| 10_bottom_nav_switch.yaml | TC-010 | 底部導航切換 |
| 11_edit_bookshelf.yaml | TC-011 | 編輯書櫃功能 |

## AI 找書測試套件

### 執行方式

```bash
# 執行全部 AI 找書測試
maestro test hyread_tests/ai_book_finder/

# 只執行 smoke 測試（PR 必跑）
maestro test --includeTags smoke hyread_tests/

# 只執行 AI 找書相關測試
maestro test --includeTags ai_book_finder hyread_tests/
```

### AI 找書測試清單

| 檔案 | 測試案例 | Tags | 說明 |
|------|----------|------|------|
| ai_book_finder/AIBookFinderHome.yaml | TC-AI-001 | smoke, ai_book_finder | AI 找書首頁各區塊驗證 |
| ai_book_finder/AISearchInput.yaml | TC-AI-002 | smoke, ai_book_finder | 搜尋輸入面板與 AI 建議 |
| ai_book_finder/AISearchResults.yaml | TC-AI-003 | smoke, ai_book_finder | 自然語言搜尋並取得結果 |
| ai_book_finder/AISearchNoResults.yaml | TC-AI-004 | ai_book_finder | 無搜尋結果的空結果頁 |
| ai_book_finder/AISearchFilterByLibrary.yaml | TC-AI-005 | ai_book_finder | 篩選館藏來源 |
| ai_book_finder/AISearchFilterByFormat.yaml | TC-AI-006 | ai_book_finder | 篩選書籍格式（EPUB/PDF/AUDIO）|
| ai_book_finder/AIBookDetail.yaml | TC-AI-007 | ai_book_finder | 書籍詳情頁與 AI 推薦分頁 |
| ai_book_finder/AIHotTopicsBrowse.yaml | TC-AI-008 | ai_book_finder | 熱門主題瀏覽與查看更多 |
| ai_book_finder/AISearchScopeChange.yaml | TC-AI-009 | ai_book_finder | 檢索範圍設定變更 |
| ai_book_finder/AIPromptSuggestion.yaml | TC-AI-010 | smoke, ai_book_finder | 點擊 AI 提示詞 chip 搜尋 |
| ai_book_finder/AIRecentSearches.yaml | TC-AI-011 | ai_book_finder | 近期搜尋紀錄與重搜 |
| ai_book_finder/AISearchResultAIExplanation.yaml | TC-AI-012 | ai_book_finder | 搜尋結果中 AI 推薦說明 |
| ai_book_finder/AINoResultsAddLibrary.yaml | TC-AI-013 | ai_book_finder | 無結果加入 HyRead 書店 |
| ai_book_finder/AIBookDetailBorrowInfo.yaml | TC-AI-014 | ai_book_finder | 書籍借閱資訊與借閱按鈕 |
| ai_book_finder/AIHotTopicsAllCategories.yaml | TC-AI-015 | ai_book_finder | 五大熱門主題分類全覆蓋 |

### 共用子流程

| 檔案 | 說明 |
|------|------|
| subflows/navigate_to_ai_book_finder.yaml | App 啟動 + 處理 Onboarding + 導航至 AI 找書 |

### 注意事項

- **中文輸入**：`inputText` 使用中文需確保模擬器關閉 IME（使用英文鍵盤）
- **網路依賴**：AI 提示詞建議（TC-AI-002、010）來自伺服器，測試需有網路連線
- **使用者資料**：近期搜尋（TC-AI-011）需先有搜尋紀錄，不可與其他 clearState 測試共用狀態
- **smoke 標籤**：TC-AI-001/002/003/010 為最核心流程，每次 PR 必跑

## 測試帳號
- 帳號：wesley
- 密碼：1234
