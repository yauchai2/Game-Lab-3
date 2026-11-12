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

- 2026-11-10 最新封面：見docs/COVER_NEON_CITY.zh-TW.md，主選單TITLE改為assets/ui/last_service/cover-neon-city.png，原生選單／Logo保持；ImageGen原創無臉青粉半身人物＋黑白街城／桃紅天空，無項鍊。原cover.png及builder是歷史模型版，請勿重新生成並當成當前使用的底圖。Web不更新。

- 2026-11-10 最新標題動畫覆蓋靜態預設：見docs/TITLE_MOTION.zh-TW.md，title_motion.gd為獨立3D封面場景owner，12Hz／376×360／8秒；純色無臉人物、黑白街城，原生UI不跟鏡頭搖。F2減少特效用靜態TITLE，離主選單停渲停鐘；不得用全域time_scale或中斷音樂，Web不更新。

- 2026-11-10 最新構圖：TITLE_ENSEMBLE.zh-TW.md覆蓋兩人／窄viewport／四段鏡頭。title_motion採640×360全幅投影、五人前後群像（四原角＋ZIP背景演員）、固定街角軸線／6°roll。左選單獨立覆蓋；減少特效用同場景渲染cover-ensemble.png。保留12Hz與離頁停渲停鐘，未新增多人戰鬥、可選角色或Web發佈。

- 2026-11-10 最新戰鬥規劃：COMBAT_ESCALATION_PLAN.zh-TW.md與references/combat-escalation-2026-11-10/user-supplement.zh-TW.md。沿同一pressure升溫（SURGE公開名）、同一Rhythm／Neon owner，先A＋B回饋／預輸入；高壓雙方窗口與敘事仍待原型／人手驗證。不要把使用者LLB分析當官方規則或本輪實作，Web不更新。

- 2026-11-10 此輪使用者明確要求「公開 Web 試玩版更新」，可部署本Lab可玩來源至gh-pages並覆核。採Godot4.7.2匹配官方Web模板、單執行緒，長BGM在Web強制STREAM（選角壓測樣本解碼曾記憶體上升）；之後沒有明確要求仍只同步來源。SURGE規劃不可冒稱已公開實裝。

- 2026-11-10 本聊天使用者確認工作流程：每輪完成驗證後commit／push到GitHub，回報branch及commit，使用者在GitHub Desktop Fetch／Pull再用本機Godot測試；不宣稱已操作其本機。SURGE工作目前接續codex/combat-escalation-next／草稿PR #6，避免每輪另開使用者要切換的branch。
- 最新SURGE現況見docs/SURGE_WINDOW_PROTOTYPE.zh-TW.md：A＋B基礎後，B獨立21步高壓比較窗口已加入明示練習fixture，B切BASELINE／WINDOW。尚未替換標準FIGHT／Demo／Street Run；真人比較、首分鐘完整教學及三站敘事仍待驗證／續作。pressure／Rhythm／Neon維持單一owner，Web不更新。

- 最新首分鐘切片見docs/FIRST_MINUTE_COACH.zh-TW.md：C進入四課主動教學，真事件驗連段／parry counter／付費追擊空擊／付費overdrive。100能量／近身／SURGE0是明示fixture；director不裁決傷害，不把自動student當真人學習。F5保留前課重試本課，Esc保存，無XP／存檔獎勵；其他模式隔離。LOOP首課採共通兩擊，不改實際擊退或招式數值。三站敘事、完整C與D仍待續；來源同branch，Web不更新。

- 2026-11-10 使用者更正：要求真正改善正式遊戲，不能再把新增教學／獨立原型當主要優化交付。最新正式玩法見docs/LIVE_COMBAT_IMPROVEMENTS.zh-TW.md：承諾式CPU攻防／角色資源、LOOP輕拳推離2.8／3.4、native hitstop與演出重疊消耗；原傷害／能量／大招長pose不改。Easy單鍵新手驗證明確選Easy，Normal／Hard可反制單鍵spam。仍同branch推送，公開Web不更新；Mac／真人平衡待測。

- 2026-11-11 黑衣人接入：見docs/BLACK_SUIT_ENEMY.zh-TW.md。基於main738c740的codex/black-suit-enemy；P2敵人4與四英雄／成長分離，原6bb9e9c2 GLB不變。black_suit_actor.tscn供演出／背景，根transform屬導演；沒有AI／傷害。故事／槍械／新地圖未接入，main及Web未更新。

