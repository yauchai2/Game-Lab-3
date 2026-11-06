# 接續工作交接

更新日期：2026-11-06（Asia/Taipei）。本紀錄只根據本聊天與實際檔案，不假設其他對話內容。

## 同步前讀取範圍

- 原工作區 repo：`/workspace/Game-Lab-3`，本地分支 `work`，乾淨，HEAD 為 `cbf117aa36b0237bcf1c1c083ae33cd148c5d0c4`。
- GitHub 遠端當時只有 `main`，同一初始提交，只有 README.md；未發現 AGENTS.md、設計／待辦／交接文件或開啟中的 PR。
- 本次已讀當時 README，查詢遠端分支／檔案／PR，再 fetch 建立獨立任務分支 `codex/flight-street-handoff`。本次新增 AGENTS.md 以記錄使用者要求的協作規範。
- 這是讀取時的快照，不表示未來 main 或其他任務分支沒有新增成果；接續前必須重新確認。

## 現有成果

`godot/` 已包含六件資產展示及 S1 街道白盒。主場景為 `scenes/street_whitebox.tscn`（1–5／Tab 切換），原 `scenes/review.tscn` 保留。尚無可操作角色。所有 GLB 原始資料未改動；尺寸與簡化碰撞在各包裝 .tscn。`assets-manifest.json` 記錄來源雜湊與狀態；`references/assets/` 包含七種資產的參考圖；`docs/evidence/` 有原型預覽與載入紀錄。

已確認的偏好與取捨見 [DECISIONS.md](DECISIONS.md)。設計基準見 [DESIGN.md](DESIGN.md)。完整原聊天計劃保留於 [archive/chat-plan.zh-TW.md](archive/chat-plan.zh-TW.md)，其中歷史工作區附件路徑不可當成 repo 檔案。

## 從哪裡接續

1. 讀取 AGENTS.md、README.md、本文件、TODO、DESIGN、DECISIONS 和 VALIDATION，確認最新分支與修改。
2. 重跑 Godot 匯入與 `verify.gd`，確認當前環境能使用六件資產。
3. 讀取 [WHITEBOX.md](WHITEBOX.md)，查看 S1 的四個固定視角與俯視布局；白盒已實作，等待使用者構圖回饋。
4. 保留 `godot/scenes/review.tscn` 作資產對照；新街道另建場景。
5. 下一個實作階段為 S2 基本遊走；S1／S2 確認後再精修 10–15 m 街段及飛機事件。先不要求使用者追加付費道具生成。

## 驗證與缺口

來源 GLB 雜湊、Blender CPU 預覽和 Godot 無視窗載入有證據；GPU 畫面、實際遊玩與效能尚未驗證。詳細範圍見 [VALIDATION.md](VALIDATION.md)。

原參考照片、三段影片及部分額外三視圖未加入 repo。需要時請明確說明缺少哪些素材，不能聲稱已觀看不存在的來源。轎車只有參考圖，尚未收到模型。

## 同步原則

本次僅提交與推送任務分支，供審查及跨對話接續；不自動合併 main 或發佈。若其他分支後續新增成果，先讀取並保留，再整合本任務所需部分。

## 此次 repo 重新驗證

六件原始 GLB 與來源 SHA-256 一致；Godot 4.6.3 在本 repo 重新匯入和載入成功。模型、場景、參考圖及非歷史文件的本地連結均核對存在。證據見 VALIDATION.md 的「任務分支重新驗證」。

## 遠端接續位置

- 任務分支：[codex/flight-street-handoff](https://github.com/yauchai2/Game-Lab-3/tree/codex/flight-street-handoff)
- 草稿 PR：[#1](https://github.com/yauchai2/Game-Lab-3/pull/1)
- 首次完整同步提交：`532670dadee274a643d8faea88b1484714354ae8`。本節連結為後續補充紀錄；以遠端分支最新提交為準。

目前未合併 main、未發佈。若後續要接續本成果，先讀任務分支或 PR 的最新內容，不要只讀尚未合併的 main。

## S1 街道白盒更新

已讀取任務分支最新規範並保留六件來源資產及原展示。新增參數配置、生成器、街道場景、四個固定相機與俯視相機、1–5／Tab 切換，以及 Godot 結構／相機／物理射線檢查。飛機位置與朝向經入口預覽調整，屬美術構圖參數，非航空實測。

現有環境沒有 Xvfb 顯示服務，未取得 Godot GPU 畫面；改用 Godot 匯出的同一份幾何在 Blender Cycles CPU 產生五張預覽。操作與重現步驟見 WHITEBOX.md。尚未完成玩家控制器、事件聲音、最終 toon 或硬體效能。

五張 CPU 預覽已完成並檢查，側巷缺少地面基底的問題已修正；入口保留道路與現有道具前景。新白盒檢查涵蓋 1–5 鍵、Tab 循環、八個地面射線取樣與配置指紋，結果見 docs/evidence/whitebox/。下一步等待構圖回饋並實作 S2，勿將 S1 固定相機當成行走控制器。
