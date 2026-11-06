# 使用 GitHub Desktop 查看最新 Godot 場景

此專案目前的製作成果位於任務分支 `codex/flight-street-handoff`；尚未合併到 `main`。這裡的步驟用於查看與回饋，並不要求合併 PR。

## 首次設定

1. 安裝 GitHub Desktop 並登入可存取 [Game-Lab-3](https://github.com/yauchai2/Game-Lab-3) 的帳號。若尚未下載，選 **File → Clone repository**，用 URL `https://github.com/yauchai2/Game-Lab-3` 複製到電腦。若已 clone，選 **File → Add local repository** 加入已有資料夾，不要重複建立。
2. 在 Desktop 頂部確認 **Current repository** 是 Game-Lab-3，按 **Fetch origin** 取得遠端分支資訊。
3. 打開 **Current branch** 選單，選 `codex/flight-street-handoff`。如有遠端分支選項，選 `origin/codex/flight-street-handoff` 建立對應本地追蹤分支；界面文字依 Desktop 版本可能不同。確認目前分支不是 `main`。
4. 用 Godot 4.6.3 專案管理器的 **Import**，選擇該複本內的 `godot/project.godot`，等匯入完成，執行主場景（F5）。

## 之後更新

1. 先在 Desktop 看 **Changes**：若有你想保留的未提交修改，先保存或提交，遇到衝突不要選擇丟棄；可把狀況告訴 AI。切換分支或更新前，建議關閉執行中的遊戲及 Godot 編輯器，避免開啟中場景仍顯示舊內容或產生編輯衝突。
2. 確認當前分支 `codex/flight-street-handoff`，按 **Fetch origin**；有更新時按 **Pull origin**。若顯示已是最新則無需再拉取。重新開啟同一份複本的 Godot 專案並等待匯入。
3. 按 F5 執行，`1` 選入口視角、`P` 重播飛機、`0` 返回遊走；`B` 比較風格、`C` 比較程序／純色天空、`N` 比較生成的圖片天空、`O` 開關實驗性描邊、WASD 和滑鼠走動。詳細操作見 [WALK.md](WALK.md) 和 [FLYBY.md](FLYBY.md)。

AI 會在已授權範圍內推送任務分支並告知更新；桌面端需使用者自己 Fetch／Pull，本聊天不能假設已控制其電腦。AI 不會因這套流程自行合併或發佈。若未見到新成果，先檢查目前分支及開啟的專案路徑；也可在 Desktop 查看最新 commit 與 AI 回報的短 SHA 是否一致。

## 最有幫助的回饋

首次不必修改任何檔案。看入口時重播飛機，回饋：① 大小、飛行方向與時間；② 建築／天空的顏色和參考方向；③ 音效是否太大、太小或不自然。若有錯誤或畫面與截圖差異大，可提供截圖和 Godot 版本；有能力時補充電腦系統／顯示卡。尚未人工聽過的合成音效只是暫用音，不是最終音效。
