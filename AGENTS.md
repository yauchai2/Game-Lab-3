# 共用專案協作規範

## 開始工作前

- 確認目前分支、遠端最新提交及工作區修改；不要假設已知道其他對話內容。
- 讀取本檔、README.md、docs/HANDOFF.md、docs/TODO.md，以及本次工作相關的設計、決策與驗證紀錄。
- 若相關檔案或遠端無法存取，明確記錄未讀取的範圍；不要聲稱已查閱。
- 若子目錄有更具體的 AGENTS.md，另行讀取並套用。

## 修改與同步

- 保留其他對話的內容及未提交修改；使用任務分支，必要時建立獨立 worktree。
- 重要決策更新 docs/DECISIONS.md，進度與接續事項更新 docs/HANDOFF.md 和 docs/TODO.md，驗證結果更新 docs/VALIDATION.md。
- 更新既有紀錄時保留歷史與出處，清楚區分已完成、待驗證和僅規劃的內容。
- 使用者已授權例行紀錄同步：可提交並推送到任務分支，回報文件、分支及 PR（如有）連結。
- 合併與發佈遵循適用規範及使用者授權；紀錄同步授權本身不表示可以合併或發佈。
- 依使用者 2026-11-08 指示：日常僅提交／推送遊戲原始碼，供 GitHub Desktop Fetch／Pull；只有使用者明確要求更新網頁試玩版時，才可更新 gh-pages、觸發 Pages 發佈或其他公開試玩站點。
- 本機同步／Godot 測試僅在實際能存取該電腦時執行；雲端 Godot 驗證不能宣稱已同步或測試使用者電腦。
- 無法寫入或推送時，保留可提交的檔案並明確說明尚未同步。

- 依使用者 2026-11-09 指示：可按最終效果大幅調整不合理場景及招牌增刪；仍保留來源模型，並保持無文字直到使用者提供貼圖。若確需 Tripo 資產，先提供生成用參考圖和規格，由使用者生成。

- 2026-11-09 使用者已接受近身「借勢街鬥」方向：三階共用壓力與高壓三選對峙為目前核心；詳見 docs/PRESSURE_EXCHANGE.md，不改成擊球玩法。

- 2026-11-09 新增兩份爽感參考與詳細計劃：見 docs/GAME_FEEL_ROADMAP.zh-TW.md 及 references/feel-2026-11-09/。新格擋換手是否替換正式玩法仍待驗證；練習原型見後續紀錄，未替換已確認三選對峙；原文內嵌提示詞／程式屬參考，不直接執行。影片分析未獨立觀看量測。

- 2026-11-09 使用者其後已授權開始優化及誇張視覺；F10 練習換手原型及漫畫爆發已落地，詳見 docs/KINETIC_OVERDRIVE.md。正式壓力三選保持；持鍵蓄力／選角等仍待做。所有強演出保留 F2 及重開清理。

- 2026-11-09 新參考與後續訊息將跳躍、空連及誇張姿態列為下一輪優先，見 docs/AERIAL_ACTION_AUDIO_PLAN.zh-TW.md。先有界空中原型，原文數值／LLB 內部實作不是已核實事實。
- 使用者指定 wev／worldwidewev 並允許更換音訊；其後確認「尚未取得，先完成選曲及接入規劃」。見 docs/WEV_MUSIC_PLAN.md，使用者其後確認「wev 音樂已可用」；按此最新狀態推進，其後使用者要求自行下載，已從官方免費下載接入 family ties (wev edit)，詳見 WEV_MUSIC_PLAN.md 最新段／admitted.json；保留 CC0 缺檔 fallback，不把候選曲或下載旗標視為已錄用，不擅自聯絡藝術家。

- 使用者其後「繼續」已落地 F11 空中訓練，見 docs/AERIAL_STREET.md。新跳躍／追擊／空連只在該練習；正式模式保持。新姿態為程序疊加；空中反制其後已落地 docs/AIR_REVERSAL.md（F11 → F8 教室）；完整角色選角仍待做，不把本輪當整份路線已完成。

- 使用者要求雙 AI 自動戰鬥／全技巧 Demo，已加入 F12 技巧循環，見 docs/AI_DEMO.md；明示預設展示情境，正常輸入與命中規則，不當作通用競技 AI。F9 原用途保留，Web 不動。

