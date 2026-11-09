# 使用 GitHub Desktop 查看最新 Godot 場景

## 新增三個角色

Pull `codex/street-combat` 後等待新 GLB 匯入，F5 → **角色配搭**，分別選原角色／角色 1／3／4，即時看右方預覽。所選配搭保存並用於對戰、練習與 F12 Demo。目前共用招式與能力，詳見 [CHARACTER_ROSTER.md](CHARACTER_ROSTER.md)。


## 最新 Rush 版查看方法

在 `codex/street-combat` **Fetch／Pull** 後，用 Godot 4.6.3 匯入／F5。Enter 對戰：**按住 J**、**K** 挑空或暴扣、**L** 爆發。主選單 **F12** 看無限雙 AI，R 重開、Esc 暫停、F12 退出，F2 比較減少演出。這輪有紅幕攻擊、BREAK／KO；N 不再換章。[新功能與影片](RUSH_REWORK.md)。只有來源分支更新，公開試玩網址保持舊版；雲端無法代你操作 Desktop。


目前格鬥與新街角細節位於任務分支 **`codex/street-combat`**；原始街景來源分支 `codex/flight-street-handoff` 保留。這裡的步驟用於查看與回饋，並不要求合併 PR。

依使用者 2026-11-08 指示，日常只推送原始碼供 Desktop 更新，**明確要求時才更新公開試玩版／gh-pages**。雲端 AI 不能假設已同步你的電腦。

## 首次設定

1. 安裝 GitHub Desktop 並登入可存取 [Game-Lab-3](https://github.com/yauchai2/Game-Lab-3) 的帳號。若尚未下載，選 **File → Clone repository**，用 URL `https://github.com/yauchai2/Game-Lab-3` 複製到電腦。若已 clone，選 **File → Add local repository** 加入已有資料夾，不要重複建立。
2. 在 Desktop 頂部確認 **Current repository** 是 Game-Lab-3，按 **Fetch origin** 取得遠端分支資訊。
3. 打開 **Current branch** 選單，選 `codex/street-combat`。如有遠端分支選項，選 `origin/codex/street-combat` 建立對應本地追蹤分支；界面文字依 Desktop 版本可能不同。確認目前分支不是 `main`。
4. 用 Godot 4.6.3 專案管理器的 **Import**，選擇該複本內的 `godot/project.godot`，等匯入完成，執行主場景（F5）。

## 之後更新

1. 先在 Desktop 看 **Changes**：若有你想保留的未提交修改，先保存或提交，遇到衝突不要選擇丟棄；可把狀況告訴 AI。切換分支或更新前，建議關閉執行中的遊戲及 Godot 編輯器，避免開啟中場景仍顯示舊內容或產生編輯衝突。
2. 確認當前分支 `codex/street-combat`，按 **Fetch origin**；有更新時按 **Pull origin**。若顯示已是最新則無需再拉取。重新開啟同一份複本的 Godot 專案並等待匯入。
3. 按 F5 執行格鬥主選單，Enter 對戰、T 練習，檢查斑馬線左右立面。按 F6 進原街景，`1` 選入口視角、`P` 重播飛機、`0` 返回遊走；`B` 比較風格、`C` 比較程序／純色天空、`N` 比較生成的圖片天空、`O` 開關實驗性描邊、WASD 和滑鼠走動。詳細操作見 [WALK.md](WALK.md) 和 [FLYBY.md](FLYBY.md)。

AI 會在已授權範圍內推送任務分支並告知更新；桌面端需使用者自己 Fetch／Pull，本聊天不能假設已控制其電腦。AI 不會因這套流程自行合併或發佈。若未見到新成果，先檢查目前分支及開啟的專案路徑；也可在 Desktop 查看最新 commit 與 AI 回報的短 SHA 是否一致。

## 最有幫助的回饋

首次不必修改任何檔案。看入口時重播飛機，回饋：① 大小、飛行方向與時間；② 建築／天空的顏色和參考方向；③ 音效是否太大、太小或不自然。若有錯誤或畫面與截圖差異大，可提供截圖和 Godot 版本；有能力時補充電腦系統／顯示卡。尚未人工聽過的合成音效只是暫用音，不是最終音效。

## 2026-11-08 街角加密

本輪補上兩側六棟相連舊樓、藍／橙正立面、窗籠冷氣、陽台燈球、空白店面、遮篷、捲閘、摩托車、車輛及低清表面。詳見 CORNER_DENSITY.md。F6 遊走也使用同一模組；原獨立白盒不改。公開 GitHub 試玩版沒有隨這輪更新，須在本機 Pull 後用 Godot 看新場景。

## 最新玩法試法（2026-11-09）

本輪已改成繁中 UI。主選單「交鋒教室」對應下文早期 PRESSURE DRILL。G 投技／拆投；E 可在撞到場邊後消耗 20 能量受身。F1 設定、H 操作、練習 F9 展開數據；F6 遊走按 H 展開提示。新版只在 Desktop Pull 後用 Godot F5 查看，公開網址未更新。詳見 [EXTENDED_POLISH.md](EXTENDED_POLISH.md)。

Pull `codex/street-combat` 後 Godot F5，主選單選 PRESSURE DRILL；或 T 進練習、F8 準備。可先不限時閱讀提示，按 K 才進 0.4 秒對峙，再選 J 頂進／Shift 卸勢／E 抽身。F8 重試，F5 退出此練習。完整規則見 [PRESSURE_EXCHANGE.md](PRESSURE_EXCHANGE.md)。這是原始碼版本，公開試玩版本輪不更新。

最新空中反制試法：在 `codex/street-combat` Pull 後，Godot 執行 → F11 → F8 → K → 接觸前 Shift → J 反踢／E 抽身。只更新來源；公開 Web 未更新。見 [AIR_REVERSAL.md](AIR_REVERSAL.md)。

雙 AI Demo：Pull 開發分支後執行 Godot，主選單按 F12；N 下一段、R 重播、Esc 暫停、F12 結束。公開試玩版未更新。見 [AI_DEMO.md](AI_DEMO.md)。
