# 動作隨 GitHub 提供及第一批收尾（2026-11-14）

使用者最新指示：「授權允許，把它放進 GitHub，繼續把全部做完」。本輪將兩份 game-ready 動作資料正式納入 `godot/assets/animations`，覆蓋先前「只能私有安裝」的流程。**Fetch／Pull 此任務分支、讓 Godot 匯入後便可直接玩，不需要下載 JSON、Adobe 登入、MCP 或執行 installer。** 原始 FBX／GLB 保留；沒有部署公開 Web。

第一批23個衍生clip全部啟用，包括前輪未啟用的 Knocked Out、Getting Up、Kicking。另完成現有四角全部戰鬥招式及狀態覆核；適合的CC0全身挑空、刺棍、跑退步、跳起落地與專用過場保留原owner。這不表示候選表49段均已下載；Sweep Kick未提供，而且現行沒有獨立掃腿move id，沒有把重複Hurricane假稱掃腿。

## 角色及接續

|角色|這輪完成的技能／空中動作|
|---|---|
|ZIP|Mixamo左右迴旋踢／單圈旋風踢、雙踢與flurry沿原真命中時計、Kicking用於空踢與有界向下追擊|
|RIVET|Mixamo直拳蓄力／勾拳大招，空中維持拳擊身份；7／8幀蓄力對齊同一load pose|
|HUSH|肘擊截擊與爆發，空中刺拳／肘擊／踢擊；打擊骨沿實際肘或手腳|
|LOOP|短棍水平／反手／下劈接入空中及爆發／節點脈衝；刺棍與放置指令保持適用CC0動作|

逐招地面／空中實際clip與owner見[覆核表](evidence/motion-completion/coverage.zh-TW.md)。原玩法、資源消耗、命中、傷害及移動數值保留；展示不寫simulation。空中拳／棍保留Jump腿部遮罩，踢擊只遮非打擊腿，來源垂直root不與實際跳躍重複相加；meteor／counter只有有界向下修正。

Knocked Out裁來源30Hz第40–121樣本、2.7秒，經原Death01入口播放並維持屍體貼地、群戰及KO過場規則。Getting Up去掉開頭躺平padding，取第75–187樣本；共同恢復由28延長至64tick（約1.067秒），相當於來源3.733秒約3.5倍播放。抓握／翻身與第60tick落地一次傷害保持，整個共享段為80＋64tick；雙方都在原鎖定流程內。起身漸接回護架，並逐步回到共同戰鬥平面，避免解除paired狀態時突然跳Z位置。致命者不會起身，仍保留落地屍體。

RIVET舊6項失敗已修正：舊固定下盤mask再加程序轉髖會拉動雙腳，且7／8幀蓄力的程序髖角不同。固定下盤profile不再額外轉髖，缺檔fallback原19項現在全過。新Mixamo全身重心允許踏步，以每幀實際蒙皮不穿地、有限骨架、原simulation不被寫入驗收；新版19項亦全過。Transit舊「model.position必須全零」改為無X/Z lunge且蒙皮貼地，允許必要鞋底Y校正；沒有放寬穿地條件。

## 資產及匯出

- `mixamo_fighters.json`：23個衍生clip、接觸marker、來源／裁切metadata。
- `mixamo_shoulder_throw.json`：兩角同座標、61–121共同樣本。
- `MIXAMO_SOURCES.md`：來源／適用條款說明；不能把Mixamo衍生動畫當CC0重新授權。

預設loader直接讀上述資產，`.godot`只作快取；兩個`GAME_LAB_*_LIBRARY`仍可作開發override。舊installer可手動更新隨附檔，其備份寫入被忽略的快取。Blender builder亦允許直接重建assets/animations，原始來源不覆寫。兩份JSON及來源說明都已驗證包含在本機輸出的PCK；這個打包測試沒有上傳Web。

## 驗收

完整證據：[evidence/motion-completion](evidence/motion-completion/README.md)。全招式／狀態矩陣554/554；前輪15個地面slot與步法119/119、loader拒收13/13；肩摔147/147、獨立renderer蒙皮／起身65/65。RIVET有／無Mixamo各19/19，其他相關回歸結果逐suite列明，不把重疊檢查加成唯一總數。

乾淨副本沒有`.godot`或環境override，重新匯入後直接載入兩份資料、跑13項loader與147項肩摔成功；再以最新收尾程式重跑成功。空專案掛載PCK的7項驗證確認兩個JSON、23clip、雙人角色及來源說明都在包內。

[12秒完整肩摔／起身](evidence/motion-completion/throw.mp4)、[14秒四角空連](evidence/motion-completion/air.mp4)均正式scene的真命令fixture；每角肩摔start／land／hit／end各一次，空連有真付費追擊、air_jab／air_kick／meteor。全片4fps抽格與四角起身／空中／倒地接觸表已檢視。Linux Godot4.6.3／llvmpipe／Dummy／MovieWriter；不是Mac、真人手感、實聽或硬體即時效能驗收。

程式及資料仍推同一任務分支 `codex/four-fighter-motion-plan`／[PR #37](https://github.com/yauchai2/Game-Lab-3/pull/37)。使用者本機／真人最終驗收仍需在其裝置完成，這不會阻止本輪程式與資料交付。