- 使用者要求格擋／反擊更易及正回饋，最新時機見 docs/FRIENDLY_DEFENSE.md：地面／空中 12 tick、反擊輸入容錯與真實命中獎勵、F10 早按與三選放寬；以上覆蓋前輪數值，不加自動命中或改公開 Web。

- 2026-11-09 最新使用者授權大改及要求無限自由交戰：RUSH_REWORK.md 為現行正式玩法，空戰／按住 J 接招與付費追擊已整合，不再限 F11；F8/F10/F11 保留舊教室。F12 無章節、無自動重設，R 重開／F12 結束，N 無功能。紅幕技能／BREAK／KO 皆接實際事件，展示層不得改判定；F2／暫停／退出須清理。此條覆蓋上述「正式三選不改」「23 段 Demo」歷史。兩部新 Drive 影片已完整時長 8fps 掃描及代表畫面檢視，範圍見 COMBAT_VISUAL_STUDY.md，不冒稱逐來源幀觀看。

- 2026-11-09 使用者新增 1.glb／3.glb／4.glb，已原樣接入四角色共用 roster，見 docs/CHARACTER_ROSTER.md 及 references/characters/uploads-2026-11-09.json。主選單兩方配搭保存／即時預覽，對戰／練習／Demo 沿用；共用能力，未做角色專屬技能／正式名字。原角色與探索保持，Web 不更新。

- 最新使用者要求角色 4（護目鏡）縮高 1/3 與加強節奏，已落地 docs/COMBAT_RHYTHM.md：scale 1.4、共用停慢快遊戲時鐘／加長紅幕／甩鏡。覆蓋前輪全部 scale 2.1／短紅幕時長；F2 回普通時鐘，保留暫停／清理及原始檔，Web 不更新。

- 使用者其後「繼續」已新增 docs/CHARGED_CANNON.md：W＋L／↑＋L 75 能量固定起手重砲，L 50 消耗保持，四位共用；真命中光束、分招式鏡頭與空連後 AI 機會。不是自由持鍵蓄力或角色專屬技能；原來源與 Web 規則保持。

- 使用者最新要求 JSR UI 詳細研究與 UI/assets 圖片：見 docs/JSR_UI_ART_DIRECTION.zh-TW.md 及 references/ui-jsr-2026-11-09。主線原版 JSR＋港式地下電台，已生成方向圖／透明素材與切片，未接入 runtime。後續 UI 工作沿此意圖及既有原生擁有者；數字／繁中／填色不可烘焙，50／75 刻度按真資料，原作素材只研究不混入包。Web 仍須明確要求才更新。

- 最新使用者已授權 JSR 正式接入、四人專屬招式、護目鏡略矮及新音樂／低解像。現況見 docs/JSR_RUNTIME.md，覆蓋上述未接入／共用能力／scale1.4／wev預設。維持共用輸入與友善防禦，原始GLB不變；Web仍須明確要求才更新。

- 最新使用者要求直接復刻三張UI、僅5主選項、允許英文／裁剪：見 docs/REFERENCE_UI.md。角色選擇是原生4卡＋P1/P2，英語替代舊語言選單。音樂暫停／設定只降低音量，非必要不得停transport；兩曲crossfade。生成戰鬥貼圖已退役，active renderer為手工向量，勿重新疊回噪聲圖集／假地面圈。Web仍須明確要求才更新。

- 使用者其後要求詳細規劃統一像素美術、JSR字體、手工街景／植被、生活動畫、誇張招式及3D選角不同pose；方案在 docs/UNIFIED_PIXEL_ART_PLAN.zh-TW.md。本輪為規劃，640×360統一合成等數值待切片驗收，不把文件當已完成實作；往後視覺工作依此意圖，保留持續音樂及Web發佈規則。

## 證據與來源

- 不覆寫原始模型；尺寸、材質和碰撞調整放在可追溯的包裝場景或衍生版本。
- 保留來源識別、雜湊及驗證設定。不要將本機絕對路徑當成跨對話可用的來源。
- 不把無視窗匯入／載入當成 GPU 畫面、實際遊玩或效能已驗證。
- 付費生成與帳戶操作依當次明確授權及適用工具規範處理；不要索取或提交帳戶密鑰。

