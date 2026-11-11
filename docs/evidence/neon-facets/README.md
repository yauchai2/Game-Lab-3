# Neon Facets M1：實際渲染與檢查

- [基線中立畫面](baseline-neutral.png)／[Lab中立畫面](neon-neutral.png)：同角色配搭、位置、鏡位與中立狀態，用`neon_enabled`在建立場景前切換。沒有拿兩段隨機AI假裝逐幀A/B。
- [格擋](neon-parry.png)／[蓄力](neon-charge.png)／[釋放](neon-release.png)：明確的事件fixture渲染，用於隔離材質和退出檢查，不是玩家按鍵連技證據。
- [30秒連續自由AI錄像](neon-demo-30s.mp4)／[全時間軸接觸圖](demo-contact.jpg)：15fps、450幀、無聲，真AI與命中規則，沒有章節重設或剪接。虛擬wall-step秒數，非硬件fps測量；接觸圖0.4fps抽樣，無法靠它判斷每個接觸瞬間。
- [總表](summary.json)、[21項Lab檢查](checks.json)、[最終verbose log](verification.log)、[錄像事件與時間軸](demo-capture.json)、[錄像引擎log](demo-render.log)。
- [53項原生回歸](regression-native/summary.json)：10 Ink頁面／37真輸入及多尺寸操作／6材質生命週期；各項保留log及報告。
- [134項規則回歸](regression-rules/summary.json)：rush、charged cannon、友善防禦、自由AI、air counter；[6項PCM音訊檢查](audio-checks.json)／[log](audio.log)。Dummy輸出驅動不等同聽過使用者喇叭。

原生結果使用Godot4.7.2 Linux Compatibility／Mesa llvmpipe。unsupported V-Sync提示保留，ERROR／SCRIPT ERROR／ObjectDB洩漏不作通過項隱藏。測試暫時產生的舊版頁面截圖及.import設定已還原，沒有覆寫歷史證據。完整功能與未完成範圍見 [runtime說明](../../NEON_FACETS_RUNTIME.zh-TW.md)。