- 2026-11-11 最新黑衣人修補與群戰見docs/BLACK_SUIT_SQUAD.zh-TW.md：runtime改derived/black_suit_repaired.glb（原檔保留）、97頸部權重／封閉補片／局部outline。FIGHTERS→SQUAD為3／4／5名獨立同場敵人，單進攻名額、玩家僅推進一次；群戰不給XP，退出須清除額外visual與simulation。舊單敵與Street Run保留；同分支、main與Web不動。

- 2026-11-11 最新使用者指定此branch並要求按影片做正式回合3D過場：現況 CITY_BREAKER.zh-TW.md。CityBreaker是KO段唯一camera／destruction owner，零生命真結算後才播，不改simulation或XP；沿用當局四角／原街景／原客機，可逆static batch／飛機分件。F2短版，Enter／Space先跳過、再Enter接下局，Esc保持result恢復。所有退出走clear；不要改成固定人物影片或另建獨立玩法。來源同branch／PR #6，Web不更新；參考片與程序幾何仍有差異，未宣稱逐像素完美。

- 2026-11-11 最新KO聲畫要求：見CITY_BREAKER.zh-TW.md最新節／evidence/city-breaker-fx。原CityBreaker正式KO入口擴充原創score、既有SFX bus、pause／clear及BGM duck，7-tap邊緣放射模糊／漫畫線／字卡／3D衝擊環／FOV反衝，14°roll上限。後製不模糊HUD，F2短版保持。原創音軌可由tools/build_city_breaker_audio.py重建；不要以原片音軌取代來源或把無聲舊預覽當最新。來源同branch推送，Web不更新。

- 2026-11-11 最新節奏覆蓋原10秒KO：正式播放5秒，以timing.json把原10秒作者時間非線性壓縮，保留撞樓／空爆短重拍、0.92秒KO收尾；playback_elapsed是真時鐘，age仍是作者時間。聲效按同profile重新合成5秒、不變調；不要用Engine.time_scale或把整段pitch_scale=2。來源同branch，Web不更新；最新證據evidence/city-breaker-fast。

- 2026-11-11 最新K.O.後要求覆蓋5秒直接結果：保留5秒基段，再追加3.2秒當局勝者近鏡／專屬離場，整段8.2秒。victory_exit.gd由同一CityBreaker時鐘掌管，四套程序骨架／方向與exit音軌；124°FOV＋桶形fisheye依真head anchor取景，真出框再出結果。clear必須還原near／fisheye、停止score；F2／暫停／重開保持。原GLB／simulation不變，最新證據evidence/victory-exits；來源同branch推送，Web不更新。

- 2026-11-11 最新完整過場要求覆蓋Demo endless／無自動重設歷史契約：見docs/evidence/round-flow/README.md。正式FIGHT／Street Run有2.8秒可跳過3D開場，練習即玩；Demo正常有限生命、真KO完整8.2秒後自動next round／next match，無XP、不在live fight補傷或改健康。round_theatre掌開場／稀疏0.28秒戰鬥魚眼，避讓Neon及CityBreaker；煙霧固定18＋12＋64上限。暫停／F2／R／F12／退出須清理lens與score。來源同branch／PR #6，Web不更新。

- 2026-11-11 最新指示覆蓋每回合完整KO：僅match_over零生命決勝才播CityBreaker，Street Run只在最後站／敗退結束；普通round_over短結算，Demo仍真勝負跨場loop。RESULT選單須在director結束後建立並驗visible controls，不能只驗finish_menu_open。正式Rush四面ArenaBox（6接觸／180tick／E20受身／無額外反彈傷害）與arena_cage，見docs/evidence/arena-box/README.md；不得無限刷新stun或改成螢幕座標物理。camera最後以雙人bounds避HUD；F2不改物理。來源同branch／PR #6，Web不更新。

- 2026-11-11 最新本聊天要求開始製作抽能力：見docs/ABILITY_DRAW.zh-TW.md及evidence/ability-draw。正式FIGHT第二回合1:1／Street Run第二站勝出／Demo共用THE DEALER真3D；局部stage profile、掃掠備援、一次抽取／領取、下一局真modifier與永久XP隔離，所有相機／人物可見性／聲音／duck可逆。NPC不替換戰鬥GLB，玩家不入鏡；2:0保持決勝KO。首版平地入口／程序人物、非逐像素原片復刻，Mac／真人驗收待辦。來源同branch／PR #6，Web不更新。

- 2026-11-11 本聊天更正NPC／機器入場：見evidence/ability-draw/entry-v2，原±5m／z-.25街景碰撞導致零位移已修正為±6m／z0；真出框／拖行／煞停及compact遮幕要保留。ABILITY_EQUIP_STORYBOARD.zh-TW.md與equip-storyboard.png僅規劃1.8秒腰側安裝，未接runtime；只拍手腰鞋不露玩家臉。等使用者Tripo NPC／機器後才換模／綁骨，保留來源與Web規則。

