# Neon Facets Lab：第一個可玩風格切片

最新大招數值與鏡頭已由 [長演出更新](NEON_SIGNATURE.zh-TW.md)覆蓋；以下保留M1初始切片及當時驗證。

2026-11-10；獨立分支 `codex/neon-street-lab`。本頁覆蓋前輪「只有規劃、runtime未改」的現況敘述；[完整路線](NEON_FACETS_PLAN.zh-TW.md)中的M2–M6仍是待辦。

## 現在可以玩到

- 戰鬥場景預設使用Lab profile：灰白／紫冷影城市、暗路面／窗洞、少量青／桃紅立面與五階桃紅天空。既有細節MultiMesh也轉到同一色盤；原建築、道路、招牌位置與碰撞未改。保留空白招牌，沒有加入新文字。
- 四個現有角色都接入Lab shader，保留原Albedo／五官／服裝及身高；用有限色階與紫冷影處理。原始GLB、貼圖、骨架不變。沒有宣稱已重做低面數拓撲、鞋／髮輪廓或新增8種pose。
- 真格擋、空中反制、蓄力、特定重擊、BREAK及KO驅動單一全屏director。普通拳保留局部圖形；強事件短暫抽走街景，人物只在開頭0.10s變剪影，接著回到完整角色與街景。director有優先序、0.8s恢復預算；蓄力升級為真命中可接續。
- 常態／攻擊圖形共用角色色盤；活動局部效果上限24。舊theatre／rhythm／spectacle的全屏繪圖及整畫面grade在Lab停止疊加；它們原有的局部事件資料仍供HUD／動作使用。這不是所有13招都重新作者化完成。
- 共用combat_rhythm接受Lab數據，縮短小事件的停慢段、保留重招收放，不加第二套Engine.time_scale。鏡頭沿用雙方構圖，Lab演出最高6°roll，不執行舊版11°環繞鏡頭；F2、重開、返回標題會清理臨時狀態。
- 640×360與現有Ink UI、3D選角、活街景及持續音樂保留。原生HUD標記 `NEON FACETS LAB`，視窗也有版本名稱；偏好獨立存到 `user://neon_lab/options.cfg`，不寫原版afterhours.cfg。

## 試玩

GitHub Desktop Fetch後切到 `codex/neon-street-lab`，Pull此分支。Godot匯入此分支的 `godot/project.godot`，F6執行 `scenes/combat/street_fight.tscn`，或F5由主選單進入。主選單 `AI DEMO`／對戰F12可看無限自由交戰；F2減少演出，Esc暫停。

目前來源已推送供Fetch／Pull，並非已同步使用者電腦；公開Web版本不更新。`neon_enabled=false`可在場景建立前回到基線渲染，供擷取工具作A/B；不是新增給玩家的複雜選項。

## 證據與驗證

[畫面／影片／報告](evidence/neon-facets/README.md)。Godot4.7.2 Linux Compatibility（Mesa llvmpipe）完成21項Lab檢查、53項原生UI／材質檢查、134項戰鬥規則、6項真PCM混音檢查。沒有renderer／script ERROR；可用V-Sync不支援提示保留在原log。沒有把軟件繪圖速度當Mac性能證明。

固定30秒wall-step自由AI雙方19／32次命中，強stage134／1800幀（7.44%），局部效果峰值10、roll峰值6°。1800步是模擬演出時間，不是引擎在此機30秒達60fps的量測。錄像450幀／15fps、無剪接、無聲；實際音樂輸出及pause持續性另以混音測試驗證，並非把音軌混進這段影片。

首輪Lab測試清理後曾出現ObjectDB退出警告，後續釋放fixture director並以verbose重跑；最終提交的verification.log無洩漏／ERROR。模型材質退休佇列檢查及既有24次換角生命週期回歸通過。

## 後續工作

M2：葉片端部動畫、全道具／車輛語義材質、天空雲動態與建築幾何不齊；M3：輪廓／8姿態及Lab專屬選角呈現；M4：逐招重新作者化、四組大招與完整鏡頭句子；M5–M6：更細緻的背景director、音訊標拍、60秒實機評估及Mac性能覆核。現階段先交付能直接打開比較feel的完整切片。
