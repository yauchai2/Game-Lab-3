# 動態標題：原生錄像與檢查

- [8秒循環GIF](title-loop.gif)／[MP4](title-loop.mp4)：96個640×360原生畫面，12fps，無音訊；GIF僅供預覽，遊戲實際使用原生3D場景。
- [鏡頭1](shot-0.png)／[鏡頭2](shot-1.png)／[鏡頭3](shot-2.png)／[鏡頭4](shot-3.png)／[減少特效的靜態海報](reduced.png)
- [8項場景檢查](motion-checks.json)／[嚴格log](motion.log)／[capture runner](capture-runner.gd)
- [37項原生介面回歸](ui/checks.json)／[log](ui.log)／[原生標題截圖](ui/title.png)／[runner](ui-runner.gd)
- [設計／生命週期／限制](../../TITLE_MOTION.zh-TW.md)／[來源SHA與觀察](../../../references/cover-neon-city-2026-11-10/motion-sources.json)

8項涵蓋獨立場景、無臉材質、四段鏡頭、有限更新、離頁停鐘停渲、減少特效靜態fallback、循環物件數有界及原生五選項。既有37項涵蓋三視窗尺寸、真鍵盤／滑鼠操作、選角／設定／Demo入口、音樂播放頭及雙deck持續規則。兩次最終執行均通過，log無ERROR／SCRIPT ERROR或退出洩漏；保留V-Sync不支援提示。

從根目錄重現時，以Godot4.7.2、原生OpenGL顯示環境，使用 `--path godot --audio-driver Dummy --script "$(pwd)/docs/evidence/title-motion/capture-runner.gd"` 或 `ui-runner.gd`。capture runner輸出原始幀到 `/tmp/title-motion-frames/`，需先建立該目錄。錄像是虛擬時間，不代表實時性能；Dummy驗證不代表實際揚聲器聽感。原片觀察採抽樣，不聲稱逐來源幀或精準音樂節拍量測。
