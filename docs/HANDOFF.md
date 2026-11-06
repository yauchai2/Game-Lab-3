# 接續工作交接

更新日期：2026-11-06（Asia/Taipei）。本紀錄只根據本聊天與實際檔案，不假設其他對話內容。

## 同步前讀取範圍

- 原工作區 repo：`/workspace/Game-Lab-3`，本地分支 `work`，乾淨，HEAD 為 `cbf117aa36b0237bcf1c1c083ae33cd148c5d0c4`。
- GitHub 遠端當時只有 `main`，同一初始提交，只有 README.md；未發現 AGENTS.md、設計／待辦／交接文件或開啟中的 PR。
- 本次已讀當時 README，查詢遠端分支／檔案／PR，再 fetch 建立獨立任務分支 `codex/flight-street-handoff`。本次新增 AGENTS.md 以記錄使用者要求的協作規範。
- 這是讀取時的快照，不表示未來 main 或其他任務分支沒有新增成果；接續前必須重新確認。

## 現有成果

`godot/` 是六件資產的展示專案，並非街道白盒或可玩場景。所有 GLB 原始資料未改動；尺寸與簡化碰撞在各包裝 .tscn。`assets-manifest.json` 記錄來源雜湊與狀態；`references/assets/` 包含七種資產的參考圖；`docs/evidence/` 有原型預覽與載入紀錄。

已確認的偏好與取捨見 [DECISIONS.md](DECISIONS.md)。設計基準見 [DESIGN.md](DESIGN.md)。完整原聊天計劃保留於 [archive/chat-plan.zh-TW.md](archive/chat-plan.zh-TW.md)，其中歷史工作區附件路徑不可當成 repo 檔案。

## 從哪裡接續

1. 讀取 AGENTS.md、README.md、本文件、TODO、DESIGN、DECISIONS 和 VALIDATION，確認最新分支與修改。
2. 重跑 Godot 匯入與 `verify.gd`，確認當前環境能使用六件資產。
3. 執行 S1：依 [design/next-phase.zh-TW.md](design/next-phase.zh-TW.md) 建立參數化街道白盒、四個固定視角與俯視布局。
4. 保留 `godot/scenes/review.tscn` 作資產對照；新街道另建場景。
5. S1／S2 成立後精修 10–15 m 街段，再擴展與製作飛機事件。先不要求使用者追加付費道具生成。

## 驗證與缺口

來源 GLB 雜湊、Blender CPU 預覽和 Godot 無視窗載入有證據；GPU 畫面、實際遊玩與效能尚未驗證。詳細範圍見 [VALIDATION.md](VALIDATION.md)。

原參考照片、三段影片及部分額外三視圖未加入 repo。需要時請明確說明缺少哪些素材，不能聲稱已觀看不存在的來源。轎車只有參考圖，尚未收到模型。

## 同步原則

本次僅提交與推送任務分支，供審查及跨對話接續；不自動合併 main 或發佈。若其他分支後續新增成果，先讀取並保留，再整合本任務所需部分。

## 此次 repo 重新驗證

六件原始 GLB 與來源 SHA-256 一致；Godot 4.6.3 在本 repo 重新匯入和載入成功。模型、場景、參考圖及非歷史文件的本地連結均核對存在。證據見 VALIDATION.md 的「任務分支重新驗證」。
