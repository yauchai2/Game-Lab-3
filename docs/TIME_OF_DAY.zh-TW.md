# 時段預設（企劃 D1 第一批實作）

2026-11-11。實作 [IDEAS_CATALOG.zh-TW.md](IDEAS_CATALOG.zh-TW.md) 的 D1：同一條街、同一碰撞，只換燈光與霧。**純演出，不改判定、傷害、音樂或規則。**

## 怎樣試
主選單或暫停畫面按 **N** 輪流切換：白晝（原樣，預設）→ 黃昏 → 深夜 → 霧晨。選擇保存在 options 的 `time_of_day`（0–3，非法值夾回）。戰鬥中按 N 無作用。目前沒有設定頁按鈕，也沒有畫面上的切換提示在主選單顯示（HUD notice 只在戰鬥畫面）。

## 實作
- `scripts/combat/time_of_day.gd`：四組預設（太陽色／強度、環境光、亮度、飽和度、霧）。
- `street_backdrop.gd` `set_time_of_day()`：預設 Neon 風格時只調太陽／環境強度比例、亮度、飽和度與霧（保留 Neon 調色盤）；非 Neon 時套完整預設。
- `fight_preferences.gd`：新增 `time_of_day`；`fight_session.gd`：載入、保存及 N 鍵。

## 驗證
`godot/tools/verify_time_of_day.gd`：11 項通過（預設白晝不變、深夜較暗、霧開關、索引夾限、N 只在 title／pause、四次回到白晝、跨 session 保存、非法值夾限）。四時段實機截圖：[time-of-day-grid.png](evidence/time-of-day/time-of-day-grid.png)（左上白晝、右上黃昏、左下深夜、右下霧晨；Godot 4.6.3 Linux／xvfb／llvmpipe）。

未驗證／限制：Mac 與真人觀感、深夜對比是否足夠、與 F2 減少特效的互動（本功能不依賴粒子，預期不受影響但未逐項測）。既有回歸 `verify_combat_polish.gd` 有一項「saved startup mute prevents the music player starting」失敗，已在未改動的基線重現，非本次造成；其餘既有套件未全數重跑。