- 2026-11-11 使用者要求最早九格分鏡的NPC／機器三視圖供Tripo：已交references/ability-draw/tripo（NPC A-pose、整機設計、外殼生成版及prompt）。圖是ImageGen建模設計而非CAD投影，背面補完；機器建議手工或Tripo外殼＋獨立輪盤／輪子／拉桿／出貨蓋，不能假定整機生成已分件。尚無Tripo新資產，runtime不變。

- 2026-11-11 本聊天已提供275dc57f…機身與36d4f0c3…65骨NPC，覆蓋前述待模型狀態：見docs/ABILITY_DRAW_TRIPO_MODELS.zh-TW.md。原GLB／albedo byte保留，真骨架CC0 gait＋作者IK接觸／手指／代幣；機身窗口多層封面用包裝材質／outline開窗，活動件獨立。短入場／抽獎cue用原OGG解碼PCM（build_ability_pcm.py），原OGG／長BGM保持，避免重現的快速重開Ogg退出滯留；不要擅自改回舊程序人物／機殼。74項原生及有聲fixture有證據，Mac／真人待驗，腰側裝備仍未實作，來源同branch／Web不更新。

- 2026-11-11 使用者明確要求所有更新集中最常用branch：本輪合併黑衣人與combat-escalation來源至main，覆蓋舊「main不動」與各聊天來源分支指示。後續日常Fetch／Pull使用main，保留歷史分支及原始GLB；Web仍需明確要求。黑衣人4可播通用勝出；SQUAD保留多人鏡頭／短結算，不套雙人過場或抽能力。整合驗證見docs/evidence/main-integration。

- 2026-11-11 最新抽獎要求：見docs/ABILITY_DRAW_RHYTHM_UI.zh-TW.md。2.05秒入場／2.20秒逐輪抽獎；必須新按DRAW才抽、結果另按CONTINUE，包含Demo，覆蓋原Demo自動抽領契約。共用bitmap字體／原生Button theme、放鍵與160ms防穿透，原模型／音訊／跨場景入口保留，85項通過；Web不更新。

- 2026-11-11 使用者最新更正覆蓋前輪Demo手動契約：見docs/ABILITY_CORE_POOL.zh-TW.md。Demo offer等3秒／result等3.5秒後自動抽領，可手動提前，pause凍結；正式FIGHT／Run仍手動。獎池9種等權，6新modifier及9圖示／輪盤、active-core HUD／ECO共用cost供AI及meter刻度。SIPHON真命中回2、上限實回12、不能復活；所有能力下一局限定、不存XP。263項通過，原GLB／音軌及公開Web保持；Mac／真人平衡待驗。

- 2026-11-11 使用者也要求同步codex/combat-escalation-next：以最新91db1f1合併mainffffd15，保留九核心／Demo自動抽領（覆蓋舊Demo手動規則）及黑衣人群戰修補。本輪推指定開發分支，不改main或Web；144項整合檢查見docs/evidence/branch-sync-combat-escalation。
- 2026-11-11 最新澄清：多面球狀反彈僅指定技能／大招，覆蓋一般重擊／挑空／投技皆觸發。ServiceProfiles.move以ricochet旗標opt-in：四人overdrive最後重擊、RIVET preload2 special、HUSH sample_boost special；其他normal／未強化技能不啟動。平常不顯示臨時盒或限制跳躍天花，僅反彈效果期間。原RESULT／決勝KO與能力抽取保持，見evidence/ricochet-scope；同branch推送、Web不更新。

- 2026-11-11 本聊天最新已要求以新影片實作抽獎後裝備：見docs/ABILITY_EQUIP_RUNTIME.zh-TW.md，覆蓋腰側僅規劃。結果按EQUIP／Demo停3.5秒後播4.10秒，F2開始1.15秒；使用當局五原選角副本、只拍手腰腿鞋，正式fighter以Hips跟隨九核心腰掛。一次套用在演出後，skip不重抽、cancel無獎、pause／clear還原；不重播多餘第三局人物開場。345項通過／新原創PCM，原GLB／XP／Web保留，Mac／真人待驗。

- 2026-11-12 使用者要求詳細故事波次／敵碰敵連鎖／大型Boss／人海遠鏡頭規劃：見docs/STORY_WAVES_PLAN.zh-TW.md。本輪僅設計，六關／新敵型／Boss／傷害倍率／相機／核心兩關區段都未實作或驗證；不要把提案寫成已完成功能。未來若開始實作先M1三波切片；保留既有FIGHT／Demo及指定技才開四面盒契約，Web不更新。

