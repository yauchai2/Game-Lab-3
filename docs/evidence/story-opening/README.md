# 開機劇情開場證據

- `storyboard.jpg`：Movie Maker 模式由真實啟動錄影抽出的 16 格（640×360 原生畫面）。
- `second-launch-menu.png`：第二次啟動 1.5 秒時的畫面，已直接在主選單。
- `checks.json`／`verify_story_opening.log`：34/34 原生檢查。
- 含聲音的完整錄影未放入 repo（約 10 MB），已交付到專案檔案 `story-opening/afterhours-opening-18s.mp4`。

環境：Godot 4.6.3 Linux、Compatibility／llvmpipe、Xvfb、Dummy 音訊。不代表使用者本機、GPU、真實音效裝置或觀感已驗收。
重跑：`xvfb-run -a godot --rendering-driver opengl3 --path godot --script res://tools/verify_story_opening.gd`；抽格用 `tools/capture_story_opening.gd -- <輸出資料夾> <秒數,秒數>`。
