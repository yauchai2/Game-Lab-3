# 九核心與 Demo 自動抽獎

[九種核心原生總覽](pool-overview.png) · [Demo 有聲預覽](demo-auto-draw.mp4) · [ECO 戰鬥 HUD](eco-combat-hud.png)

`*-result.png`／`*-reels.png` 為逐個指定 catalog entry 的引擎 fixture，真正 3D 膠囊、原機殼及獨立輪盤／GUI 渲染，非隨機掉落機率證明。`pool-overview.png` 只拼接九張未加工的原生結果畫面。

Demo 影片設第二回合 1:1 邊界，指定 RNG seed 3 展示新增 FURY 核心；沒有直接塞獎品，也沒有送滑鼠／鍵盤事件，正式 director 自己等待、roll、展示、claim，再進第三回合開場。`demo-capture.json` 保存狀態轉換及引擎幀時間；Movie Writer 同錄真聲畫，MP4 用 nearest 放大 1280×720／AAC，沒有事後配音。音訊量測在 `audio-check.json`。

| 檢查 | 通過 | 證據 |
|---|---:|---|
| 能力規則／全九種可達與一次領取／四角色 modifier／成本／回血邊界／AI | 75 | core-rules.json、core-rules.log |
| 正式回合／真 GUI 輸入／Demo 3秒與3.5秒等待／暫停／F2／跨場景／清理 | 67 | verification.json、verification.log |
| 九種輪盤與膠囊圖案／顏色／結果及 active-core HUD | 19 | core-visuals.json、core-visuals.log |
| 原65骨蒙面NPC／Tripo機殼／窗口及活動零件回歸 | 22 | model-verification.json、model-verification.log |
| 基本戰鬥回歸 | 34 | combat-regression.json、combat-regression.log |
| 四角色／專屬技能／永久成長回歸 | 46 | service-regression.json、service-regression.log |
| 合計 | **263** | 最終日誌無 ERROR／SCRIPT ERROR／退出洩漏 |

初次新增規則測試沒有扣除正式 Rush 的開場 60 能量，造成 FLOW 六項斷言錯誤；保留 `initial-fixture-energy.log`，改為 fixture 明確起始零能量後重跑 75/75。沒有因測試而修改原遊戲開場能量。

Godot 4.6.3／Linux Compatibility／llvmpipe／Dummy。不是自然完整 match、目標 Mac／真人平衡／音效裝置或即時 GPU 效能驗收。舊證據保留，公開 Web 未更新。