- 2026-11-12 使用者已要求「開一個分支實做」：codex/story-waves-m1的M1已可玩，見docs/STORY_WAVES_RUNTIME.zh-TW.md，覆蓋前輪M1僅規劃。STORY入口3波／N-R-G／6人、有限真撞體、同場retry及遠鏡頭；無XP／Boss／六關／持久checkpoint。StorySimulation繼承Squad，舊模式委派保持。只推獨立分支／草稿PR，不把此次分支工作自動合併main或發佈Web；原GLB及指定技才開四面盒規則保持。

- 2026-11-12 最新城市ARPG詳細提案見docs/CITY_ARPG_PROGRESSION_PLAN.zh-TW.md。本輪僅規劃：新故事保證能力漸解鎖、主選單入口、48節點／25點、城市刷圖／三槽永久裝備／兩貨幣／定向抽裝保底未實作。故事晶片擬持續下一整張圖，覆蓋舊兩關區段提案；標準模式九核心契約不改。保留舊存檔能力；先一區小循環再擴六區Boss，現況仍M1三波。只推codex/story-waves-m1，不自動合併main或發佈Web。

- 2026-11-12 最新使用者要求Hades式回城升值／故事，缺assets先簡單做：已接主選單STORY→45°正交程序城市／五站／六區18遭遇，見docs/CITY_ROGUELITE_RUNTIME.zh-TW.md，覆蓋城市僅規劃。12節點8點、基本L三級、三槽數值裝／保底、短對話、永久與局內分層、獨立city_v1快照存檔；敗退清局內、清場Enter回城。FREE PLAY收FIGHT／SQUAD／Demo，舊M1保留FIGHTERS。六區共用街道佈置、隊長沿盾衛，沒有巨型Boss／完整48樹／T1–5／城市九核心，不得冒稱。226項最終驗證，Linux llvmpipe非真人／Mac；只推codex/story-waves-m1／草稿PR #12，main與Web不動，原GLB／舊進度保持。

- 2026-11-12 最新要求稍提高解像度並完成城市成長：現況docs/CITY_PROGRESSION_EXPANSION.zh-TW.md。960×540／較清晰title-city-roster覆蓋舊640要求，nearest／無AA／toon輪廓／logical UI保持、fractional填1280視窗。48節點25點／一keystone、縮放拖曳／相連／互動天賦，T1–T5合約四詞綴／seed／3次／返圖晉級，真掉裝／詞綴／特製取捨／比較／各角三槽與倉庫已實作。v1城市遷schema2保技能錢裝、退樹保等值預算、.v1.bak；公開city驗證入口轉新套件舊fixture保archive。359項／960原生圖，仍非真人／Mac／FPS；巨型多階段Boss／完整劇情美術與城市九核心仍待做。原GLB、FIGHT／Demo／舊進度保持，只推codex/story-waves-m1／草稿PR #12，不合main／Web。

- 2026-11-12 最新使用者要求實作所有既定ideas並技巧優先：現況docs/CAMPAIGN_COMPLETE_RUNTIME.zh-TW.md，覆蓋上一輪Boss／城市核心／新場景／完整短篇未做。六區18場／六章、兩種多階段巨型Boss、有限增援／重裝干擾隊長／危險地面／破箱連鎖／分支補給休息、五技能課程／12專屬招式、九核心真DRAW→EQUIP、工坊及裝備外觀；12原創Blender低模GLB可重建（使用者本輪允許生成模型），原Tripo保持。schema3保v2樹裝及局內進度並留.v2.bak。裝備直傷12%、條件總50%／parry60%、核心減傷／省能合併上限及Boss閉甲限制；裸裝四角／全故事正常輸入測例可過，九種極端裝攻擊spam敗於最終Boss，非真人／Mac／FPS驗收。證據evidence/campaign-complete。仍只推codex/story-waves-m1／草稿PR #12，不合main／Web。

- 2026-11-12 最新澄清：整個遊戲包括UI／文字提高解像度。正式root／title／city1280×720覆蓋舊960，logical UI在預設視窗1:1；選角cards192×256／hero448×512。保留nearest／無AA／bitmap／toon，不能又將UI先縮低再放大。70項原生檢查見docs/evidence/whole-game-720p；未驗硬件FPS／Mac，UI runner退出8ObjectDB警告明示未解。仍同branch／PR #12，main及Web不動。
