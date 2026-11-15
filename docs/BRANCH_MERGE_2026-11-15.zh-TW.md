# 全部分支整合至main（2026-11-15）

依使用者「幫我將所有合適嘅分支全部合併到main」，從最新main `f9576c5` 建立 `codex/merge-suitable-branches` 驗證整合。全部34個原始碼分支（含main）均已納入；獨立Web產物分支gh-pages排除，保留所有來源分支。

|本輪新增來源|原始SHA|結果|
|---|---|---|
|codex/four-fighter-motion-plan|6ad88f8|31段隨附Mixamo、步法／挑空／空中／NPC、配對肩摔／起身|
|codex/zip-express-reference|879846b|ZIP兩招、RIVET兩招、連續慢動作／插值與真命中VFX|
|codex/flight-street-handoff|7e0b245|高處非碰撞屋頂水箱／通風細節|
|codex/street-combat|e4329e9|原已複製到main的內容保持，補完整提交祖先|
|codex/last-service-character-record|0871bde|隨street-combat納入祖先；不回退main的角色實作現況說明|
|codex/last-service-roster-revision|87c2c4f|2男2女設定與當輪造型計劃；不替換目前GLB|

完整35個遠端分支SHA／原已納入狀態：[分支清單](evidence/branch-merge-2026-11-15/branches.json)。本機work亦已是main祖先，沒有額外未合併改動。

## 衝突處理

文件歷史保留，這份整合狀態覆蓋較早「不合main／私有安裝／只有23段」紀錄。遊戲現隨附31段Mixamo，Pull即用，來源／條款說明保留；現行繁中、5／8／100字體、原GLB、存檔與音樂保留。ZIP／RIVET地面special及overdrive由影片專用owner接管，避免通用Mixamo蓋過分段踢擊、距離步態或直拳／下砸；其他Mixamo動作、倒地起身與配對摔投保持。

## 驗證及剩餘範圍

[本輪21個suite與原始log](evidence/branch-merge-2026-11-15/README.md)：動作矩陣554、Mixamo179、配對肩摔147及renderer65、街鬥90、空地216、連續慢動作79、ZIP23／44／22、RIVET14／25／19、loader14、槍械21、角色規則46、繁中21、基本戰鬥34、街景13、動作18strict及全局23strict均通過。各套件重疊，不相加作唯一總數。

Linux軟體renderer，非Mac／真人／實體手柄／目標GPU／實聽驗收。原生編輯器受Vulkan環境所限、舊原生combat退出的GL leak與walk指標NO GRAB另列診斷，不當成乾淨通過；沒有為此改原玩法或專案配置。日常GitHub Desktop選main Fetch／Pull；Godot完成本機匯入後驗收。沒有部署公開Web。