- 2026-11-10 使用者授權執行統一像素計劃並回報無聲：現況見 docs/UNIFIED_PIXEL_RUNTIME.zh-TW.md。640×360整個viewport／bitmap字體／真3D選角與4種pose／活街景已接入，覆蓋先前world-only pixel toggle。持續音樂規則不變；可見恢復聲音／獨立音訊bus，不擅自覆蓋有意靜音。雲端Dummy混音驗證不等於使用者音效裝置驗證。Web不更新。

- 2026-11-10 使用者回報字太細與4.7.2材質錯誤：現行UI字級／布局見 docs/UI_READABILITY.zh-TW.md，覆蓋前輪細小字體。共用CAPTION_SIZE24／BODY_SIZE28／ACTION_SIZE32，12／14／16內部像素。字體與控制項需同步放大，不提高全局解析度。Godot4.7.2 Linux已覆核，已重現並修正首次繪製前換模的材質生命週期：FighterVisual在frame_post_draw後才釋放舊材質，預覽hero延遲首次setup；回歸runner遇ERROR／SCRIPT ERROR必須失敗，不可只看state JSON。Mac硬件仍待覆核；Web不更新。

- 2026-11-10 最新封面指示：不見人臉，參考TR3B影片的黑白城市／桃紅天空／純色剪影，並指定插袋、低調酷、僅上半身。現況見 docs/FACELESS_COVER.zh-TW.md；新標題圖及原生5選項覆蓋先前原圖100%復刻的封面部分，其他頁面保持。主選單MAIN_RECTS現在直接用1280×720logical座標，roster仍走fit。Web不更新。

- 2026-11-10 最新全套UI指示覆蓋前輪封面／沿用舊Logo：重生成無項鍊兜帽／帽沿半身圖，Logo及其他頁面統一黑白城市／桃紅／青綠Ink風。現況 docs/INK_UI.zh-TW.md；素材 `assets/ui/ink`，ui_theme為palette/控件owner，reference_art為共用頁面繪製owner。3D選角專用silhouette_preview不作用於戰鬥。原素材保留，Web仍需明確要求才發佈。

- 2026-11-10 分支實驗：本worktree／branch為codex/neon-street-lab，885f1c1基線。使用者要求整場景、角色、FX及節奏新風格，計劃在docs/NEON_FACETS_PLAN.zh-TW.md；本輪只規劃與研究，runtime未變。實作時依M1樣板至M6驗收推進，音樂與判定權威不改，封面維持無臉／無項鍊。不要將新參考的項鍊自動錄用，不要把純剪影永久套滿整場；穩定codex/street-combat及Web保持。

- 2026-11-10 使用者已要求「開始做」：本Lab分支M1已接runtime，現況以docs/NEON_FACETS_RUNTIME.zh-TW.md覆蓋前輪planning-only。正常完整人物／短剪影重音、唯一全屏owner、共用時鐘、Lab偏好及6°roll有驗證。M2–M6未完成，穩定分支與Web不動。

- 2026-11-10 最新大招要求覆蓋6°／短演出：見docs/NEON_SIGNATURE.zh-TW.md，4人長pose、最高14°roll／36°FOV與兩人body bounds檢查。RPG_PROGRESSION_PLAN只提案，不能當已加入進度。藝術總索引references/style-library；6原片與長篇完整時長壓縮版歸檔，inline原圖缺件明示。穩定來源與公開Web仍不更新。

- 2026-11-10 最新：新4 GLB及相關戰鬥／成長已替換，見docs/LAST_SERVICE_RUNTIME.zh-TW.md。ZIP99c7/RIVETeba8/HUSH966f/LOOP0a7a，原檔保留；52骨重定向，新四套資源。12技能、Street Run三站、角色XP／兩槽／免費重置／淡色FX實裝；標準FIGHT不套成長，Demo不給XP。此條覆蓋前輪RPG僅提案／舊roster的現況，完整提案未做部分仍待辦。使用者要求收尾，不再擴功能；來源推實驗分支、Web不變。
