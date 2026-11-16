# Story onboarding — 2026-11-15

基線 main `5bd1c48`，Linux Godot 4.6.3，OpenGL Compatibility／Mesa llvmpipe，Dummy audio。截圖為實際原生引擎輸出；不代表 Mac／真人遊玩或硬件效能驗收。

| 檢查 | 結果 |
| --- | --- |
| 開局招式／三代存檔／實際按鍵和指南導航 | 54 / 54 |
| 城市成長、經濟、備援、四角第一區正常輸入 | 86 / 86 |
| 完整戰役、Boss、能量／傷害上限及極端裝備 | 50 / 50 |
| 原生城市／練習／裝備／Boss／退出隔離 | 23 / 23 |
| 既有關鍵腳本嚴格警告編譯 | 23 / 23 |
| 繁中翻譯、字圖覆蓋及語言保存 | 21 / 21 |

各組有範圍重疊，不當作獨立遊戲情境總數。`checks.json` 是新增檢查明細；`regressions.json` 保存本次回歸結果。所有成功執行的最終日誌已檢查沒有 ERROR／SCRIPT ERROR。

## 原生畫面

- [繁中指南](guide-zh.png)／[升級與裝備說明](guide-growth-zh.png)／[英文指南](guide-en.png)
- [據點下一步](hub-zh.png)
- [繁中技能台](skills-zh.png)／[英文技能台](skills-en.png)
- [第一場戰鬥及操作提示](combat-zh.png)

## 重跑

在專案根目錄執行（原生檢查需要可用的 Linux 顯示環境）：

```sh
godot --headless --path godot --editor --import --quit
godot --path godot --audio-driver Dummy --script res://tools/verify_story_onboarding.gd
godot --headless --path godot --script res://tools/verify_city_expansion.gd
godot --headless --path godot --script res://tools/verify_campaign_complete.gd
python tools/verify_godot_warnings.py --output /tmp/story-strict
godot --headless --path godot --script res://tools/verify_traditional_chinese.gd
```

Cloud desktop 連線工具本次失敗；已改用獨立 Xorg dummy 顯示執行原生引擎及輸入測試。首次嘗試系統 :0 被 X11 認證拒絕，改用專用 :1 成功；失敗的啟動不計入通過結果。沒有操作使用者電腦或部署 Web。
