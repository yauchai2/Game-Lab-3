# 抽到能力後：3D 裝備

[有聲裝備預覽](ability-equip.mp4) · [完整 Demo 自動抽取→裝備→第三局](demo-draw-equip.mp4) · [六個鏡頭](equip-frames.png)

裝備片是明示 SPEED 獎品 fixture，結果卡後經真正 viewport GUI 滑鼠按下／放開 EQUIP，然後正式 3D 裝備／套用／下一局。Demo 片是固定 1:1 邊界及 RNG seed3 的正式自動流程，沒有送按鍵；來源狀態時間分別在 capture.json／demo-capture.json。不是自然完整對局或原片播放。

每角色 `actor0`–`actor4` 的六時點是實際引擎畫面；六鏡總覽只拼接原 PNG。`references/ability-equip` 保存使用者原 4.458333 秒片、SHA 和完整 4fps contact sheet。沒有將原片水印或人物圖當 runtime 素材。

| 檢查 | 通過 | 證據 |
|---|---:|---|
| 五原選角、手腕／頭部取景、一次領取、live腰掛／移動／重置、九色／圖示、另一stage、pause／F2／skip／cancel | 113 | verification.json／verification.log |
| 真GUI抽獎、正式回合／Street Run／Demo定時接裝備、音量／設定／跨場景／清理 | 69 | flow-verification.json／flow-verification.log |
| 九核心真戰鬥效果與限額／AI門檻 | 75 | core-regression.json／log |
| 基本戰鬥 | 34 | combat-regression.json／log |
| 四角色專屬技能及永久成長 | 46 | service-regression.json／log |
| 四類警告當編譯錯誤，8個runtime入口及其新依賴 | 8 | warnings/strict.json／strict.log |
| 合計 | **345** | 最終無 ERROR／SCRIPT ERROR／退出洩漏 |

初期 `initial-framing-contact` 記錄接取超出手臂可達範圍、面部入鏡，已改手部距離／鏡頭並重驗；後來放手目標也改為真待機手腕位置。鞋鏡曾在低處遭前景遮擋，改斜上取景後逐圖檢視。`initial-strict-warnings.log` 保留新 Node3D 屬性同名／ternary 型別警告，已改名及浮點零，嚴格 runner 最終 8/8。

`initial-flow-exit.log` 保留初跑69項後兩個退出資源未釋放；後續顯式 stop/stream 解除路徑及較長混音 drain 的 verbose／最終原生退出乾淨，沒有證據把它宣稱為引擎全局修復。Movie Writer 同錄原創 PCM，再轉 AAC；audio-check.json 有非靜音峰值／RMS／零削波，沒有事後配音。

Godot4.6.3／Linux／Compatibility llvmpipe／Dummy。固定30fps匯出不代表即時GPU效能，未驗使用者 Mac／Godot4.7.2／真人手感或音效裝置。原 GLB／音訊／歷史證據保留，Web 未更新。
