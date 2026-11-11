# KO後：四角色魚眼特寫與專屬離場

[完整8.2秒 KO＋勝者有聲演出](ko-and-winner.mp4) · [四角色離場連播](four-victory-exits.mp4) · [四角畫面](four-exits.jpg)

四段單獨預覽：[ZIP](exit-zip.mp4)、[RIVET](exit-rivet.mp4)、[HUSH](exit-hush.mp4)、[LOOP](exit-loop.mp4)。

前5秒保留原快節奏爆破，K.O.字卡讀完後追加3.2秒：124°FOV超近廣角＋桶形魚眼畸變，勝者在鏡頭前表演、轉身／滑步慢慢離開，末尾墨色切幕後才出結果選單。鏡頭依真骨架頭部位置取景；手部可以誇張透視靠近鏡頭，沒有固定替身。

- ZIP：近鏡甩手／拳尖挑釁，保持朝鏡方向向左側滑步；高頻三連音與鞋底滑擦。
- RIVET：雙拳近鏡、沉肩壓場，向右重步離開；低頻重音／金屬聲與重腳步。
- HUSH：手靠臉側、側頭回眸，向左轉身離去；短吸氣／脆響與較輕腳步。
- LOOP：右手花式擺動、沿用既有手部道具，轉身向右離去；訊號式琶音與清脆腳步。

`victory_exit.gd` 是共用director呼叫的無獨立時鐘程序骨架演出，按四個roster模型及角色ID分支。不是新增固定人物影片或修改GLB；沒有宣稱是新錄製mocap、完整腳部IK／足底鎖定或手指獨立動畫。魚眼為即時螢幕桶形畸變結合透視近鏡，不是物理鏡頭光學校準。

勝者段背景碎片／煙雲繼續以慢動態更新；保留角色顏色、邊緣墨線、角色色漫畫切線、近鏡反衝與轉場。四段3.2秒音效是程序合成，專用player在第5秒切換正確角色音軌，服從原SFX音量／mute／pause／clear，BGM沿既有owner繼續。

驗證：

- [86項四角色×雙方勝利／出框／不同骨架姿態／清理](verification.json)／[log](verification.log)。
- [20項聲畫回歸](fx-regression.json)／[log](fx-regression.log)。
- [165項KO生命週期](ko-regression.json)／[log](ko-regression.log)。
- [17項結果流程](result-regression.json)／[log](result-regression.log)。
- [四段真引擎音軌量測](audio-report.json)，有聲且零削波；[完整錄像log](full-movie.log)／capture-0至3.log保留軟件渲染耗時。

上述最終log無ERROR／SCRIPT ERROR或洩漏警告。Godot4.6.3 Compatibility／llvmpipe／Dummy audio；影片由Movie Writer真正同步聲畫，640×360／30fps，剪掉1個準備幀。四角連播只是四段引擎錄像順接，不是後配音／插幀。固定匯出不是Mac／目標GPU即時效能或真人實聽驗收。未重跑整個歷史suite，前輪舊Rhythm基線失敗仍保留。

重現：

```sh
python tools/build_city_breaker_audio.py
godot --headless --editor --path godot --import --quit
godot --path godot --audio-driver Dummy --script res://tools/verify_victory_exits.gd
godot --path godot --audio-driver Dummy --fixed-fps 30 --write-movie /tmp/victory.avi --script res://tools/capture_city_breaker_fx.gd -- --out=res://../docs/evidence/victory-exits/ --character=0
# 其他角色：--character=1/2/3；只錄離場追加 --outro-only
```
