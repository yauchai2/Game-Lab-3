# 繁體中文語言

設定→Language／語言→繁體中文。English保留為預設，選擇寫入既有options.cfg，重啟後恢復；不改角色進度或存檔schema。

共1034條翻譯，涵蓋主選單／設定／雙人與教學、戰鬥HUD／提示、六個城市設施、技能／天賦／裝備／詞綴／合約／九核心、六章故事與各結局。對話採繁中粵語口吻，介面採繁體中文；角色品牌名、按鍵代碼、音樂曲名及原圖內嵌字樣保留。沒有新增配音。

TranslationServer共用catalog，原生控制項自動翻譯，Canvas繪字與文字量測走同一locale_text helper。動態數字／百分比／角色佔位符保持；先翻譯後量測，已中文的名稱不重複翻譯。資料ID／事件及simulation仍保持原值。字體補齊現有AfterhoursUIHK子集，維持Noto CJK OFL來源與授權；拉丁字體5／8／100不改。天賦FIT VIEW獨立譯為全覽，與裝備FIT區分；故事打字效果按翻譯後字數結束。

翻譯表：godot/assets/localization/zh_TW.json。tools/subset_ui_font.py現在亦讀取此檔補字。Web export include_filter含JSON；僅產生本機暫存PCK測試，未部署網站。

## 最終驗證

[264項通過／0失敗](summary.json)：新語言規則18、原生8、strict23、英文整合70／Ink10／城市22、戰鬥34／九核心75、PCK4。新增規則包含全劇情／各結局逐句catalog覆蓋、全部繁中字形、格式／百分比／角色替換、偏好保存及中英切換。原生測試以真點擊打開選單、用PopupMenu的index_pressed語意啟動選項，不宣稱作業系統鍵盤路由驗收；後期頁面用明示進度／資金fixture。首次失敗另存initial-attempts，包含preload/autoload順序、popup測試路由及首次退出資源記錄，未混作通過。最終accepted logs無ERROR／SCRIPT ERROR，歷史evidence未覆寫。

PCK檢查在/tmp啟動、只載入匯出包，確認raw JSON、autoload翻譯、動態數字與繁中文字形；不是瀏覽器執行證明。Linux Godot4.7.2 Compatibility／Mesa llvmpipe／Dummy音訊，未驗Mac／硬件FPS／實聽。

[主選單](title-zh.png) · [設定](settings-zh.png) · [故事](story-zh.png) · [技能](station-0-zh.png) · [核心／裝備](station-3-zh.png) · [商店](station-4-zh.png) · [天賦](talent-zh.png) · [暫停](pause-zh.png) · [切回英文](title-en.png)

PNG為原生1280×720、未後製。可重跑godot/tools/verify_traditional_chinese.gd及verify_traditional_chinese_native.gd；後者需原生顯示環境。
