# 2026-11-16：完整整合 PR #38 至 main

使用者明確要求「全部推到 GitHub main」。[PR #38](https://github.com/yauchai2/Game-Lab-3/pull/38) 已轉正式並完整合併，日常下載來源改用main；保留來源分支及原始資產。公開Web未部署。

## 本次納入

- 故事開局全部基本招式、據點指南／實際設施導航、成長與真實費用提示。
- 四角各六招、兩戰術槽Q／I、有限蓄力、解除H誤觸、變體與三套完整構築預設。
- 第二支援槽的回收／延時／空投、普通敵人回應可見預告、schema7舊存檔與預設遷移。
- 四角急停／前後步／前後閃切片覆核，修正場邊與身體受阻仍原地跑的展示步態。

## 合併證據

| 項目 | Git識別 |
| --- | --- |
| 原main | `5bd1c48b31fa20ff35bab6a8b520f9778963a1c5` |
| 已驗證PR head | `62a01e36b22d5d9ae35b46fad1ff7d6602ce1319` |
| 合併提交 | `4829efa790ccebeb1311d85b06a5dc3c077cc317` |
| PR head及合併提交共用tree | `590efafcb04b445940924d3e6221eb9f0fad586a` |

GitHub確認MERGED、非草稿；合併有上述兩個父提交。合併樹與驗證過的來源完全一致，沒有額外runtime差異。本次隨後僅更新交接／狀態文件，保留既有驗證及歷史紀錄。

[教學54/54原生重驗](evidence/story-merge-readiness/README.md)、[步態對照與權威trace](GROUND_MOTION_REVIEW.zh-TW.md)、[技能擴充](TACTICAL_EXPANSION.zh-TW.md)、[空投及相關回歸](TACTICAL_AIRDROP.zh-TW.md)為既有驗證依據；沒有把合併動作冒稱全部測試重跑或GitHub CI通過。

## 仍待完成

完整動作表尚有真180°換邊、勝利／選角、NPC／Boss與遠景路人等；其餘模組、自然章節／Boss構築比較與專用動作仍待續。Linux原生及規則驗證不代表真人趣味／平衡、Mac、實體手柄或硬件效能驗收。Web部署與線上驗證未包含於此次來源整合。

GitHub Desktop選main，Fetch origin後Pull，再以本機Godot開啟遊戲。下方歷史文件中未答合併範圍、草稿及只推任務分支限制已由本次明確授權覆蓋。
