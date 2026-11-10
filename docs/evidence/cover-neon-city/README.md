# 街城剪影封面：原生畫面與驗證

- [640×360標題畫面](title.png)
- [角色頁](fighters.png)／[設定](settings.png)／[戰鬥HUD](hud.png)
- [37/37介面檢查](checks.json)／[完整原生log](native.log)
- [生成來源、兩段原片SHA](../../../references/cover-neon-city-2026-11-10/source.json)
- [目前設計及完成範圍](../../COVER_NEON_CITY.zh-TW.md)

沿用 `godot/tools/verify_reference_ui.gd`，僅將輸出路徑改到本資料夾；[實際runner副本](runner.gd)保留以便重現。從儲存庫根目錄，以Godot4.7.2執行 `--path godot --audio-driver Dummy --script docs/evidence/cover-neon-city/runner.gd`，需要原生OpenGL顯示環境。

檢查包括三視窗尺寸、鍵盤／滑鼠選單、選角／設定／Demo入口、音樂雙deck與暫停後播放頭持續、有限特效幾何。全部37項通過；log無ERROR／SCRIPT ERROR或退出洩漏，保留軟件顯示環境不支援V-Sync的提示。Linux Compatibility／llvmpipe／Dummy音訊；不是目標Mac效能或實際揚聲器聽感證明。海報外觀另由人工檢視，並非自動人臉辨識測試。
