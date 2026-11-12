# 連續反彈僅限指定強化技能／大招

2026-11-11 使用者澄清：球狀多面連彈只在部分特殊攻擊或大招出現，普通攻擊不用。前輪擴大到重擊／挑空／投技的版本已被本輪覆蓋。

- 四角色overdrive最後重擊可觸發；ZIP前段連打保持原推力，到最後一擊才彈飛。
- RIVET蓄滿preload2技能、HUSH有sample_boost的技能可觸發；一般special不觸發。
- jab、cross、heavy、finisher、launcher、meteor、air_finisher、air_counter、grab都不會啟動ArenaBox。普通擊退與既有單次牆彈保留。
- 盒狀圍場僅在反彈效果期間顯示；普通跳躍不套臨時天花限制。原6接觸／180tick、E花20受身、衰減、保護及跟鏡不變。
- 結果頁／決勝回合KO保持，已同步並保留遠端2c1483e的能力抽取／九核心／Demo定時自動抽領，以及黑衣人／群戰整合。

[修正後的大招反彈預覽](power-ricochet.mp4)：兩組四角色、真overdrive命中（初始100能量／近身站立CPU是明示fixture），沒有注入傷害或速度；不按E以檢查反彈。BGM僅在錄像靜音，SFX保留。原普通挑空預覽僅為歷史證據。[接觸時序](capture.json)。

驗證共278項通過：65反彈規則（含四角色×10普通招式不啟動）、25原生結果／鏡頭、62二段跳、10重砲、7Demo、34戰鬥、75能力核心。headless與native資料夾保存報告；新核心回歸另外存ability-core-regression。不是全歷史suite或真人平衡／硬件FPS驗收。Godot4.6.3 Linux Compatibility／llvmpipe／Dummy audio，640×360固定30fps錄像；公開Web未更新。

推送期間另有main整合更新，已rebase保留。整合後65反彈＋25原生結果／鏡頭再次通過，另35項群戰規則通過；merged-headless／merged-native／merged-squad保存當次證據。上述影片在91db1f1基線錄製，並非新增黑衣人模型預覽。
