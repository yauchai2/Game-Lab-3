# 全遠端分支整合驗證（2026-11-16）

本次先發現local fetch refspec只追main，改用明確全分支fetch，再以GitHub API的38分支SHA逐個核對Git祖先。37個原始碼分支（含main）中只有codex/deadshift-integration的3個提交尚未納入；gh-pages為獨立部署產物，不合來源main也不部署。[完整分支快照](branches.json)記錄合併前狀態。

新來源6397f57（含0ed8b2f／69352b9）基於先前main，與PR #38後的main0029103整合。保留教學、戰術技能、TacticResponse／jammer沉默限制、schema7及MotionInterpolation步態；加入DEADSHIFT模型／附件／狗骨架／波次Dealer／STATIC預告、空中受擊及動態配樂。文件衝突保留兩側歷史，新的整合狀態優先。

## 本次執行結果

| Suite | 結果 |
| --- | --- |
| 嚴格編譯 | tactical23／motion18，七類warning fatal，均通過 |
| DEADSHIFT原生 | 24/24 |
| 故事教學原生 | 54/54 |
| 敵人預告反應原生 | 8/8 |
| 波次／戰役 | 37/37、50/50 |
| 擴充戰術／模組／空投 | 111/111、83/83、59/59 |
| 受阻步態／Rush／肩摔 | 21/21、22/22、147/147 |
| 連續動作原生 | 79/79 |
| 配樂聲效／開場／KO | 66/66、44/44、21/21 |

各suite重疊，不相加當唯一總數。所有接受執行exit0且無ERROR／SCRIPT ERROR。9個新GLB的SHA256全符合sources.json，未改原檔。原生中文首戰截圖[story-combat-zh.png](story-combat-zh.png)已檢視。log（僅去除行尾空白）、JSON與此次生成的規則報告保留於本資料夾，既有證據資料夾恢復其歷史版本。

第一次把continuous_motion當headless執行，停在frame_post_draw等待，人工終止exit-15；[headless-results.json](headless-results.json)保留此診斷，不當通過。隨後改用正常Compatibility渲染，continuous-native.json為79/79，exit0。

環境Linux Godot4.6.3、Compatibility／Mesa軟體渲染、Xvfb、Dummy音訊。原生log有Xvfb不支援VSync警告；import log有三個既有缺UID從cache重建警告，非腳本錯誤。新測試verify_deadshift的UID隨來源加入，其他產生的未追蹤舊UID不納入此次變更。此輪不是Mac、真人手感／趣味平衡、實體手柄、喇叭實聽或硬件FPS驗收；來源分支的Mac紀錄屬原作者紀錄，不冒稱本輪重測。

提交後再逐一驗證37個來源分支皆為main祖先、main與遠端一致。所有來源分支保留。公開Web未更新。
