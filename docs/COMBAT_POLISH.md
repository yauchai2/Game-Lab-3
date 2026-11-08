# 戰鬥與練習模式完善

2026-11-08（香港時間），`codex/street-combat`。承接使用者「繼續完善遊戲」，這輪聚焦可反覆試招、空中追擊、難度與 Web 操作，不更換原始角色／街景模型。

## 新增玩法

- **無限練習**：不走回合倒數、不結算 KO；致命命中保留 1 HP，待雙方落地並離開攻擊／硬直 90 個模擬幀後回滿生命及防禦。能量維持 100，可反覆練習能量技。暫停／頓幀不偷跑回復時鐘。
- **三種練習對手**：站立、持續面向玩家防禦、AI 陪練。防禦對手不自動精準防禦，仍可測普通防禦及破防。F7 輪換並重置間距，選單也能選。
- **F5 快速重置**：回到原站位，清除特效、輸入緩衝及紀錄；不用重載整個場景。新增最近六筆遊戲操作及模擬幀號、上次連段命中／傷害。
- **挑空追擊**：挑空命中後可按 Space 取消收招追上對手；跳躍輸入可在頓幀期間緩衝八個模擬幀，再用 J 接空中輕攻擊。未命中不能取消；空中攻擊保留部分水平慣性。
- **浮空限制**：對手離地後最多再吃三次空中命中，第三次帶向下速度，落地後重置預算，避免反覆向上浮空。原三段連擊、傷害遞減及地面規則保留。
- **AI 難度**：Relaxed / Standard / Challenging，改變固定攻擊節奏、可防禦窗口及跳躍頻率；Standard 保留原攻擊週期。AI 均不使用精準防禦，不宣稱為學習型 AI。

## 選單與 Web 操作

主選單及暫停可選難度，練習可選對手；暫停新增返回主選單。較長內容放入有焦點跟隨的捲動容器，保護小視窗可操作性。聲音、音樂、減少演出、場景描邊、難度及對手選擇存於本機 `user://afterhours.cfg`，不收集玩家資料。類型錯誤／超界值會回到預設或限制在有效範圍；瀏覽器由 Godot 持久檔案系統保存。

Web 在畫布有焦點時攔截 F5／F7，避免練習重置變成瀏覽器重新整理／插入符瀏覽；保留 Ctrl／Meta 瀏覽器快捷鍵。全螢幕時畫布維持 16:9 實際矩形，避免非 16:9 螢幕只有圖像縮放、滑鼠點擊座標卻偏移。更新操作提示及素材頁連結，沿用原 CC0 音訊／動畫及圖像。

音樂改為還原設定後才首次播放，避免已選靜音時仍在啟動瞬間播放。部分快速 headless 測試退出仍有既有音訊 playback 清理警告，未宣稱全面修復。

## 驗證

新 32 項確定性邏輯／設定／場景整合檢查通過；既有格鬥 34、場景／音訊 33、骨架／透視 30、編輯器警告 3、viewport 自動輸入 11 通過，共 143 項。viewport 本輪使用 headless `Input.parse_input_event`，不是實體鍵盤；舊 X94 顯示服務已不可用，啟動失敗另留日誌。

先前 GitHub release 已成功完成匿名 HTTP 15/15 資產雜湊；Chromium + ANGLE SwiftShader 實際 WebGL 啟動、Enter、D、J、K、Esc 及畫面擷取成功，沒有 JavaScript pageerror。這補上先前 Sites 預覽不可用的驗證缺口；不是硬體 FPS、真人手感或聆聽證據。

新的本機瀏覽器預覽請求被環境代理回應「Loopback targets forbidden」，沒有繞過此限制；接續用授權的公開 GitHub Pages 發佈再驗證。新的 Web／公開頁結果在完成後補記，不能把舊版測試當作新版驗證。

重現：

```sh
godot --headless --path godot --audio-driver Dummy --script res://tools/verify_combat_polish.gd
python tools/build_web.py --output /absolute/output
node tools/verify_web_build.mjs /absolute/output
godot --headless --main-pack /absolute/output/game.pck --script /absolute/repo/godot/tools/verify_web_pack.gd
```

證據在 `docs/evidence/combat-polish/`；不覆寫歷史測試快照。原始場景、GLB、天空圖及素材授權保留。投技、第二角色、手柄、手機觸控和多人仍未完成。
