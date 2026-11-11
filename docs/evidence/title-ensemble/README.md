# 五人群像構圖：原生錄像與檢查

- [8秒GIF](title-loop.gif)／[MP4](title-loop.mp4)：96張640×360原生畫面、12fps，無音軌；遊戲使用原生3D而非播放GIF。
- [0秒](shot-0.png)／[2秒](shot-1.png)／[4秒](shot-2.png)／[6秒](shot-3.png)／[同構圖靜態fallback](reduced.png)
- [10項場景／構圖檢查](motion-checks.json)／[log](motion.log)／[capture runner](capture-runner.gd)
- [37項原生介面回歸](ui/checks.json)／[log](ui.log)／[runner](ui-runner.gd)
- [設計](../../TITLE_ENSEMBLE.zh-TW.md)／[來源及靜態圖SHA](../../../references/cover-neon-city-2026-11-10/ensemble-sources.json)

10項檢查包括全幅獨立viewport、五人無臉材質、固定相機軸線、96個採樣中五個頭部均在選單外及畫框內、頭部投影互相保持45px以上距離、有限更新、離頁停渲停鐘、減少特效fallback、循環節點數有界及五個原生選項。頭部投影不能證明身體／頭髮完全無遮擋，外觀另檢視四個時間點；有意保留前後景遮擋。第五位是背景演員，不是第五個可選角色或多人對戰。

既有37項檢查涵蓋三視窗尺寸、真鍵鼠、角色頁／設定／Demo入口、音樂持續播放頭與雙deck等。使用Godot4.7.2 Linux Compatibility／Mesa llvmpipe；最終log嚴查ERROR／SCRIPT ERROR及退出洩漏，V-Sync不支援提示保留。不代表目標Mac性能、真人玩法測試或實際喇叭驗證。

從根目錄使用Godot4.7.2原生顯示環境，執行 `--path godot --audio-driver Dummy --script "$(pwd)/docs/evidence/title-ensemble/capture-runner.gd"` 或 `ui-runner.gd`。capture輸出原始幀到 `/tmp/title-ensemble-frames/`（需先建立），並從原生viewport重建 `godot/assets/ui/last_service/cover-ensemble.png`。錄像為虛擬時間擷取，不用它推斷實時FPS。
