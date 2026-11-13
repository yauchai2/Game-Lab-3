## 2026-11-13：HUSH／LOOP第三輪驗證

[evidence/hush-loop-motion](evidence/hush-loop-motion/README.md)：122新motion／合法起招／雙朝向／F2／hitstop／owner交還／握點棍尖／真sample／放點脈衝／明示encore變體＋90ZIP/RIVET＋19首輪＋46規則＋104死亡／群戰＋26FX，共407全通過。七motion／recipe腳本七類fatal warning通過；全19suite仍15/19，同四處基線失敗。固定1800 simulation ticks、同指令hash，471b21e與新版狀態SHA均022cef61…、21真命中、0sim差異／呈現改寫。ZIP／RIVET22類逐tick骨socket相同，原11曲線及19原庫hash不變。15秒450幀連續play實錄，真parry取得／消耗sample、正常兩點pulse、一點encore；各段1真命中、後兩段各1真pulse事件。未預塞sample／node／damage（對手首jab為明示合法起招fixture）；骨socket／握姿不等於地形IK、真人或硬體FPS驗收。accepted原生log無ERROR／SCRIPT ERROR，原GLB／判定／BGM／公開Web不變。Linux4.6.3 llvmpipe／Dummy，Mac／真人／GPU待驗。

## 2026-11-13：ZIP／RIVET新CC0庫驗證

詳[evidence/street-motion-library](evidence/street-motion-library/README.md)：90新motion／真確認／socket＋19RIVET＋46角色規則＋104死亡／群戰＋26FX共285項通過。六motion／recipe腳本七類fatal-warning通過；全19script suite15/19，與前輪同四個既有失敗。相同指令hash的1800 simulation tick在25c83ec與新版狀態SHA均022cef61…，21真命中、0逐tick差異、0呈現改寫。舊Demo迴圈probe報告受並行Godot視窗搶焦點自動暫停影響，保留但不作等價證明；獨立錄影新增每幀play檢查，三段付費真命中2/3/1，初次失敗另存。四角22類抽樣，HUSH／LOOP骨socket與前輪相同；新sourcepreview與60Hz重建hash一致。原GLB／19clips／判定／BGM／Web不變。Linux4.6.3 llvmpipe／Dummy，不是Mac／真人／GPU效能／地形IK驗收。

## 2026-11-13：RIVET地面動作切片及四角基準

詳[evidence/fighter-motion](evidence/fighter-motion/README.md)：19新原生＋46角色機制＋104死亡／群戰回歸全通過；四個變更runtime七類warning當error編譯通過。全19腳本strict為15/19，未改基線同四處失敗，前後log保留；不能宣稱全套strict通過。兩組角色1800步相同玩法SHA／事件完全一致；其餘三角22類每類90tick骨socket完全相同。RIVET五地面招Foot骨tick10後位移0，屬固定source stance遮罩，不是鞋幾何／地形IK量測；hold7/8、真二階放拳、F2／hitstop／左右朝向、owner交還通過。12秒360幀正常L按／持／放三段重設練習，3次真命中，有聲錄影，約67秒錄製，非真人或硬件FPS。accepted原生log無ERROR／SCRIPT ERROR；初次缺快取已editor import後重跑。Mac／真人／逐幀全招與外部新素材待驗；本輪原GLB／判定／BGM／Web不變。

## 2026-11-13：四英雄動作 review 與詳細方案（僅文件）

基線main／origin/main均7aac2c1、工作區起始乾淨。依[FOUR_FIGHTER_MOTION_REVIEW_PLAN.zh-TW.md](FOUR_FIGHTER_MOTION_REVIEW_PLAN.zh-TW.md)查閱所有動作家族的來源選片／層疊／時序／視覺變形與選角／勝出／據點路徑；四份GLB直接解析皆65 joints、0 animations；現用JSON動作庫19clips。只目視兩個歷史影片抽格（ink-fx/after第3秒、last-service-runtime/zip-rivet-demo第5秒），未聲稱當前逐招錄影或完整影片審查。以正常HTTPS讀四官方入口回Tunnel connection failed:403 Forbidden，未確認最新目錄／授權／價格及新下載。Markdown本地連結與git diff --check覆核；無runtime修改，因此未跑Godot玩法測試；未驗Mac／真人／GPU效能。所有製作門檻和工期為提案，非本輪測試結果。

## 2026-11-12：按原圖重做據點＋15秒動態（覆蓋粗模）

使用者回報上一版差距大，要求照指定圖、移除無關物件，並給15.083秒動畫。正式入口改用reference_workshop.gd：固定鏡頭投影空場貼圖／3D深度片與可走地面、既有四英雄／Dealer骨架、活動橙色臂、掃燈／光斑／煙／電光／閘門開口與門內剪影；Loop移向機器後回位。移除接線大機／戰利品牆／站位框，天賦綁LOOP區，Tab展開HUD。這是**2.5D／3D混合固定視角方案，不是全角度實體建築**；人物外形／姿態仍有差異，不稱逐像素或逐來源幀完美。詳[NIGHTSHIFT_REFERENCE_REBUILD.zh-TW.md](NIGHTSHIFT_REFERENCE_REBUILD.zh-TW.md)。

[15秒原生預覽與對照](evidence/nightshift-reference/README.md)：450幀／30fps，15.000秒；輸出配既有menu.ogg低音量，未用附件音軌。211回歸＋15strict通過，accepted無ERROR／SCRIPT ERROR；另有時間線採樣與六站／F2檢查。原Tripo不改、schema3／戰役經濟保持。Tripo必需0件，若做全角度／人物輪廓精修，優先Dealer與指定英雄，再DJ台／音箱／機器殼；具體規格見references/nightshift-hub/TRIPO_REQUIREMENTS.zh-TW.md。只更新codex/nightshift-hub／草稿PR #19，未發Web；Mac／真人仍待驗。

## 2026-11-12：夜班維修場回城場景

使用者要求將確認的黑白工廈／桃紅背景／低模角色概念落成可互動遊戲地圖。基於最新main6fdd3a6，在codex/nightshift-hub改造既有STORY城市，保留CityProfile／CityCampaign／schema3與六區戰役。實際3D剖面場景、可走DJ閣樓、六設施、靠近E／點設施或1–6實走、點地尋路、三位正式英雄同伴（換角無重複）、原Tripo黑白wrapper、章節戰利品／短環境動作已接入。新場景使用程序幾何，原GLB保持；另交F6預覽與可導入Blender的衍生nightshift_workshop.glb，無需新增Tripo。詳[NIGHTSHIFT_HUB.zh-TW.md](NIGHTSHIFT_HUB.zh-TW.md)。

[實際引擎畫面與驗證](evidence/nightshift-hub/README.md)：211行為／原生／城市戰役回歸＋14嚴格編譯，共225項通過，accepted無ERROR／SCRIPT ERROR。樓梯轉角／延遲焦點／舊fixture STORY鍵與排版等待已修，初次失敗保留。Linux4.6.3 llvmpipe／Dummy，非Mac／真人／FPS驗收。這是概念的可玩3D重建，非逐像素完稿；後續角色關係／黑箱劇情回城演出仍屬規劃。只推任務分支／draft PR，未發Web。

## 2026-11-12 開場貼近參考影片

Linux llvmpipe：截圖對照參考影片；verify_story_opening 結果見 PR 說明。非 Mac／真人／真聲音。

## 2026-11-12：開場 polygon／警告截圖修正

修復眼鏡 glint 零半徑及細小ray的triangulation錯誤：略過不可見burst並以draw_primitive直接提交三角形；整理外層title_progress、未用_t與equipment metadata的獨立ternary。19腳本／七類fatal warnings、288組原生burst及既有37項開場流程通過，15個3D抽格無ERROR／SCRIPT ERROR。證據[evidence/opening-bugfix](evidence/opening-bugfix/README.md)。來源codex/fix-opening-polygons；Godot4.6.3 Linux llvmpipe，Mac／4.7.2待使用者覆核，Web未更新。

## 2026-11-12：完整短篇故事、雙巨型Boss與技巧優先成長

最新見[CAMPAIGN_COMPLETE_RUNTIME.zh-TW.md](CAMPAIGN_COMPLETE_RUNTIME.zh-TW.md)，覆蓋下方「Boss／城市九核心／獨立場景／完整短篇故事未做」的舊狀態。六區18場、兩／三階段Boss與讀招弱點、有限增援／新敵型、危險地面預告／破箱連鎖、分支休息與補給、六章劇本／三NPC／五能力課程／12專屬招式三選二、九核心真DRAW→EQUIP與一次性出擊預算、工坊及裝備骨架外觀已接正式STORY。12個原創低模GLB與Blender來源可重建；原Tripo及英雄GLB保持。schema3保v2樹／裝／局內進度並留.v2.bak，v1遷移仍保持。

裝備直接增傷封頂12%，不增最大HP／parry窗口／無敵；總條件增傷50%／真parry反擊60%，Boss閉甲／弱點限制不可略過，合約HP／傷害亦封頂。四角從零合法掉落／解鎖／付費補給通18場、八組裸裝讀招Boss通關；九種極端裝／核心攻擊spam都敗於最終Boss。這是自動測例，非真人平衡或FPS驗收；簡單原創低模及無配音仍是本版本美術範圍。本輪437項最終通過（規則50／原生23及完整回歸），最終log無ERROR／SCRIPT ERROR。證據見[evidence/campaign-complete](evidence/campaign-complete/README.md)。只推codex/story-waves-m1／草稿PR #12，main／Web不動。

## 2026-11-12：960解像度、完整天賦與合約刷圖已接實作

見[CITY_PROGRESSION_EXPANSION.zh-TW.md](CITY_PROGRESSION_EXPANSION.zh-TW.md)。依最新要求由640×360升960×540，title／city及roster同步、保留最近鄰／toon輪廓／bitmap字體、logical UI與1280視窗（fractional填滿）。故事入口／能力解鎖沿既有；天賦擴48節點／25點／單關鍵天賦與真連線、縮放／拖曳／免費重置；真首次撞體擴散與parry／追擊有界回能。六區主題程序佈置、T1–T5合約seed配方／四詞綴／三次機會／同階返圖與兩次完圖升階；每場真裝備掉落、詞綴／四特製取捨、比較、各角配裝、60背包＋120倉庫。

schema2沿原city_v1路徑，保留技能／錢裝、退舊樹等值點數，首次交易留.v1.bak；舊標準模式／GLB不改。巨型Boss／完整劇情及全新場景美術仍待做；城市仍簡單幾何，戰鬥六區共用基底。來源只推codex/story-waves-m1／草稿PR #12，main與Web不動。

[359項驗證／960畫面](evidence/city-expansion/README.md)：城市86、原生22、strict18、M1 37／二段跳62／戰鬥34／九核心75、原生整體15／Ink10；最終log無ERROR／SCRIPT ERROR。四角Easy普通輸入、真掉落／解鎖通首區，無補血傷害注入；後期結算採fixture，非真人／Mac／FPS／實聽驗收。舊v1城市fixture歸檔，公開verify_city入口改跑新套件；兩舊UI framebuffer斷言按新960契約更新，其他斷言保持。

## 2026-11-12：Hades式城市回城循環已可玩

最新使用者要求覆蓋前輪純城市圖／規劃狀態，見 [CITY_ROGUELITE_RUNTIME.zh-TW.md](CITY_ROGUELITE_RUNTIME.zh-TW.md)。主選單STORY進45°正交可行走安全城、五互動站；六區×三場共用街道佈置、回城升技／12節點8點天賦／三槽永久裝備／保底抽裝／短故事。清場銀行化錢零件並選一次臨時強化，敗退清出擊、保留永久進度；獨立city_v1存檔／備援／交易回滾／逐場快照。標準FIGHT與Demo在FREE PLAY，原M1預覽仍在FIGHTERS；原GLB及舊進度不改。

[226項驗證及畫面](evidence/city-hub/README.md)：城市62／原生17／strict14／舊M1 37／二段跳62／戰鬥34；accepted無ERROR／SCRIPT ERROR。四角Easy普通輸入無裝備補血通首區，後期開區採fixture；Linux軟體渲染／Dummy，Mac與真人平衡待驗。城市人形／建物程序佔位、戰鬥六區共用基底；未有巨型多階段Boss、完整48點樹／T1–T5／複雜詞綴／九核心城市接入。本輪只推codex/story-waves-m1／草稿PR #12，main與Web保持。

## 2026-11-12：城市ARPG設計文件核對

本輪只新增 [城市成長規劃](CITY_ARPG_PROGRESSION_PLAN.zh-TW.md) 並同步紀錄。核對既有三階角色成長／兩技能槽、主選單五項、九核心與M1實際範圍；區分必得能力、可洗天賦、永久裝備、臨時晶片。文件數量核對：28＋12＋4＋4＝48節點；19等級點＋6主線點＝25點；抽裝提案25＋55＋19＋1＝100%。檢查文件diff、連結與runtime未變；沒有執行或宣稱新玩法／經濟／存檔／平衡測試。main及Web不更新。

## 2026-11-12：故事波次M1

[accepted報告與原生圖](evidence/story-waves/README.md)。最終287項：Story37、native Story17、startup warnings11、Arena65、二段跳62、戰鬥34、UI37、回合24，對應log無ERROR／SCRIPT ERROR，VSync警告保留。四英雄Easy普通輸入完整通三波，不注入傷害／補血／重設；真pointer／J／↓+K／Esc／Enter／R及六骨架，另有邊界fixture；玩家投影約68內部像素。基線舊Demo測試同樣23/24的重複intro預期已按現行裝備契約修正且增加真equip觀察，初次失敗保留。Linux4.7.2 Compatibility llvmpipe／Dummy，不是Mac／真人／硬件FPS／實聽驗收。未做Boss／六關／持久checkpoint；任務分支交付，main與Web不更新。
## 2026-11-12：正式戰鬥VFX實作完成

Godot4.6.3 Linux Compatibility llvmpipe／Dummy：26新FX＋14 strict＋380相關回歸＝420通過；最終log無ERROR／SCRIPT ERROR。1800步前後玩法／資源／事件SHA一致；12秒360幀Movie Writer含真混音，AAC解碼peak .507、零滿幅樣本，另6混音檢查。原生錄製約37秒，非Mac／硬件FPS或聆聽驗收。舊Rush600tick不足（實際698勝出）、Neon永不結束與多餘第三局entry假設已修fixture；headless裝備等draw超時改原生113項通過，初次／基線log保留於evidence/ink-fx。詳COMBAT_VFX_RUNTIME.zh-TW.md，Web未更新。

## 2026-11-12：SEPAK原片視覺分析補件

已取得13.792653s／1440p60原片，8fps全時間範圍取樣＋0.55／1.35／12.0起三段來源連續幀，觀察分段弧、雙色煙尾、小腳塵、背景退讓及近鏡，詳SEPAK_VFX_VIDEO_STUDY.zh-TW.md與references/vfx-quality-2026-11-12。未正常速度含聲播放／聆聽，未知引擎／素材／內部公式；LLB新附件超過32MiB工具上限，未取得，需較短或壓縮版補分析。修訂先做小白塵、分段弧、指定事件短雙色煙；runtime與Web未改。

## 2026-11-12：戰鬥VFX研究範圍

本輪為文件研究，基線ef3f8d3；核對Godot640×360 Compatibility、active fight_vfx／impact_shapes／fight_session／street_smoke／Neon路徑，看compact-hud/fight.png及round-flow兩圖；舊combat-escalation/zip-rivet.mp4之3–15秒取12張1Hz接觸表，不能驗短閃／聲音／當前build。X原片web403、替代讀取未取得、cloud browser初始化失敗；未觀看。來源候選查Kenney官方CC0頁、GDQuest及Real Time VFX拆解、Vefects產品搜尋，未下載或驗引擎相容。僅文件檢查與git diff --check，不跑runtime測試、不宣稱Mac／真人／效能通過；Web未更新。

## 2026-11-12：故事波次設計文件

本輪只新增STORY_WAVES_PLAN.zh-TW.md及相關紀錄。查閱基線main e725c99的三站Run、黑衣人群戰、opt-in反彈、九核心與裝備契約；文件區分既有與待做。波次／角色量／倍率／像素高度／時長是試作目標，未跑新玩法測試，未宣稱現有可支援10–12同場或大型Boss。僅檢查文件diff與runtime未變，原遊戲及Web不更新。
## 2026-11-12：開場配樂與音效重做

- `verify_story_opening` 35/35（新增「開場期間主選單曲靜音」「標題後淡入」）。Godot 4.6.3 Linux、Compatibility／llvmpipe、Dummy 音訊。
- Movie Maker 真實啟動錄影：錄到的音軌與 `score.wav` 每 0.25 秒響度曲線一致、沒有時間偏移；18 秒後主選單曲淡入。
- 量測：節奏段 RMS 約 −11 dBFS、抽音段約 −34 dBFS、峰值 −0.5 dBFS；3–6 秒頻段比例（20–60／60–150／150–400／400–1.5k／1.5–5k／5k+）為 −5.0／−4.5／−8.4／−9.3／−15.7／−17.7 dB，參考片約 −5／−4／−8／−9／−13／−18。
- 未驗證：真人試聽。律動好不好聽、音色是否刺耳、音效與畫面觀感都只能由人判斷；Mac／實機喇叭亦未測。

## 2026-11-11：開機劇情開場

verify_story_opening 34/34（擁有權、六鏡對應、無狀態取樣、黑箱／車／黑衣人節點、減少特效、暫停、音樂duck、自動結束、相機／街景還原、旗標存取、重播與跳過）。Movie Maker真實啟動錄影確認開場→主選單及第二次啟動直入主選單。回歸：reference_ui 37/37、ability_draw 69、black_suit 35；round_flow 23/24，失敗項於未修改e725c99相同。Godot4.6.3 Linux llvmpipe／Dummy音訊，非使用者本機、真實音效或觀感驗收；4.7.2 warning工具未跑。

## 2026-11-11：正式抽獎後 3D 裝備（最新）

最後合併最新main compact HUD（fda61d1），額外21項原生整合及嚴格8項重跑通過；交付main與codex/combat-escalation-next，Web不動。

見 [ABILITY_EQUIP_RUNTIME.zh-TW.md](ABILITY_EQUIP_RUNTIME.zh-TW.md)。按EQUIP／Demo結果停3.5秒後，當局原選角演出副本接取→握緊→腰扣→鎖定→能量到鞋→踩地，4.10秒（F2開始1.15秒）。九核心真腰掛跟隨骨盆保留到下一局重置；不露臉，原街景／stage profile沿用，聲效／魚眼／短模糊／震動／漫畫線／煙塵同步。先演再一次套用，Space跳過不重抽；pause／cancel／R恢復。113新＋69流程＋75核心＋34戰鬥＋46角色／成長＋8嚴格編譯＝345項，證據evidence/ability-equip。原GLB／XP／Web保持，Mac／真人待驗；覆蓋舊腰側裝備僅規劃。

## 2026-11-11：精簡HUD

[最終accepted log、JSON及原生圖](evidence/compact-hud/README.md)。HUD21／二段跳原生12／原生UI音樂37／嚴格編譯8，共78項通過，accepted log沒有ERROR／SCRIPT ERROR。初次typed Array清理、舊fixture Space被intro消費及mixer快速退出錯誤保留在initial-attempts，正式結果以accepted為準。Godot4.7.2 Linux Compatibility llvmpipe／Dummy，非人手可讀性／Mac驗收；保留simulation、費用、GLB、音樂transport和歷史圖片。Web未更新。

## 2026-11-11：死亡姿態／群戰屍體貼地

[前後量測、圖及完整log](evidence/grounded-death/README.md)。基線7d3cab2五角色骨盆／身體懸空已重現；正式修正為完整死亡軌跡、穩定死亡clip、已落地屍體按skin頂點貼地及非focus結果落地。新native104/104以獨立renderer bake驗證地面接觸、兩朝向／F2、無資料改寫與生者跳躍；另strict8/8、規則／結果33/33、回合／KO189/189，共334項通過，最終無ERROR／SCRIPT ERROR。Linux Godot4.7.2 Compatibility llvmpipe／Dummy，不是Mac／真人／硬件音訊驗收；Web不更新。

## 2026-11-11：同步 main 至 codex/combat-escalation-next

使用者明確要求也推到codex/combat-escalation-next。以遠端最新91db1f1合併main的ffffd15，保留九核心與Demo定時自動抽領，以及main的黑衣人群戰／頸部領帶修補／過場相容處理，不強推、不改Web。此輪只推指定開發分支；main維持ffffd15。最新Demo自動節奏以ABILITY_CORE_POOL.zh-TW.md為準，覆蓋較早手動Demo契約，一般FIGHT／Street Run仍手動。

合併後144項通過：九核心75、群戰規則35、原生群戰10、原生回合24；無ERROR／SCRIPT ERROR。Godot4.6.3 Linux Compatibility／llvmpipe／Dummy，非使用者本機或真人平衡驗收。證據docs/evidence/branch-sync-combat-escalation。

## 2026-11-11：九核心獎池與 Demo 延時自動抽領（最新）

## 2026-11-11：反彈限指定強化技能／大招

使用者澄清球狀連續反彈只屬特殊攻擊／大招，覆蓋前輪普通重擊／挑空／投技也發射的範圍。一般jab／cross／heavy／finisher／launcher／meteor／air_finisher／air_counter／grab及未強化special不啟動ArenaBox，保留原擊退／既有單次牆彈。四角色大招最後重擊（ZIP連打末段）及RIVET滿蓄、HUSH強化special由move metadata明確opt-in；傷害／消耗不改。

圍場只在反彈效果期間可見，平常不加臨時天花限制。仍有6接觸／180tick／E20受身、衰減、跟鏡與F2。65反彈規則＋25原生結果／鏡頭＋62二段跳＋10重砲＋7Demo＋34戰鬥＋75能力核心共278項通過；原結果頁修復、決勝KO及能力抽取功能保留。[新證據與大招預覽](evidence/ricochet-scope/README.md)。同branch／PR #6來源更新，不發佈Web，真人／本機驗收待辦。

見 [ABILITY_CORE_POOL.zh-TW.md](ABILITY_CORE_POOL.zh-TW.md)。Demo 代幣展示3秒後自動抽，獎品展示3.5秒後自動領取；覆蓋上一輪Demo必須手動的契約，正常模式仍手動。獎池3→9：新增FURY增傷15%、PLATE減傷15%、FLOW命中能量30%、ECO技能耗能-20%、BREACH盾損25%、SIPHON命中回2／整局最多12HP。九種等機率、下一局限定，實際simulation／AI節能門檻／HUD刻度及圖示／輪盤色彩皆接入。263項通過，證據evidence/ability-draw/expanded-pool；原GLB／音訊／XP／公開Web保持，Mac／真人平衡待驗。

## 2026-11-11：main 收入最後一筆遠端更新

## 2026-11-11：Godot4.7.2腳本警告覆核

[完整前後log／重現方式](evidence/godot-warnings/README.md)。官方Linux4.7.2.ed1daf0bf下，啟動前將static_called_on_instance／incompatible_ternary／shadowed_variable_base_class／integer_division設Error，基線ffffd15重現15項，修改後5檔全部通過。另90無視窗規則、189原生回合／KO、85抽獎流程／Tripo模型，共369項通過，最終log無ERROR／SCRIPT ERROR。最初動態warning設定未觸及快取的探查與editor清理警告保留，不列作通過證據。Compatibility llvmpipe／Dummy audio，不等於使用者Mac／音訊裝置測試；未宣稱全專案所有類別警告皆為零。匯入metadata／舊證據已還原，Web未更新。

推送前再次核對遠端，combat-escalation-next已從3389fa9前進至3ea0691，故再合併該提交。包含手動DRAW／CONTINUE、2.05秒入場／2.20秒逐輪抽獎、新音訊及共用bitmap UI；Demo也等待玩家確認，覆蓋下方自動抽領的歷史描述。群戰／黑衣人相容處理保留。更新回合測試以明示Enter確認抽獎，不移除最新手動要求。

最新合併來源再跑109項原生檢查：回合24、模型22、抽獎流程／輸入／節奏63，全部通過，無ERROR／SCRIPT ERROR；證據見evidence/main-integration/latest-final。前一整合477項與初次測試器失敗保留，非宣稱使用者本機／真人驗收。兩次合併保留987d4d2、3389fa9、3ea0691完整歷史；日常取main，Web未更新。

## 2026-11-11：手動抽獎、節奏及共用字體（最新）

見 [ABILITY_DRAW_RHYTHM_UI.zh-TW.md](ABILITY_DRAW_RHYTHM_UI.zh-TW.md)。2.05 秒入場／2.20 秒抽獎，三輪鎖定後靜拍再揭曉；必須新按 DRAW，結果另按 CONTINUE，Demo 也等待玩家，覆蓋舊自動抽領。刪減口號與裝飾、統一黑白桃紅青綠 UI；修正獨立 Button 未繼承遊戲 bitmap Theme。63 流程／輸入／節奏＋22 原模型檢查通過，原生有聲證據在 evidence/ability-draw/rhythm-ui；原模型／音訊保留，Mac／真人待驗，Web 不更新。

# 驗證紀錄與證據範圍

## 2026-11-11：D3 飛機掠過

`verify_flyby_event.gd` 8/8（headless）。見 [TIME_OF_DAY.zh-TW.md](TIME_OF_DAY.zh-TW.md)。

## 2026-11-11：G5／G6／G8

`verify_secret_notes.gd` 9/9，`verify_banter` 129、`verify_time_of_day` 12、`verify_street_tags` 27（headless）。非 Mac／真人驗收。

## 2026-11-11：街區標記

`verify_street_tags.gd` 27/27 headless；兩張 xvfb／llvmpipe 畫面。非 Mac／真人驗收。見 [STREET_TAGS.zh-TW.md](STREET_TAGS.zh-TW.md)。

## 2026-11-11：角色台詞與對手記憶

`verify_banter.gd` 107/107（headless）＋兩張 xvfb／llvmpipe 畫面。非 Mac／真人驗收。見 [BANTER.zh-TW.md](BANTER.zh-TW.md)。

## 2026-11-11：時段預設

`verify_time_of_day.gd` 11/11（headless），xvfb／llvmpipe 四時段截圖。`verify_combat_polish.gd` 的靜音啟動斷言失敗於未改動基線同樣重現（非本次造成）。其餘既有套件未全數重跑；非 Mac／真人驗收。詳見 [TIME_OF_DAY.zh-TW.md](TIME_OF_DAY.zh-TW.md)。

## 2026-11-11：來源集中整合至 main

使用者要求「把所有的更新都推到最常用的branch」。以 main738c740 為基礎，整合黑衣人分支987d4d2與正式戰鬥／過場／抽能力分支3389fa9，保留雙方提交及來源資產；往後 GitHub Desktop 選 main Fetch／Pull。此節覆蓋下方歷史的「main未更新」狀態；公開Web不更新。

同時處理整合相容性：黑衣人索引4支援進場名稱／顏色、通用步行勝者離場及既有HUSH離場音軌；群戰保留多人跟鏡與短結算，不套雙人進場／決勝KO／回合抽能力。四英雄正式回合演出、有限生命Demo及抽能力保持；合併空連預算helper與ArenaBox排除，保留3位數群戰倒數。

合併來源已跑477項最終檢查：146無視窗規則、177原生UI／結果／回合／勝者／材質、154群戰／黑衣人／Tripo抽能力。最終無ERROR／SCRIPT ERROR；Linux Godot4.6.3 Compatibility／llvmpipe／Dummy，非使用者Mac或真人手感驗收。最初round-flow 19/23的測試器在單一引擎影格內跑完整Demo，抽能力防重複確認阻止第二次動作；改為定期讓出真引擎影格後24/24。初次失敗與最終結果均保留在 [整合證據](evidence/main-integration/README.md)。


## 2026-11-11：群戰與修補版模型

[完整證據](evidence/black-suit-squad/README.md)：35群戰規則＋9原生群戰＋32修補版單敵＋46角色資源＋45正式戰鬥＋62二段跳＋25防禦＋37原生UI＋6材質，共297項通過。確認同場獨立血量、多目標真命中每人一次、一個攻勢名額、全部倒下才勝利及全模式退出清理；三階站立診斷有真攻擊，最短受擊間距123／92／68 tick。修補前後原生正／側／後近鏡、97頸部重權重與4個封閉補片（無boundary edge）、1208面／65關節、權重誤差5.22e-8、原始SHA不變。Godot4.6.3 Linux Compatibility／llvmpipe／Dummy音訊，最終無ERROR／SCRIPT ERROR；VSync警告保留，Mac／真人手感／實聽待驗收。

## 2026-11-11：黑衣人接入

[報告及原生畫面](evidence/black-suit/README.md)：32敵人原生整合＋46四角技能＋62二段跳＋25防禦＋37原生UI＋6材質生命週期，共208項通過。原GLB hash比對、有限值／權重／joint與vertex索引／貼圖解碼另見references/characters/black-suit/inspection.json。實際指標選P2、真simulation命中與招架、30秒自由AI、三視窗、保存／Street Run還原與角色場景根transform均覆核。Godot4.6.3 Compatibility／Mesa llvmpipe／Dummy audio；最終native log無ERROR／SCRIPT ERROR，保留不支援VSync警告。初版測試器step呼叫錯誤、Dummy material診斷及早期退出警告保留在證據說明，不算通過；已改native-only及退出等待。不是Mac／硬件效能／真人平衡或喇叭實聽驗收。公開Web未更新。

## 2026-11-11：main整合核對

合併來源4177ef9至main54a520d，無衝突。以Git tree object ID核對godot及tools，兩者與4177ef9完全相同；原main的docs/JSR-BRC-style-reference.md亦與來源相同並保留。只更改整合紀錄，沒有重跑引擎測試或聲稱修正上輪四個舊測試失敗。既有二段跳／正式戰鬥驗證詳見docs/evidence/double-jump/README.md。公開Web分支沒有更新。


## 2026-11-11：故事解鎖、同鍵盤雙人、雙手柄

[規格](LOCAL_VERSUS.zh-TW.md)／[log、report、畫面](evidence/local-versus/README.md)。基線 `codex/combat-escalation-next` 3389fa9（先前在 main 738c740 上亦跑過同一套，結果一致）；Godot 4.6.3 Linux Compatibility，Xvfb＋Mesa llvmpipe，Dummy audio。

- 新增 `verify_local_versus.gd` 68/68：雙人對戰不觸發能力抽取、手柄 A 跳過開場、全新存檔鎖定、鎖定入口拒絕、第三站落敗不解鎖、三站勝出解鎖並寫檔、重啟後保持、分鍵盤各自攻擊／移動／左右 Shift／跳／數字鍵盤、綁定鍵不觸發快捷鍵、結算與重開保持雙人、兩支手柄、搖桿死區、扳機、Start、拔除暫停與退回、插回取回、鍵盤＋手柄混用、裝置選項存檔、故事中手柄與鍵盤並用、手柄操作選單、RELOCK。log 除 ALSA 開啟失敗（無音效裝置）外無 ERROR／SCRIPT ERROR。
- 既有回歸，Codex 分支 3389fa9 上：reference_ui 37/37（兩項斷言由「5 選項」改為「6 選項，故事在首」）、live_combat 45/45、last_service_rules exit 0。combat_input 12/15、double_jump_input 8/11、first_minute 60/63、last_service_native exit 1：**在未改動的 3389fa9 乾淨 worktree 同機重跑，失敗項逐行相同**，不是本輪造成，本輪也沒有修。
- 先前在 main 738c740 上：上述七套改動前後各跑一次全數通過（15/15、22/22、11/11、45/45、63/63、37/37），`verify.gd` 道具庫通過。
- 沒有跑 Codex 分支新增的 verify_ability_draw、verify_round_flow、verify_city_breaker 等套件。
- 改動前已有問題、未作依據：verify_ui_input（SCRIPT ERROR 後逾時）、verify_jsr_runtime（多項 FAIL 後逾時）、verify_demo_input（多項 FAIL）。本輪沒有修這些，也沒有重跑上輪記錄的另外 4 個舊失敗 suite。

**範圍限制**：輸入全部是程式注入的 InputEvent 與注入的手柄清單，不是實體手柄、不是真人按鍵；不能證明按鍵映射、鬼鍵、延遲、手感或平衡。未在 Godot 4.7.2、macOS、目標 GPU 或 Web 驗證。未操作使用者電腦。

## 2026-11-11：main整合核對
## 2026-11-11：上傳Tripo角色／機身

最終Godot4.6.3 Compatibility／llvmpipe原生模型22/22＋既有流程52/52共74項，最終log無ERROR／SCRIPT ERROR／SHADER ERROR及退出洩漏。原檔逐byte相同、原65骨／skin／albedo實際載入；骨骼鏈、CC0重定向、有限姿態、手腕接觸、代幣跟手、渲染輪盤可見性及原有回合／mute／pause／F2／清理皆驗。證據evidence/ability-draw/tripo-models含原檔預覽、完整有聲Movie Writer、PCM及log。

來源窗口封面使後移輪盤消失，已用衍生材質開窗並加真render pixel檢查；早期型別parse與outline varying宣告失敗保留。Ogg intro／arrival快速重開退出滯留在顯式stream模式仍重現，最終用原OGG解碼短PCM cue重跑乾淨；保留原OGG／長BGM，不宣稱修好引擎解碼器。錄像是1:1邊界fixture、640×360固定30fps再nearest放大，非自然完整match／使用者Mac／真人實聽或硬件FPS。裝備段未實作、Web未更新。

## 2026-11-11：三視圖參考圖交付

已視覺檢視三份ImageGen三視圖：NPC全身A-pose／正側背、機器完整組裝／正拉桿側背、靜態機殼／活動件留空版；核對主色、朝向、拉桿左右、機殼基準及用途區分，PNG尺寸及SHA-256入references/ability-draw/tripo/manifest.json。這是建模設計參考而非CAD精確投影或Tripo服務驗證；背面為補完設計，不能保證生成後分件／拓撲。此輪只增加圖片／prompt／文件，runtime未改，未重跑引擎測試或發佈Web。

## 2026-11-11：抽獎進場修正與裝備分鏡

最終Godot4.6.3原生52/52，log無ERROR／SCRIPT ERROR或退出洩漏；evidence/ability-draw/entry-v2保存空場首幀、鏡頭外入場、煞停、有聲Movie Writer、PCM及實際街景Physics前後probe。原入口被碰撞判阻塞而退回原地已重現，修正後驗真非零位移、兩演員mesh corners初始均出框、移動／輪轉、雙路受阻遮幕，以及原有獎勵／跨場景／暫停／F2／退出。

首跑52項後仍有4個資源未釋放；verbose是arrival／intro的Ogg playback，補齊兩owner的clear顯式停止及exit解除stream後最終重跑乾淨，初次紀錄保留。不把數字旗標當作初次無錯證明。裝備六鏡為ImageGen概念與規劃，未接runtime；Tripo模型尚待使用者提供。未發Web，Mac／真人裝置與目標GPU仍待驗收。

## 2026-11-11：THE DEALER 3D抽能力

Godot4.6.3 Linux Compatibility／Mesa llvmpipe原生45/45新檢查，加既有headless戰鬥34/34及結果15/15，共94項。最終native log無ERROR／SCRIPT ERROR；VSync warning保留。明示1:1／Street Run邊界fixture測真流程、native pressed callbacks、seed／skip／一次領取、實際移速／回盾／能量／重置、Demo無XP、另一stage原點／方向、障礙備援、mute／設定／暫停／F2與完整還原。真桌面滑鼠／鍵盤到獎品頁亦已觀察。

有聲Movie Writer 172幀／30fps，原生640×360再nearest放大1280×720；PCM非靜音與擷取時序見[evidence/ability-draw](evidence/ability-draw/README.md)。初次headless材質null與測試clock設定、原生profile collision mask及F2繼承失敗已保留及說明；不能把33/33旗標視為該次無錯。不是Mac／真人裝置實聽、自然完整match或目標GPU效能；模型與原片仍有差異。未發Web。

## 2026-11-11：結果頁修復、決勝KO與四面反彈

修正RESULT空白：先前在CityBreaker仍active時提前設finish_menu_open，rebuild把controls隱藏；之後director清場但沒有再建選單。本輪在演出釋放後才建立結果操作，並對空白狀態自我恢復。原生測試驗真visible buttons、視窗內位置及pressed callbacks，涵蓋自動播完／暫停／F2／跳過、下一回合與重賽。

依最新指示完整KO只在兩勝制決勝回合；之前回合短結算。Street Run只在最後一站或本次Run敗退結束播完整KO；超時不偽造零生命KO。Demo仍沿真勝負loop，每場只有決勝KO，之後接下一場開場。

正式Rush／Demo／Street Run加入四面盒狀反彈：x±8.2、腳部y0–5.6（8m頂框），重擊／挑空／終結擊／符合推力的技能真命中才發射，普通輕拳不觸發。法線反射耗能、無額外碰牆傷害；每次飛行最多6個接觸／180物理tick，耗盡自動恢復＋18tick保護，不被新命中刷新預算，落地後才重置。接觸後18tick內可E花20能量受身；AI有有界反應延遲。暫停／hitstop不消耗飛行時間；F2保持物理，只減演出。

真3D透明線框圍場、每面重用一個撞擊格、既有SFX／揚塵／速度尾跡／軀幹中心翻滾。高速飛行鏡頭以雙人body bounds即時退開，避開HUD，反彈字卡移到底部。513項focused checks全數通過；9秒四角合法挑空反彈預覽及約56.7秒自然三回合／下一場有聲錄像。詳見[evidence/arena-box](evidence/arena-box/README.md)。同codex/combat-escalation-next／PR #6推來源，不發佈Web；Mac／真人平衡、鏡頭和混音待驗收。

## 2026-11-11：完整回合演出、AI Demo循環與煙霧

正式FIGHT／Street Run加入2.8秒同場3D開場：街景、P1／P2角色近鏡、ROUND，再交回原倒數及對戰。Enter／Space跳過，Esc暫停，練習保持即玩。AI Demo改正常有限生命、不回血，真KO後播完整5秒破壞＋3.2秒勝者魚眼與離場，之後自動下一回合；兩勝完場也繼續loop，沿用選角、不發XP。覆蓋舊Demo endless／無KO契約，正常FIGHT結果仍由玩家確認。

場景加入有界屋頂／街邊煙、命中揚塵及64團KO殘煙；重擊後可短暫魚眼近鏡，避讓Neon大招與KO，保持雙人及HUD留白。新增原創2.8秒開場音軌，沿原SFX／mute／pause及BGM duck。26回合／選角／清理＋86勝者＋20FX＋165KO＋37UI＋11Demo輸入＋7Demo規則＋17結果共369項通過；40.4秒連續兩個真KO有聲錄像。詳見[本輪證據](evidence/round-flow/README.md)。來源同codex/combat-escalation-next／PR #6，公開Web不更新；Mac／硬件效能與真人強度仍待驗收。

## 2026-11-10：二段跳與落地預輸入

[規格與範圍](DOUBLE_JUMP.zh-TW.md)／[本輪 log、report、畫面及修改前對照](evidence/double-jump/README.md)。新增規則62/62、原生輸入11/11；相關戰鬥規則201/201、現行正式戰鬥45/45、鏡頭13/13、原生UI37/37。舊combat_polish34/35、cannon_input5/7、aerial_input30/31：四個斷言於未改動f53c378得到相同失敗，未冒稱全套零失敗。首次native因未設Xauthority失敗，修正執行環境後正常渲染；原始log保留。Godot4.6.3 Linux Compatibility／llvmpipe／Dummy audio，輸入為注入；非Mac／人手／音訊裝置／FPS提升證據。模型、字體及舊證據未改，公開Web不更新。


## 2026-11-10：正式FIGHT／Street Run玩法改善

依使用者「真係優化遊戲」更正，直接修改正式AI、LOOP連段和共用接觸時鐘；見 [LIVE_COMBAT_IMPROVEMENTS.zh-TW.md](LIVE_COMBAT_IMPROVEMENTS.zh-TW.md)。CPU會近身投持續防禦、用輕拳打揮空恢復、低guard後撤、按資源選角色招式／付費大招；以20／14／9 tick承諾中立意圖，不讀玩家pending。HUSH低能量改近身；LOOP jab/cross推離5／6→2.8／3.4，近身J能接第三段挑空。native hitstop不再被慢鏡重複拉長，保留原tick數及大招起手profile，SURGE60 parry到狀態重推進16→12個wall步進。

[真FIGHT按鍵、兩組30秒前後對照及量測](evidence/live-combat/README.md)：R後長按Shift被正常CPU真grab命中，非Demo／training；另驗證跳躍可避投。12組guard情境舊AI零投技，新每組5–12次起手；LOOP距離1.2／1.5的第三擊失敗已重現並修復。45新玩法＋260戰鬥＋37原生UI音樂＋185既有系統檢查通過；早期失敗及測試Easy難度更正均保留紀錄，不以數量宣稱好玩。Godot4.6.3 Linux／llvmpipe／Dummy audio，Mac與真人平衡／實聽仍待驗收。

同一來源branch codex/combat-escalation-next／PR #6；不新增教學或原型作主要交付，原高壓窗口仍隔離，XP／裝備／GLB／公開Web不動。ChatGPT分享頁仍無法讀取（網頁無可讀內容、原生Chrome DNS錯誤），未聲稱已讀；以repo規格和本聊天更正續作。

## 2026-11-10：FIRST MINUTE四步主動教學

規格E首分鐘與C起手讀取切片已接入，見 [FIRST_MINUTE_COACH.zh-TW.md](FIRST_MINUTE_COACH.zh-TW.md)。主選單C或HOW TO PLAY頂部入口，四個真接觸目標：同段兩擊、parry後真counter_success＋hit、launcher→付費homing_chase→空中hit、付75能量的overdrive真hit。Enter／按鈕開始及接下一關，F5僅重試本關，Esc保存，F2仍能完成。每關明示100能量／近身／SURGE0 fixture，不改正常傷害、擊退、能量、成長或AI規則；讀招陪練只用普通commands，成功由Simulation事件判斷。

396項（63新教學＋46窗口＋250戰鬥＋37原生UI音樂）通過，另有桌面真C／Enter／按住J完成兩擊。四角×四課都以普通輸入完成；揮空／普通block／起手counter hit／只有parry／只有launcher／只有startup不誤判。反擊／追擊期限與長按guard有正確提示。[畫面、示範及log](evidence/first-minute/README.md)。Godot4.6.3 Linux Compatibility／llvmpipe／Dummy audio，無ERROR／SCRIPT ERROR；不是Mac、真人學習／首分鐘完成時間或實際混音驗收。

完整C情境教讀、D逐角色視聽、E三站敘事仍待續作；新高壓窗口維持練習隔離。繼續推同一來源branch codex/combat-escalation-next／PR #6，使用者Desktop Fetch／Pull後本機Godot測試；公開Web不更新。

## 2026-11-10：SURGE LAB高壓窗口原型（僅練習）

接續規格B的獨立比較原型，見 [SURGE_WINDOW_PROTOTYPE.zh-TW.md](SURGE_WINDOW_PROTOTYPE.zh-TW.md)。主選單B或HOW TO PLAY頂部入口：明示60能量／60 SURGE近身fixture，B切BASELINE／WINDOW並重設，F5重試。雙方地面idle、無硬直／已緩衝動作及合法距離，heavy／launcher尚未起手前開21個固定60Hz決策步進；J確認攻擊／Shift有限普通格擋／E普通後撤。逐邊首選、超時沿用兩方原輸入、AI預承諾、共用pressure及90步冷卻；不套舊F8三選傷害。Esc保存，F2不延長，KO／中斷／退出清理。

363項（46原型＋30基礎＋250戰鬥＋37原生UI音樂）通過，另有真正桌面B/K/E在21步完成evade。[畫面、並排fixture影片及log](evidence/surge-window/README.md)。Godot4.6.3 Linux Compatibility／llvmpipe／Dummy audio，無ERROR／SCRIPT ERROR；不能當Mac、真人手感或實際混音驗收。新窗口仍不進標準FIGHT／自由AI Demo／Street Run；真人需先比較是否比可靠預輸入有趣。首分鐘完整教學／C教讀／D逐招視聽／E三站敘事未完成。

繼續推同一來源branch `codex/combat-escalation-next`，方便GitHub Desktop Fetch／Pull後在使用者本機Godot測試；不操作或宣稱已同步該電腦，公開Web不更新。

## 2026-11-10：SURGE A＋B基礎切片已實作

依 [COMBAT_ESCALATION_PLAN.zh-TW.md](COMBAT_ESCALATION_PLAN.zh-TW.md) 接續第一切片，現況見 [COMBAT_ESCALATION_RUNTIME.zh-TW.md](COMBAT_ESCALATION_RUNTIME.zh-TW.md)。正式Rush／自由Demo中央顯示同一pressure0–90及FLOW／HEAT／SURGE；升階提示、三級局部強度／接觸聲量，沿同一Rhythm／Neon owner做低高壓對照。成功格擋／挑空後逐邊鎖首個J／K／E意圖，原生hitstop及presentation hold不消耗期限；36個非hitstop固定步進有界，合法時僅交回既有判定一次。Esc保存，受擊／KO／重開／退出清理；不加傷害倍率、免費追擊或受擊偷跑。

30項新增檢查＋250項戰鬥規則回歸＋37項原生UI／音樂回歸通過；真鍵盤K／Esc／Esc使用明示凍結時間fixture，和兩組各30秒正常自由AI錄像分開。Godot4.6.3 Linux Compatibility／llvmpipe／Dummy audio；無ERROR／SCRIPT ERROR，原生VSync不支援警告保留。最終混音峰值／實聽、目標Mac及真人首分鐘仍待驗收。[證據](evidence/combat-escalation/README.md)。

前對話01a1b16d-5526-77a4-b961-b3a97bc7a0af讀取工具回報host不可用，未聲稱已讀；依遠端891489b與規格／交接續作。來源任務分支codex/combat-escalation-next；穩定分支及公開Web不更新。下一步先真人比較可靠預輸入是否足夠，再決定高壓雙方窗口原型；C一般招式教讀／D逐招姿態及E三站敘事尚未整包完成。

## 2026-11-10：LLB升溫／博弈優點轉化規格（待實作）

已吸收使用者補充，對照目前Simulation／Rhythm／Neon／Audio及HUD，規格見 [COMBAT_ESCALATION_PLAN.zh-TW.md](COMBAT_ESCALATION_PLAN.zh-TW.md)。確認現有pressure0–90會累積但正式Rush不顯示，舊三選排除is_aerial；停頓pending也不等於完整決策佇列。下一步沿現有pressure對外稱SURGE，先做三級回饋＋可靠預輸入，再驗證高壓雙方窗口和三站敘事。LLB原作精確規則／幀數標為使用者參考分析，本輪未獨立核實。

**本次只有規劃和來源摘要，沒有更動runtime、傷害／能量、存檔或Web。** 文件連結及狀態檢查不等於遊戲驗收；既有47項封面檢查仍只對應上一輪封面。


## 2026-11-10：五人群像構圖修正

按使用者回報Layout／角度不自然，標題改完整640×360／16:9場景與左側選單覆蓋層；前景桃紅／青色，中央黃、後方紅／螢光綠五人分層。攝影機固定同一街角方向、6°輕斜鏡與細小推近，取消兩秒換角度；街道拓寬，五個頭部留出選單／邊界和互相分離空間。第五人是背景演員，沒有增加可選角色或多人戰鬥模式。減少特效的靜態封面也用同一群像。見 [TITLE_ENSEMBLE.zh-TW.md](TITLE_ENSEMBLE.zh-TW.md)。


47/47原生構圖／生命週期／介面音樂檢查通過，[GIF／MP4與嚴格log](evidence/title-ensemble/README.md)。來源實驗分支更新，公開Web未更新。

## 2026-11-10：原生3D動態標題

主選單右側已改成獨立3D街城：ZIP／HUSH純色剪影、抽幀擺動／抬手、黑白建築視差、四段近中景與斜鏡，8秒循環。左Logo／選單保持固定。12Hz更新上限、376×360子viewport；離頁停渲且不前進時鐘，F2減少特效使用上一版靜態海報。沒有新增GIF播放器或中斷音樂，公開Web不更新。詳見 [動態標題](TITLE_MOTION.zh-TW.md)。

8項動畫生命週期＋37項既有原生介面／音樂檢查通過；[8秒實機循環GIF／MP4及證據](evidence/title-motion/README.md)。Linux Godot4.7.2 Compatibility／llvmpipe，不代表目標Mac效能或實機喇叭驗收。


## 2026-11-10：黑白街城／青粉半身新封面

依最新封面參考接入新海報：黑白切面樓群、桃紅天空、青／粉紅無臉半身人物；左側保留黑色原生選單區。沒有項鍊、五官或戰鬥架勢。新圖為ImageGen原創宣傳插畫，不宣稱是遊戲GLB渲染；原Godot模型封面和原始GLB保留。只改標題背景，未改其他頁面、戰鬥、音訊transport或公開Web。詳見 [封面更新](COVER_NEON_CITY.zh-TW.md)。

Godot4.7.2 Linux Compatibility／llvmpipe介面回歸37/37通過，三視窗尺寸、真鍵鼠和音樂連續播放；log無ERROR／SCRIPT ERROR或退出洩漏。640×360實機圖見 [證據](evidence/cover-neon-city/README.md)，不代表目標Mac驗收。


## 2026-11-10：LAST SERVICE新四角與街區成長已接入

使用者提供ZIP／RIVET／HUSH／LOOP四個Tripo GLB並要求替換相關系統。現況以 [LAST_SERVICE_RUNTIME.zh-TW.md](LAST_SERVICE_RUNTIME.zh-TW.md)為準：原檔SHA保留；65骨、52骨重定向；新選角／封面／名稱／技能／HUD、四套角色資源；三站Street Run、12技能、兩裝備槽、XP／免費重置／120XP淡色FX解鎖及獨立存檔。標準FIGHT固定基礎數值，不套成長；Demo無XP。舊探索預設角色亦改ZIP，未改成開放世界RPG。

295項自動檢查通過，包含46新規則／22原生整合／28大招／53介面材質／134舊規則／12探索；嚴格log及分層證據見 [evidence](evidence/last-service-runtime/README.md)。三站結算用低血站樁fixture驗證真接觸及指標操作，自由AI影片不使用fixture；不當作Mac硬件或真人平衡驗收。實驗分支codex/neon-street-lab推送，Web不更新。下一步僅按玩家回饋修平衡／動作及補原提案其餘子招式，不能把完整劇情／RPG世界當已完成。


## 2026-11-10：加長大招與藝術參考庫

使用者要求大招更長／近鏡／更多旋轉，已接入四人五段程序pose、overdrive共用時鐘0.22s hold／0.78s slow／0.44s release、36°起手鏡頭及最高14°roll；攝影機按雙方body bounds拉遠。真正受擊中斷／被招架才取消，護甲保持攻擊時不取消。見 [NEON_SIGNATURE.zh-TW.md](NEON_SIGNATURE.zh-TW.md)，覆蓋M1最高6°及短大招的數字。原模型／判定／音訊來源與Web不變。

藝術文件／六段風格原片／圖片與生成素材／兩段長篇完整時長壓縮研究版集中在 [參考總庫](../references/style-library/README.md)。原圖缺件及原Drive連結／hash皆列明；Release上傳401已改用Git內研究副本，空draft已刪。

[RPG／加點／解鎖](RPG_PROGRESSION_PLAN.zh-TW.md)只完成具體提案，尚未加入runtime。推薦單人街區＋三路技能板＋兩裝備節點，標準對戰固定數值，四角色和基本技巧不鎖。後續先完成新pose／逐招VFX與M2場景，再切RPG存檔及結算。


## 2026-11-10：Neon Facets M1已實作

`codex/neon-street-lab`已從規劃進入可玩切片：場景／既有細節合批的Lab材質、五階桃紅天空、四人切面shader、格擋／蓄力／重擊／BREAK／KO單一全屏director、短剪影與回氣、24個局部效果上限、最高6°roll及獨立Lab偏好。原GLB／判定／音檔保留；Web與穩定分支不變。

詳見 [NEON_FACETS_RUNTIME.zh-TW.md](NEON_FACETS_RUNTIME.zh-TW.md)及[連續錄像／驗證](evidence/neon-facets/README.md)。21 Lab＋53 native UI／材質＋134規則＋6音訊檢查通過；30s virtual-wall自由AI19／32命中、強stage7.44%。不是目標Mac性能證明，未同步使用者電腦。下一包M2全道具語義材質／葉端／雲動畫，然後M3新輪廓與pose；不得把M2–M6當已完成。


## 最新：統一美術規劃文件（2026-11-09）

[詳細計劃](UNIFIED_PIXEL_ART_PLAN.zh-TW.md)依基線8ed0700讀取現有project、world-only pixel shader、reference UI、天空／飛機、植物方塊與動作資料制定。候選規格、已存在與待實作清楚分開。本輪僅文件，檢查本地連結及diff whitespace；沒有重跑／宣稱新的遊戲測試或效能驗收，runtime／素材／公開Web均未修改。


## 最新：參考圖UI復刻、連續音樂與完整特效審查（2026-11-09）

[功能／界線](REFERENCE_UI.md)／[實機圖與證據](evidence/ui-replica/README.md)。主選單原圖直接接入5個原生按鈕；選角4卡／P1P2與英語；HUD依圖構圖但保留真實動態值。主選單原生1280×720對來源bilinear縮放RGB平均絕對差約1.14/255，不能推論每個動態畫面100%像素相同。

37/37原生真按鍵／滑鼠／popup／scroll／3尺寸、音樂持續與crossfade；19/19實際攻擊路徑、57幀階段圖，另7個明確標示的孤立防禦效果診斷。已檢視完整起手／接觸／釋放圖表及防禦圖；退役生成貼圖／棒狀骨架殘影，地面效果改接真落地。144/144既有headless戰鬥、47/47原生節奏／紅幕、33/33場景音訊特效及40腳本載入0失敗。靜態audit0，不當nativeA11Y證明。舊場景測試仍期待12招架回能，按既有18更新，未改遊戲來通過。

Enter錯誤落到Fight、粗糙人像裁剪及換曲Vorbis物件退出警告的首稿保留；專用stream和mixer退出等待後，最終native37與Demo日誌無新退出警告。退出等待只在測試工具，不暫停產品流程。Godot4.6.3 Compatibility／llvmpipe／Dummy，不是真人或目標硬體驗收。來源原檔不變，只推來源分支，Web不更新。


## 最新：JSR UI 正式接入、四流派與低解像（2026-11-09）

[功能](JSR_RUNTIME.md)／[本輪完整證據](evidence/jsr-runtime/README.md)。原生新114/114檢查：4×13真實單次命中、四人傷害與速度、雙語三尺寸、選角callback、50/75沿用模擬、8種專屬圖、低解像及歌曲切換。舊戰鬥規則263項全部通過，原生UI36、真滑鼠／鍵盤17、節奏29、紅幕18，四角色原生30/30、音樂播放20/20、39腳本載入0失敗，headless512循環3/3（3125 objects／543nodes保持）。各次receipt列出，不把重跑與前輪648加總。

已檢視主選單、設定、護目鏡比例及舞者／電光技能的原生畫面。首版文字被圖框干擾，改為描邊與安靜次級底板；深蹲待機改直立，選角新增說明後戰鬥按鈕越界亦已收緊。初次兩項測試把實體視窗與邏輯邊界混比已修正，舊測試的StyleBoxFlat與1/3身高假設已隨新契約更新；失敗記錄保留first-pass。專屬圖首稿半透明白霧經ImageGen修正；所有PNG未用Python改畫。通用圖一角alpha=1如實保留，專屬圖四角0。

19段CC0重定向＋作者化姿態，不冒稱四完整新下載動作庫。2首使用者音樂轉OGG接入，不冒稱CC0；Dummy音訊驗證播放狀態，未實聽。世界640×360格取樣是畫風，不宣稱內部低解像效能。現引擎4.6.3，對使用者4.7.2截圖所列寫法做修正，不冒稱4.7.2實跑。49件來源資產不變，公開Web不更新，未操作使用者電腦。


## 最新：JSR UI 研究與生成素材（2026-11-09）

成果見 [研究與接入規格](JSR_UI_ART_DIRECTION.zh-TW.md)／[圖片總覽](../references/ui-jsr-2026-11-09/README.md)。本輪未改遊戲 runtime UI，沒有把圖片視為已接入或重跑不相關戰鬥回歸。

- [45/45 素材檢查](evidence/ui-jsr/asset-inspection.json)：三張正式 PNG 的 RGBA／透明角落／內容、Logo 至少 6% 顯著內容留白、8 框架區域、16 圖示、血框與圓盤的透明中心。工具只讀像素，未裁切／重畫生成 PNG，切片另寫 JSON。
- [Godot 框架](evidence/ui-jsr/ui-frames-alpha-preview.png)／[圖示](evidence/ui-jsr/action-icons-alpha-preview.png)／[Logo](evidence/ui-jsr/afterhours-logo-alpha-preview.png)為實際原生 alpha 合成並已檢視；只是在檢查素材，沒有假裝是已工作的遊戲按鈕。首張預覽未按 project 邏輯畫布縮放而裁切，修正成 viewport 等比適配後完整顯示，first-preview 保留。原檔透明 RGB 背景有色，不能從不合成 alpha 的預覽誤判為不透明。
- [提案色票對比](evidence/ui-jsr/contrast.json)：Ink 對 Paper／Orange／Lime 為 15.93／6.22／14.30:1；Paper 對 Orange 只有 2.56:1，明確排除一般小字用法。這不是生成圖逐像素或整體 A11Y 驗收。
- [Frontend Design Premium strict 稽核](evidence/ui-jsr/premium-audit.json) 0 errors／warnings；該工具主要掃 Web 格式，不能證明 Godot 原生控制項的互動／無障礙。既有 DESIGN.md／UX-CONTRACT.md 與 ui_theme 擁有權已核對，現行 Tokens 未改。
- [來源](../references/ui-jsr-2026-11-09/sources.json)及[生成 lineage](../references/ui-jsr-2026-11-09/generation-manifest.json)：四張官方 PC 截圖、十頁手冊圖像實際檢視，掃描 PDF 無可抽取文字；blocked／零素材來源亦記錄，未冒稱看過。9 個生成輸出含3早稿，主要交付6 PNG；未重用原作素材作遊戲貼圖。角色參考來自現有四個模型的原生擷取。
- [來源完整性](evidence/ui-jsr/source-integrity.json)核對基線19a3637全部49件既有模型／圖片／音檔及所有現行 runtime 腳本／場景／設定不變；只有新增擷取／合成工具、設計文件與素材。

圖片為概念合成，英文示意文字不當作正式 UI 字圖；右側角色插畫有簡化，不當作新模型設定。素材需接入時再驗證真實輸入、數值、兩語言、三尺寸與 F2；本輪沒有那些 runtime 變更，不宣稱已通過。Godot 4.6.3 Compatibility／Mesa llvmpipe，只有預期 VSync 提示。只推來源分支，不更新 Web，未操作使用者電腦。


## 最新：蓄力重砲、空連後 AI 選擇與分招式鏡頭（2026-11-09）

功能見 [CHARGED_CANNON.md](CHARGED_CANNON.md)。W＋L／↑＋L 為一次承諾的固定起手重砲，75 能量、30 tick 起手、38 基傷／3.8m／一次命中；普通 L 的 50 消耗保持。原來源模型／音樂不改，角色 4 維持 1.4 縮放。

- 本輪 **504 項不同無視窗檢查**：既有 494 項回歸及新重砲 10 項。初次[整套 headless](evidence/charged-cannon/headless/summary.json) 503/504，唯一失敗為新投技測試誤把施放後 25 能量當成被投後仍 25，忽略既有受傷 +6 回報；修正預期為 31，保留真打斷／扣血檢查，[10/10 通過](evidence/charged-cannon/final-rules/summary.json)。AI 最終改成空連取得機會後，再跑[新規則＋30,000 tick 雙實例 Demo 31/31](evidence/charged-cannon/earned-rules/summary.json)。新規則涵蓋 74 拒絕／75 真消耗、空揮不退、一次命中、起手受傷、投技打斷、按住 J 不吞手動指令、普通 L 保持及 AI 自然真命中。
- 本輪 **144 項不同原生檢查**：重砲輸入 7、節奏 29（七配置）、四角色 30、紅幕 18、Demo 28、UI 17、戰鬥按鍵 15。初次[原生批次](evidence/charged-cannon/native/summary.json) 143/144，顯示 AI 太直接選重砲會降低既有 30 秒追擊／暴扣門檻；沒有放寬門檻，改成自己完成地空五連記住機會、600 tick 間隔並等距離／能量，再跑[新輸入／節奏／Demo 64/64](evidence/charged-cannon/earned-native/summary.json)。[光束錨點與 UI 24/24](evidence/charged-cannon/muzzle-final/summary.json)另確認實際 F2 傷害保留及介面；重複項不加總。[逐案例回歸索引](evidence/charged-cannon/validation-index.json)列出本輪不同檢查共 **648**，是多次有出處的回歸集合，不冒稱單次全套在最後一秒執行。
- 新原生 7 項包含 viewport 真實 W／L、放開方向後仍選正確技能、75 消耗、獨立蓄力紅幕與時鐘、後拉／雙掌姿態、真接觸後才產生光束、正確能量不足提示、F2 真傷害及退出清理。最後再驗證演出優先級：[輸入／節奏／紅幕／Demo／UI 99/99](evidence/charged-cannon/priority-final/summary.json)，普通技能不可蓋掉重砲，真命中／BREAK／KO 才接管。姿態為程序疊加，不冒稱新增下載動畫。
- [最終 120.009 秒原生自由交戰](evidence/charged-cannon/native-soak-final/complete.json)：6,064 戰鬥 tick、173 次真命中（89／84）、27 追擊、11 次重砲命中、20 普通爆發命中、23 BREAK，0 重置／循環／結果。最多 15 效果／541 節點，孤立節點取樣 0，最大 roll 約 11°。只有開始 F12 的兩次按鍵轉換，最終優先級／光束修正後完成。較早 [120.172 秒 run](evidence/charged-cannon/native-soak/complete.json) 亦保留，不混為同一回合或加總。短觀察不是長測／無洩漏保證，軟體 GL 不是目標 GPU 效能。
- [30 秒連續 Demo](evidence/charged-cannon/demo.mp4)／[GIF](evidence/charged-cannon/demo.gif)：同場 1,800 牆鐘步驟、450 張原生擷取／15fps／無音軌；實際前進 1,620 simulation tick、51 真命中、8 追擊、3 重砲命中、3 普通爆發命中、3 暴扣、6 BREAK。事件由 combat_event signal 計數，見 [capture.json](evidence/charged-cannon/capture.json)。與舊版數字不同是新戰鬥路徑，不是單變因爽感評分。
- [4 秒重砲片段](evidence/charged-cannon/cannon.mp4)是對站立陪練的一次真實 W＋L 指令，120 張／30fps，真消耗與一次命中後的光束釋放，見 [move-capture.json](evidence/charged-cannon/move-capture.json)。已檢視[紫紅蓄力](evidence/charged-cannon/captures/cannon_slow.png)、[手部射向接觸點的光束](evidence/charged-cannon/captures/cannon_blast.png)及新角色比例。不是自由交戰剪接或人手錄影。
- [來源與候選雜湊](evidence/charged-cannon/source-manifest.json)保存基線 297b1f3：全部 49 件既有 GLB／圖片／音檔逐位元組保留，只更新程式／UI 衍生字體。舊 smoke 工具及角色回歸擷取意外寫回歷史證據的檔案已恢復；本輪新畫面另存 charged-cannon，未覆寫歷史原圖。

Godot 4.6.3 Compatibility／Mesa llvmpipe／Dummy 音訊。最後通過日誌只有預期 VSync 提示，未有新腳本／退出資源錯誤。自動注入、狀態／幾何檢查與原生畫面檢視不代表真人讀招、手感、混音、舒適度或使用者電腦驗收。只推來源分支，不更新公開 Web；角色專屬技能／名字、完整 VS、可變持鍵蓄力仍待後續。


## 最新：停慢快節奏、加長紅幕與角色 4 比例（2026-11-09）

功能／時間規格見 [COMBAT_RHYTHM.md](COMBAT_RHYTHM.md)。原始 GLB 不修改；護目鏡角色 4 包裝比例 2.1→1.4，顯示高度減少 1/3，陰影／殘影粗細與特效高度配合。

- [無視窗回歸 494/494](evidence/combat-rhythm/headless/summary.json)：Rush 21、友善防禦 25、無限 Demo 21、空中反制 57、空戰 54、換手 60、結果 15、戰鬥 34、戰鬥完善 35、接觸演出 24、高壓 59、近身 41、UI 35、構圖 13。純 simulation 規則及 30,000 tick 雙實例確定性保持；實際新遊戲時鐘由原生檢查驗證，沒有把純模擬 tick 當新牆鐘時間。
- [原生流程 135/135](evidence/combat-rhythm/final-native/summary.json)：新節奏 27、四角色 30、紅幕 18、Demo 28、UI 17、戰鬥輸入 15。新 27 項逐一檢查六配置的 hold／slow／release／flow 與最多兩步；低階事件不覆寫強停頓；F2／清理、角色 4 確切 2/3 比例；真實付費爆發啟動停頓、雙方狀態及 sim.tick_count 真正凍結、停頓輸入保留、暫停凍結兩時鐘、實際慢速與高速步進、約 5–13° 間的可見鏡頭轉動、無限交戰兼有普通街景與強演出，兩方真命中。
- 清理慢鏡骨架殘影／重複技能字卡後，再跑 [新節奏＋紅幕＋Demo 73/73](evidence/combat-rhythm/visual-final/summary.json)；這是覆核，不重複加總，本輪 **629 個不同檢查**。最後只有工具擷取路徑及額外錄影工具變動，未再改 runtime。
- [120.007 秒原生真實時鐘運行](evidence/combat-rhythm/native-soak/complete.json)：角色 4 對 3、只有開始 F12 的兩次按鍵轉換，6,103 戰鬥 tick、177 次真命中（72／105）、28 次追擊、24 BREAK、12 次反踢命中，0 重置／循環，全程維持 fight。最多 15 效果／541 節點，孤立節點取樣 0；最大鏡頭 roll 約 11°。phase_render_frames 為各階段的**渲染幀取樣數**，不是 simulation tick 或時間比例。軟體渲染各階段 FPS 不同，不拿此表推論慢鏡佔總時間。
- [30 秒無剪接片段](evidence/combat-rhythm/rhythm-demo.mp4)／[GIF](evidence/combat-rhythm/rhythm-demo.gif)為同場 1,800 固定牆鐘步驟、450 張原生畫面／15fps，無音軌；實際 simulation 前進 1,675 tick、54 真命中、9 追擊、6 爆發命中、4 暴扣命中、5 BREAK，事件以 signal 計數。每四步採樣的 [capture.json](evidence/combat-rhythm/capture.json) 有 274 flow／37 hold／59 slow／80 release、132 紅幕取樣；這是固定間隔取樣，不是逐幀視覺評分。
- [新長 KO 片段](evidence/combat-rhythm/extended-ko.mp4)為角色 4 按住 J 真實勝出後的 1.6 秒／30fps 擷取，包含 1.2 秒紅幕與結果返回。已檢視[縮高預覽](evidence/combat-rhythm/captures/short_fighter_preview.png)、[慢鏡技能](evidence/combat-rhythm/captures/skill_slow.png)、[速度線釋放](evidence/combat-rhythm/captures/release.png)、[BREAK](evidence/combat-rhythm/captures/break.png)及[KO](evidence/combat-rhythm/captures/extended_ko.png)原生畫面。
- [來源與擷取雜湊](evidence/combat-rhythm/source-manifest.json)：基線 49be6e5 的全部 49 件既有模型／圖片／音檔逐位元組保留；更新原始碼／角色比例 metadata，不改 wev 音樂。歷史 character-roster PNG 因舊工具回歸被重寫，已恢復原版；新縮高畫面另存本輪，工具未來寫入本輪目錄。

保留失敗與修正：`native/` 的 Demo 107/108 是舊斷言把 1,800 牆鐘呼叫等同至少 1,800 模擬 tick；改驗證每步單調、最多兩 tick、持續有真交戰且不切章，並保留兩方命中／追擊門檻。`first-headless/` 493/494 的挑空測試仍固定十次呼叫等釋放，新慢鏡使其過早；改為最多 120 次內等真 hitstop 結束。`first-rhythm-native/` 132/135 揭露實際接線錯誤：技能是 swing/special 事件，誤等不存在的 special kind；改接真發招後，技能停頓／雙方凍結／輸入保留三項都通過。首個 KO 擷取未等原生按鍵進入下一視窗幀便快轉，未取得所需命中；補兩幀輸入交付後真實勝出，保留 ko-capture-first.log，不冒稱新增遊戲 bug。

Godot 4.6.3／Compatibility／Mesa llvmpipe／Dummy 音訊。最後通過日誌只有預期 VSync 提示，沒有新腳本或退出資源錯誤。自動注入／畫面檢視不等於真人爽感、甩鏡舒適度、實聽、目標 GPU 或使用者電腦驗收；120 秒是短觀察，不是長測或無洩漏保證。新共享時鐘改變兩方的實際操作時間，需真人比較，F2 返回普通速度。只推來源分支，未部署 Web。


## 最新：三個 GLB／四角色配搭（2026-11-09）

功能見 [CHARACTER_ROSTER.md](CHARACTER_ROSTER.md)，靜態資料見 [uploads manifest](../references/characters/uploads-2026-11-09.json)。三個來源 GLB 不改位元組，各 1,502／1,535／1,548 tris、65 joints、1024² Base Color、零內嵌動畫。Python 檢查 GLB magic／version／長度、JSON／binary chunk、三角形模式、材質與圖片可解碼；這不是 `game-dev` receipt。該 CLI 缺少，未安裝或改用遠端生成。

- [原生回歸 107/107](evidence/character-roster/native/summary.json)：新 roster 29、紅幕 18、Demo 28、UI 17、戰鬥輸入 15。四個實際 Skeleton3D 皆 65 骨骼且至少 50 個映射，判定期雙手放大、有限非退化骨矩陣及 F2 復原；切換模型不改 simulation。三位新角色各實際空連到 meteor 並勝出真回合，無限 Demo 保留指定不同配搭及真命中。驗證兩個四選項的原生 OptionButton 回呼、兩語言／三尺寸、儲存及非法編號限制。
- 最後移除預覽頁返回鈕上方重疊提示，補 24 次反覆換角只保留一件模型及一份重定向快取，再跑 [新 roster 30/30](evidence/character-roster/final-native/summary.json)；上一輪 29 項不重複加總。
- [無視窗回歸 104/104](evidence/character-roster/headless/summary.json)：Rush 21、戰鬥完善／偏好 35、UI 35、構圖 13。沒有改 simulation 規則，未無故重跑全部舊測試。本輪不同檢查合計 **212**。
- [角色 4／3 預覽](evidence/character-roster/01_fighter_4_vs_3.png)、[角色 1／3 預覽](evidence/character-roster/02_fighter_1_vs_3.png)、[KO](evidence/character-roster/03_new_fighter_ko.png)及[Demo](evidence/character-roster/04_demo_pair.png)為原生引擎擷取，已實際檢視。原生輸入測試以固定步進／注入按鍵和選單回呼操作，不是人手試玩或完整美術驗收。較早 29 項成功報告亦保留，非首跑失敗。
- [來源與擷取雜湊](evidence/character-roster/source-manifest.json)保存基線 135515f、候選程式／新素材 SHA-256；43 件既有模型／圖片／音訊不變，只重建 UI OFL 衍生字體。Godot 自動抽出新 GLB 的內嵌 JPG，不覆寫舊貼圖。

Godot 4.6.3／Compatibility／Mesa llvmpipe／Dummy 音訊，最終日誌只有預期 VSync 提示，無腳本／資源退出錯誤。四位共用招式、判定及能力；角色專屬設計未做。未宣稱目標 GPU、人手手感或使用者電腦同步，公開 Web 未更新。


## 最新：Rush 主玩法／無限交戰／紅幕技能及 KO（2026-11-09）

功能見 [RUSH_REWORK.md](RUSH_REWORK.md)，兩部影片的實際取樣範圍見 [COMBAT_VISUAL_STUDY.md](COMBAT_VISUAL_STUDY.md)。本輪改了正式規則與 Demo，不將上一輪的章節展示結果冒充這輪自由交戰。

- [最後完整無視窗回歸](evidence/rush-rework/final-headless/summary.json) **494/494**：Rush 正式新手規則 21、連續 Demo 21、友善格擋 25、空中反制 57、空戰 54、換手 60、結果 15、原戰鬥 34、戰鬥完善 35、分段演出 24、三選 59、近身 41、UI 35、構圖 13。新手按住 J 實際命中六種招式、產生六連及贏下真回合，對手也造成真傷害；空揮不追人、手動 L 不被吞、落地逃脫、爆發非無敵及投技破起手均檢查。Demo 兩個獨立決策／模擬在 **30,000 tick** 輸入／事件／狀態一致，無章節重置或時間／KO 完結，雙方數百次真命中，實際出現追擊、暴扣、反踩、受身與 BREAK。
- [完整原生流程](evidence/rush-rework/red-native/summary.json) **221/221**：紅幕 17、友善格擋 13、Demo／主玩法 28、wev 20、空中反制 33、空戰 31、換手展示 36、UI 17、戰鬥按鍵 15、三選按鍵 11。含真正 viewport 的 F12／R／Esc、玩家鍵隔離、N 無功能、偏好恢復、雙語／三尺寸、按住 J 主玩法實際贏回合，以及 red environment／city／shadow／F2／暫停／退出／結果清理。
- 最後調整 KO 尖星跟隨受擊者、展示層角色分離及暴扣雙手放大後，再跑 [紅幕／Demo 45/45](evidence/rush-rework/final-native/summary.json)，並擷取新片段。其後修正時間到／平手不誤播紅幕 KO，新增一項同時檢查兩種結果，再跑 [18＋28＝46/46](evidence/rush-rework/final-native-timeout/summary.json)。覆核**不重複加總**；本輪不同檢查 **716** 項。上述完整 221 項早於最後幾項純視覺調整，未宣稱全部都在最後一秒重跑。
- [紅幕版原生真實時鐘觀察](evidence/rush-rework/native-soak/complete.json) **120.14 秒、5,794 戰鬥 tick**：只有開始 F12 的兩次按鍵轉換，169 次真命中（70／99）、27 次追擊、9 次暴扣起手、29 次爆發起手、23 次 BREAK、11 次空中反踢命中、9 次場邊受身；**0 重置、0 循環、全程維持 fight**。502 個渲染取樣落在紅幕，最多 13 效果／540 節點，孤立節點取樣 0。這是短時間穩定性觀察，不是長測或記憶體洩漏證明；軟體 GL 未達目標機 60Hz，不能拿這份時鐘當目標 FPS。
- [15 秒連續 Demo](evidence/rush-rework/endless-demo.mp4)／[GIF](evidence/rush-rework/endless-demo.gif)：900 sim tick、225 張原生擷取、15fps，**同一場不中斷、無剪接／章節跳轉**；29 真命中、5 追擊、2 暴扣命中、2 爆發命中、2 BREAK、3 次空中反制起手，詳見 [take.json](evidence/rush-rework/captures/take.json)。[1 秒紅幕 KO](evidence/rush-rework/red-ko.mp4)為真正按住 J 贏下回合後的 30fps 演出擷取；兩片均固定步進／無音軌，不是人手操作錄影。已檢視普通交手、追擊、暴扣、爆發及近鏡 KO 畫面，未將截圖當真人好玩評價。
- [原自主交戰基線](evidence/rush-rework/baseline.json)與[新候選](evidence/rush-rework/candidate.json)各 7,200 tick：命中 **145 → 208**、追擊 **11 → 32**、爆發命中 **8 → 38**、最長無命中間隔 **160 → 97 tick**。舊基線只取自主 duel、不是含預設情境的章節展示；初始能量舊 100／新 70，規則及策略一併改變，這是整體候選對比，不是單變因實驗或真人爽感分數。
- [來源清單](evidence/rush-rework/source-manifest.json)保存基線 af7c13c 與候選內容 SHA-256，43 件既有 GLB／圖片／音檔不變，wev 音樂保留；UI OFL 衍生字體重建。[擷取雜湊](evidence/rush-rework/artifact-manifest.json)另存。

首跑驗證失敗亦保留：[spacing-first.json](evidence/rush-rework/spacing-first.json) 的舊 F7 契約仍要求 ±3m，但主玩法自由練習已改 ±0.7m；將斷言改成按模式驗證新／舊合法距離後通過，沒有取消重置檢查。[red-theatre-first.json](evidence/rush-rework/red-theatre-first.json) 16/17 的結果時序在 .816 秒讀選單，早於 .82 秒門檻，修正等待至 .866 秒後通過；不冒稱這兩項準備問題是新遊戲 bug。較早成功快照留在同目錄，最終以上述路徑為準。歷史 friendly-defense 原圖已恢復，新的回歸擷取改寫 rush-rework/defense-captures。

Godot 4.6.3／Compatibility／Mesa llvmpipe／Dummy audio；只有預期 VSync 提示，最終日誌未有新腳本錯誤或退出資源警告。原生注入輸入／實際解碼與混音檢查並不代表真人手感、實聽、目標 GPU 或使用者電腦驗收。選角／VS、更多角色專用動畫、完整新蓄力分支及真人平衡仍待做。只推送來源分支，未匯出／部署公開 Web。


## 最新：更友善的格擋／反擊（2026-11-09）

目前數值與操作見 [FRIENDLY_DEFENSE.md](FRIENDLY_DEFENSE.md)。本輪修改實際預設規則與正回饋，不僅更新說明。

- [最終無視窗回歸](evidence/friendly-defense/final-headless/summary.json) **489/489**：新容錯／獎勵 25 項；另重跑 Demo 兩輪／全技巧、空中反制、空連、動能換手、高壓、戰鬥／介面／構圖等 464 項。新檢查涵蓋雙向早按、+18 能量、36 tick 反擊、按住 Shift 的緩衝 J、無額外傷害、太早過期／投技破防、空揮無讚賞、F10 末段早按、空中整段終結起手、重置及跳躍取消短按保留。
- [原生輸入與展示](evidence/friendly-defense/native/summary.json) **187/187**：新增 13 項及既有 174 項。真正 viewport Shift／J，確認較早格擋、持續按住 Shift 出反擊、實際命中才顯示成功、普通擋格、暫停不消耗機會、早按空中反制、F2 與退出清理。之後補上短按保留可被跳躍取消及高壓／換手清理，再完整重跑上方 489 項及 [新原生 13/13](evidence/friendly-defense/final-input/summary.json)；不把重跑重複加總，本輪不同檢查共 **676** 項。
- 四張原生引擎圖已檢視：成功格擋有能量 18／J 提示，實際反擊後對手 93 HP／反擊成功，普通擋格及 F2 空中成功。固定情境／60Hz 步進，不是真人遊玩錄影。
- [來源清單](evidence/friendly-defense/source-manifest.json) 保存基線／候選內容 SHA-256。43 件原始模型／圖片／音檔不變，wev 音樂保留，只重建 UI 衍生字體。

首跑舊契約的空中 56/57、動能 59/60 及高壓工具錯誤保存在 first/：舊「太早」個案因新窗口已合法成功，改用仍會過期的 14 tick 暴扣／高階換手案例檢查無限刷新；高壓工具原本固定等 24 tick 就讀 winner，放寬後尚未結算，改以 WINDOW 常數等待，59/59 通過。沒有刪除過早／連按限制檢查。

新檢查首輪 21/22 是投技測試站距 1.2m 超過 1.15m 判定，修正合法測試距離後通過；新原生首輪 7/13 未等視窗初始化便送第一個 Shift，空中也早一 tick 檢查接觸。補上初始化等待及正確接觸時序後 13/13，保留 rules-first.*／input-first.*。這些準備錯誤不冒稱遊戲 bug；實際新增的跳躍取消保留則另有規則測試。

Godot 4.6.3／Compatibility／Mesa llvmpipe／Dummy 音訊，只有預期 VSync 提示；沒有新腳本或退出資源錯誤。未宣稱真人成功率、平衡、實聽或使用者電腦驗收。只更新來源分支，未部署公開 Web。

## 最新：雙 AI 技巧 Demo（2026-11-09）

功能及預設情境範圍見 [AI_DEMO.md](AI_DEMO.md)。F12 進 23 段技巧／自由交戰／KO 循環；不把展示決策器當成通用競技 AI。

- [無視窗回歸](evidence/ai-demo/headless/summary.json) **384/384**：新 Demo 37 項，兩份模擬／決策器在 **9,858 tick、兩個完整循環**保持輸入／角色／事件一致，全部 23 段在左右角色交換後各一次，雙方皆真實命中。實際事件覆蓋所有 12 種已實作傷害招式，以及格擋／破防／完美格擋、拆投、閃避、撞牆／受身、起跳／急降、挑空追擊、地面反彈、空中反制、高壓對峙、四階換手及 KO；未靠假事件檢查。其餘 347 項既有規則／介面／構圖回歸本輪重跑。
- [原生 viewport 輸入／展示](evidence/ai-demo/native/summary.json) **138/138**：新 Demo 31 項，含鍵盤 F12／N／R、點按、暫停、F2、設定、23 段完整循環及結果自動續播、玩家出招隔離、原陪練偏好恢復、雙語／三尺寸控制範圍。其餘 107 項空中、反制、介面、戰鬥及高壓輸入回歸通過；手動步進，不冒充真人。
- [原生真實時鐘觀察](evidence/ai-demo/native-soak/complete.json) **120.005 秒**：只有開始按鍵的 2 次轉換，完整自動循環一次並進第二輪；43 次真實命中、1 次 KO、3 次空中反制、4 次動能換手接觸、3 次高壓對峙、拆投／撞牆／受身均實際發生。最多 9 效果、節點初始化最高 541 後取樣穩定 517、孤立節點樣本 0。是短觀察，不是長測或硬體效能驗收。
- [25 張原生畫面](evidence/ai-demo/captures)含主選單、每段技巧及 F2；已檢視入口、空中反制與場邊受身。180 幀擷取衍生 [12 秒 MP4](evidence/ai-demo/demo.mp4)／[GIF](evidence/ai-demo/demo.gif)：空連／反制／四階換手／KO 的剪接，60Hz 固定步進、每四 tick 擷取、15fps 播放，沒有遊戲音軌，不是真人錄影。

首跑 **25/37** 與完整報告保留在 rules-first.*：純決策器在 KO 終止狀態仍等 hitstop 歸零，遊戲結算本來已停模擬，導致無法跑第二輪，故多項至少兩次覆蓋失敗。已讓章節終止判定識別 round_over／match_over；session 仍播放 2.5 秒 KO 結果再續播。修正後 37/37；原生完整循環亦通過。

修改前基線及既有模型／圖片／音檔不變的雜湊見 [source-manifest.json](evidence/ai-demo/source-manifest.json)。字體子集因新段名重建。只有預期軟體 VSync 提示；無新腳本錯誤／資源退出警告。Godot 4.6.3／Compatibility／Mesa llvmpipe／Dummy 音訊，不代表真人手感、實聽、目標 GPU 或使用者電腦測試。未更新公開 Web。

## 最新：wev 官方音樂接入（2026-11-09）

使用者確認可用並指示自行下載，官方 Bandcamp 免費下載成功取得 family ties (wev edit) MP3 320，全曲 225.802 秒；不是 SoundCloud 串流擷取，未購買付費 OST。官方下載的最初 URL 回傳 Download Expired，依官方頁面 JS 的 statdownload／伺服器 retry_url 流程取得 HTTP 200 audio/mpeg。未登入、提交 email 或繞驗證；沒有將短期下載簽章寫入 repo。

- [音訊來源／SHA-256／量測](../references/audio-sources/worldwidewev/admitted.json)：9,075,311 bytes 原 MP3（不提交），4,047,248 bytes 遊戲 OGG。全曲首尾淡化；FFmpeg 量測衍生 −18.02 LUFS-I／−10.01 dBTP，未宣稱實聽或小節無縫循環。
- [本輪原玩法回歸](evidence/wev-integration/headless/summary.json) **103/103**：場景音訊 33、戰鬥完善 35、介面 35。退出釋放修正後另重跑 [場景音訊 33/33](evidence/wev-integration/final-audio-regression/summary.json)，不重複加總。
- [新音訊流程 20/20](evidence/wev-integration/final-audio/summary.json)：實際 OGG 解碼／完整長度、實例隔離、缺檔 fallback、持續播放頭、duck 恢復、音量零／mute／暫停、20 次導覽循環、實際 seek 近曲末並跨端點循環、十聲道上限。Master AudioEffectCapture 得到 7,680 frames 並檢查當次輸出未削波；這是短取樣，不是全曲硬體或人工混音驗收。
- [原生介面輸入 17/17](evidence/wev-integration/native/summary.json)；同摘要亦含初版音訊 19 項，其後完整 20 項以上方 final-audio 為準。本輪不同檢查合計 **140**，不把重跑重複計數。
- [設定頁原生擷取](evidence/wev-integration/settings-credit.png) 已檢視，曲名／作者及獨立音量可見。匯入成功；新衍生檔不覆蓋原 CC0 資源。

首次音訊工具 19/19 但退出有 OGG 音效播放實例未釋放警告，保留 runtime-first.log／json。補上播放實例明確 stop 及工具等待清理後，final-audio／final-native-mix 日誌只剩預期軟體 VSync 提示，沒有腳本錯誤／退出資源警告。這是實際問題修正，不以通過斷言掩蓋診斷。

環境 Godot 4.6.3 Compatibility／Mesa llvmpipe／Dummy audio。實際解碼與混音取樣不等於真人聆聽，未宣稱耳機／喇叭、目標 GPU 或使用者電腦驗收。只更新來源分支，未更新 gh-pages／公開 Web。

## 最新：wev 可用狀態更新（2026-11-09，僅文件）

使用者確認「wev 音樂已可用」已記錄；工作區檔案搜尋只找到既有音訊，未找到 wev 音檔，未附新素材連結。本輪只更新交接／待辦／決策與接入狀態，未更換音檔或執行程式，未重跑遊戲測試；沒有聲稱完成聆聽、混音或獨立授權查驗。公開 Web 不變。

## 最新：空中借勢逆轉（2026-11-09，香港時間）

功能與限制見 [AIR_REVERSAL.md](AIR_REVERSAL.md)。本輪加入 F11 空戰及 F8 專用教室的有界反制，正式三選不變。

- [無視窗回歸](evidence/air-reversal/final-headless/summary.json) **427/427**：新增反制 57 項，覆蓋雙方向／兩種終結、資源、按住與早按、定格與起手精確期限、首次鎖定、閃避／落空／抽身、AI／教室／重設及 25,000 tick 決定性重播。前輪 370 項本輪重跑；最後只調整 HUD 時機提示條件，其後原生回歸重新載入該版本。
- [原生輸入／展示](evidence/air-reversal/final-native/summary.json) **143/143**：新增 33 項，含 viewport K／Shift／J／E、點按、暫停、F2、教室／模式切換、雙語及三尺寸按鈕範圍。既有空中、換手、介面、戰鬥及壓力輸入 110 項本輪重跑。按鍵經真實 viewport 分發，檢查工具以固定步進驅動物理，不是真人試玩。
- [原生連續操作](evidence/air-reversal/native-soak/complete.json) **120.134 秒**、466 次按鍵轉換、90 次教室啟動、77 次成功反制、24 次反踢真實命中、53 次抽身、13 次未接住而承受終結。此工具使用真正 native physics／viewport 按鍵，沒有直接改位置或呼叫 simulation.tick；軟體渲染下並非每次都能抓住六幀窗口。最多 7 效果，節點取樣由初始化 535 到穩定 514，孤立節點樣本 0。這是短觀察，非長測／效能驗收。
- 14 張原生圖及 80 幀固定步進衍生 GIF／MP4；已檢視接住定格、反踢釋放、F2 畫面。圖片／序列由實際引擎渲染，場景初始化與時序由工具控制；不當作玩家錄影。
- [來源清單](evidence/air-reversal/source-manifest.json)：基線 `1478fff`；42 件既有 GLB／圖片／音檔 SHA-256 不變，僅 UI 字體子集衍生更新。重建字體及匯入完成，候選執行檔雜湊保存。

首輪規則 **52/53** 保存在 rules-first.json：重播工具在強制 Shift 後立刻隨機出拳，打斷自身嘗試，未實際走到反制。修正重播前兩 tick 輸入並分開檢查狀態一致／事件覆蓋，後續加三項 AI 檢查最終 57/57；不是把未觸發分支說成已驗證，也不是遊戲決定性失敗。

環境 Godot 4.6.3、Linux Compatibility、Mesa llvmpipe、Dummy 音訊；只有預期軟體驅動 VSync 提示，沒有新腳本錯誤。不代表實聽、真人平衡、目標 GPU 或使用者電腦驗證。只更新來源分支，未匯出或部署 Web；wev 未下載或錄用。

## 最新：空中街鬥原型（2026-11-09，香港時間）

功能與操作見 [AERIAL_STREET.md](AERIAL_STREET.md)。本輪實作 F11 專用空中訓練，正式玩法保持；新增規則／姿態／鏡頭／輸入，不包含空中格擋逆轉或 wev 音樂。

- [無視窗回歸](evidence/aerial-street/final-headless/summary.json) 370/370；新增 54 項空中檢查及 25,000 tick 決定性混合重播，其餘 316 項原玩法本輪重跑。
- [原生輸入／展示](evidence/aerial-street/final-native/summary.json) 110/110；新增 31 項含真實 viewport 按鍵、完整追擊空連、暫停／F2／模式切換／設定與 36 組安全包圍盒。
- [原生自動操作](evidence/aerial-street/native-soak/complete.json) 120.019 秒、458 次鍵盤轉換、25 次追擊、空中三招各 25 次、100 次真實命中，最多 8 個效果、孤立節點樣本 0。這是短觀察，不是長測或真人平衡。
- 修改前原生跳躍基線 1.955m、新跳躍最高點 2.181667m；14 張新圖、1 張基線及 105 幀序列衍生動畫。已看實際起跳／頂點／追擊／暴扣／落地與主選單。
- 初次 17/30、中間 27/30 原生失敗紀錄保留：已修快放修飾鍵遺失及場邊腳底貼近提示板，新增站立陪練入口檢查後最終 31/31。

Linux Godot 4.6.3 Compatibility／Mesa llvmpipe、Dummy 音訊；未實聽／真人試玩／目標 GPU 驗收，未操作使用者電腦。[來源快照](evidence/aerial-street/runtime-manifest.json)核對 42 件既有模型／圖片／音檔不變，僅衍生字體更新。只推送原始碼分支，公開 Web 不動。

## 最新：空中戰與 wev 研究／規劃（2026-11-09）

- 已完整閱讀 18,127 bytes 新參考，保存原始位元組及 SHA-256；使用者後續重申空中動作優先。原遊戲幀數／內部實作／影片時間碼未獨立核實。
- [獨立參數試算](../references/rd-aerial-2026-11-09/parameter-sanity.json)通過：60Hz 先扣重力再積分下，現值跳高 1.955m、參考 5.683m、建議 2.182m；守恆縮放公式核對。這不是 Godot 遊戲／碰撞／手感驗證。
- 7 個藝術家／作品／官方連結公開頁面 HTTP 200，保存必要 metadata 與回應雜湊；《OST》15 首、SoundCloud 2 首，已查授權欄位為 All Rights Reserved。使用者確認尚未授權，先規劃；未下載音訊、未實聽／量測 BPM、未聯絡藝術家。
- 新增 [空中戰計劃](AERIAL_ACTION_AUDIO_PLAN.zh-TW.md)及 [wev 音訊計劃](WEV_MUSIC_PLAN.md)，檢查來源大小／雜湊、metadata 數量／錄用狀態與 108 個本地文件連結通過，`git diff --check` 通過。
- 修改範圍只有研究／文件／獨立算術腳本；Godot 執行程式、音檔及現有音訊授權均未改，沒有重跑遊戲測試，也不挪用下方舊版檢查宣稱新空中系統已實作。只推送開發分支，公開 Web 不更新，未操作使用者電腦。

## 最新：動能換手及漫畫爆發（2026-11-09）

完整功能／限制見 [KINETIC_OVERDRIVE.md](KINETIC_OVERDRIVE.md)。最終無視窗 316/316、原生 viewport 79/79 通過，包含新規則 60 項、展示／輸入 36 項及 25,000 tick 決定性重播；最後主選單底部留白另有 UI 35/35、原生展示 36/36。原生自動輸入完成 120.031 秒、732 次鍵盤轉換、6 回合／2 場；這是短觀察，不是長時或真人測試。

15 張原生圖片、86 張固定步進序列衍生 GIF／MP4，已查看壓縮、能量技、KO、減少演出及主選單畫面。[無視窗報告](evidence/kinetic-overdrive/final-headless/summary.json)、[原生報告](evidence/kinetic-overdrive/final-native/summary.json)、[觀察完成紀錄](evidence/kinetic-overdrive/native-soak/complete.json)。初期 UI 33/35 失敗記錄保留，已修字體重新匯入及選單溢出。新換手只在練習，未做持鍵蓄力、選角或 VS。

Linux Godot 4.6.3 Compatibility／Mesa llvmpipe；音訊 Dummy，未實聽、未真人平衡、未驗收目標 GPU，未同步使用者電腦。原模型／貼圖／音檔保留；只更新衍生 UI 字體及來源 manifest。只推送開發分支，gh-pages 不更新。

## 最新：爽感規劃文件（2026-11-09；沒有改遊戲）

- 對照 `abf0dfc` 的交鋒／格擋、輸入、鏡頭、動作轉換與既有設計，完成 [GAME_FEEL_ROADMAP.zh-TW.md](GAME_FEEL_ROADMAP.zh-TW.md)。兩份使用者文字已完整讀取；未獨立觀看影片／核實原片時間碼、FOV 或速度門檻。
- 兩份來源共 34,716 bytes，大小及 SHA-256 與歸檔 manifest 全部一致；停用原文換行轉換。
- 新增計劃／來源索引及相關更新文件的 84 個本地 Markdown 連結檢查通過，`git diff --check` 通過；修改範圍只有文件／參考。
- 本輪沒有修改執行程式或資產，沒有重跑遊戲測試。新格擋連鎖、選角與 KO 演出尚未實作；不得將下方舊版測試結果當作新機制驗收。
- 同步政策：只推送 `codex/street-combat`，不匯出／部署、不更新公開 Web、不操作使用者電腦。同步前遠端 gh-pages 為 `2908503295c24b918b293b463ec962797a7ccb06`，推送後另確認。

## 最新：原生 UI、招牌與近身交鋒（2026-11-09，香港時間）

完整範圍、操作、重現及證據索引見 [EXTENDED_POLISH.md](EXTENDED_POLISH.md)。374 項規則／整合、104 項原生介面／輸入、7 項真實 X11 視窗失焦通過；最後 UI 以 53 項針對性重測，結算演出新增 15 項並以 69 項相關回歸確認。19 份執行腳本嚴格編譯及 512 次頁面／語言循環通過；保留新舊畫面及固定步進 GIF／MP4。

原生正常輸入測試完成 1,200.097 秒、31 回合／13 場、6,698 次鍵盤轉換事件。環境重連中斷了早期基線及候選觀察；兩者保留為未完成，不能當成連續三小時測試。恢復後的 `b6e439b` 觀察另完整完成 1,800.025 秒、21 次回合重開，詳見[統整](evidence/extended-polish/stability.json)。最終 `a238e3e` 的結算展示修正以針對性檢查補驗。

累計互動開發／驗證超過三小時，續接前的等待空檔已從工作時間排除。這不表示真人手感、實聽、目標 GPU 或使用者電腦已驗收。原有 33 個二進位資產保持不變，只同步原始碼；公開 Web 不更新。下方保留各輪歷史紀錄。

## 六件原型資產

| 資產 ID | 三角面 | 貼圖 | 使用尺度 |
|---|---:|---|---|
| PROP_HYDRANT_A01 | 1,477 | 512×512 | 高 0.9 m |
| PROP_BIN_A01 | 1,456 | 512×512 | 高 1.0 m |
| VEH_VAN_A01 | 1,582 | 1024×1024 | 長 4.2 m，等比縮放 |
| PROP_SHOP_STOOL_A01 | 1,513 | 512×512 | 高 0.45 m |
| PROP_CRATES_A01 | 1,491 | 512×512 | 整組高 0.8 m |
| PROP_MAILBOX_A01 | 1,440 | 512×512 | 高 1.1 m |

合計 8,959 三角面，每件一個材質。這是幾何計數，不是效能測量。精確來源雜湊、模型和包裝場景位置見 [assets-manifest.json](../assets-manifest.json)。

## 已執行

- 靜態讀取 GLB JSON／buffer，讀取面數、包圍盒、內嵌貼圖尺寸及 SHA-256。
- Blender 4.3.2 讀取並使用 Cycles CPU 渲染四角度；repo 的 evidence/ 保留六件斜角預覽。來源工作區的其他角度及 .blend 尚未全部納入 repo。
- Godot 4.6.3 完成無視窗匯入，載入各資產包裝場景及總展示場景，核對面數與碰撞節點。原聊天工作區紀錄見 [six-assets-godot-verification.log](evidence/six-assets-godot-verification.log)。
- 首次 repo 同步時重新驗證每份 GLB 與來源 SHA-256 一致。

## 重現命令

從 repo 根目錄執行：

```sh
godot --headless --editor --path godot --import --quit
godot --headless --path godot --script res://verify.gd
```

`verify.gd` 檢查六件資產的三角面、至少一個 CollisionShape3D，以及總展示場景能載入。腳本不是渲染測試，也不是玩家碰撞測試。

## 尚未驗證

- Godot GPU 實際畫面、目標硬體效能與輸出包。
- 遊走控制器的人工手感、更多相機角落、真實桌面輸入與飛機事件的人工視聽（自動檢查另見下方）。
- 最終 toon 材質及與參考照片／影片的畫面一致性。
- 全資產封閉拓樸。消防栓的診斷有開放邊，原型使用獨立簡化碰撞，未將來源網格強行修補。

所有資產目前僅接受為靜態街景原型，不標記為最終遊戲美術完成。

## 任務分支重新驗證

將資料搬入本 repo 後，在 Godot 4.6.3 重新執行兩個重現命令，均成功。另核對六件來源雜湊、模型／場景／參考圖路徑，以及非歷史文件的 Markdown 連結。結果：

- [匯入紀錄](evidence/repository-import.log)
- [六件載入核對](evidence/repository-verification.log)
- [來源完整性與文件檢查](evidence/repository-integrity.json)

以上仍不包含 GPU 畫面、實際遊玩或效能驗證。

## S1 街道白盒

已生成街道場景，完成五個相機切換與方向檢查、64 m／8 m 基準尺寸、四個引擎與開口、六件來源道具、251 個 mesh 節點及八個地面射線取樣檢查。原始六件 GLB 的 SHA-256 維持一致。主場景無視窗啟動通過。

- [白盒生成紀錄](evidence/whitebox/build.log)
- [檢查紀錄](evidence/whitebox/verification.log) 與 [結構化結果](evidence/whitebox/verification.json)
- [啟動紀錄](evidence/whitebox/startup.log)
- [來源資產回歸檢查](evidence/whitebox/source-assets-verification.log)
- [五張預覽及重現步驟](WHITEBOX.md)

預覽為 Godot 幾何快照的 Blender Cycles CPU 渲染，光照另設；不代表 Godot GPU 畫面驗證。S1 沒有玩家控制器，八個射線取樣不能代替玩家碰撞與整條路的人工遊玩。

## S2 遊走物理／邏輯檢查

Godot 4.6.3 headless，60 Hz 模擬，28 項檢查通過。包含實際角色移動、斜向速度、跳躍落地、人行道跳躍、超過 50 m 的連續主街通行、側巷、建築／廂型車／郵箱阻擋、牆邊相機臂縮短，以及相機模式、游標請求、重設及掉落回復。完整測量見 [verification.json](evidence/walk/verification.json) 及 [verification.log](evidence/walk/verification.log)。重現方式及未驗證範圍見 [WALK.md](WALK.md)。

本次測試注入應用程式輸入並跨 Godot 物理幀執行，不是人工操作。headless 不支援真實桌面游標鎖定，僅核對鎖定請求及輸入邏輯；GPU、手感和硬體效能仍待驗證。

## S3 風格樣片

Godot 4.6.3 Compatibility 透過 Xorg dummy／Mesa llvmpipe 軟體 OpenGL 4.5 實際擷取同鏡頭畫面；這不是硬體 GPU 效能測試。12 項樣片材質／切換檢查、S2 28 項遊走回歸與六件原始 GLB 雜湊檢查通過。投影開關及兩／三段畫面像素比較見 [STYLE_SAMPLE.md](STYLE_SAMPLE.md) 與其 evidence/style 紀錄。

最終風格、人為遊走感受、實體 GPU／效能及字型跨平台仍待驗收。

## S4 飛機事件與樣片調整

11 項 headless 事件檢查、28 項遊走回歸、12 項風格回歸與六件 GLB 載入／SHA-256 均通過。事件測試在退出時仍有 ObjectDB 清理警告。Godot Compatibility、Mesa llvmpipe 固定入口鏡頭擷取三個事件凍結位置；並非硬體 GPU、動態實機或音訊實聽測試。操作、證據與限制見 [FLYBY.md](FLYBY.md)。舊 S3 圖片是調整前的歷史快照。

## GitHub Desktop 指引與天空參考

本次為操作／交接文件更新；已核對目標分支及現有專案路徑。沒有實際操作使用者的 GitHub Desktop 或 Godot，也沒有將聊天中的天空圖檔匯入專案。前述 S4 測試結果為此前執行，不能視為本機使用者驗收。

## 程序天空樣片

Godot 4.6.3 headless 的 7 項天空及切換檢查通過，另重跑風格 12、遊走 28、飛機 11 項回歸通過；飛機測試仍有退出 ObjectDB 清理警告。Godot Compatibility／Mesa llvmpipe 已擷取入口比較與其他方向的靜態畫面。完整 360° 接縫、目標硬體與人工驗收尚未驗證，詳見 [SKY_SAMPLE.zh-TW.md](SKY_SAMPLE.zh-TW.md) 及 evidence/sky。

## 天空環視與接縫局部檢查

Godot Compatibility／llvmpipe：在高空隔離天空，擷取八個方向及接縫兩側；0°／360° 與 ±180° 精確相同，±179.75° 的中央區域按 5 像素對齊後約 0.21% 像素不同（未對齊約 1.66%），測試區域包含雲。天空 7 項 headless 回歸通過。這不涵蓋所有俯仰角、目標 GPU 或人工操作；檢查方法、原始圖和侷限見 [天空文件](SKY_SAMPLE.zh-TW.md)。

## 轎車候選參考圖

AI 依既有三視圖拼版製作單輛斜角參考圖，圖片已保存，尚未用 Tripo 生成或驗證任何轎車 GLB。本次未更改 Godot 程式、模型或遊玩結果；生成設定為建議，不能作為實際模型品質或成本的證據。

## 使用者上傳轎車與場景整合

原始 GLB 223,928 bytes、1,524 三角面、1,220 頂點、單材質、1024×1024 JPEG，來源與 repo SHA-256 一致。縮放後長 4.2 m；靜態盒碰撞與 B 材質切換另行包裝，原白盒保留。[六項 headless 場景檢查](evidence/car/verification.json)、28 項遊走、12 項風格、11 項飛機及七件資產載入檢查通過；場景測試與飛機測試退出有 ObjectDB 音訊清理警告。Godot Compatibility／llvmpipe 擷取[正面](evidence/car/01_front_street.png)與[背面](evidence/car/02_back_street.png)，車體陰影較暗；不是硬體效能或人工試玩驗證。工具 `game-dev` CLI 未安裝，未產生其 canonical package，也未以 Blender 正規化來源。

## 圖片天空及使用者貨車

貨車原始 GLB 282,288 bytes、1,510 三角面、1,490 頂點、1K 貼圖，來源與 repo SHA-256 一致；5.5 m 靜態包裝、碰撞和風格比較均通過，新增的 [11 項檢查](evidence/truck-sky/verification.json)及既有遊走／風格／天空／飛機／轎車、八件資產載入回歸通過。部分 headless 測試退出有 ObjectDB 音訊清理警告。[Godot 軟體渲染截圖](evidence/truck-sky/03_truck_front.png)顯示貨箱背面無明顯門件。

新生成天空圖 1774×887，原圖邊緣平均通道差約 0.72／255、最大差 6／255；llvmpipe 指定相機的 0°／360° 一致、±180° 相差 109 像素。詳細範圍與[圖片／程序比較](SKY_SAMPLE.zh-TW.md)有記錄；非完整接縫保證、硬體效能或人工試玩。

## 港式街景優化與動態飛機

13 項新場景／碰撞／功能檢查與遊走、風格、天空、飛機、轎車、貨車、S1 及八件資產載入／原始雜湊回歸通過。Godot Compatibility／Mesa llvmpipe 在 1280×720 擷取五個視角及描邊對照，並錄製固定 30 fps 模擬、10 fps 無聲影片。指定 800×450 測試場景的繪製呼叫由 1,871 降至 1,131，前後有少量幾何細節差異；不是硬體效能或 FPS。詳見 [STREET_POLISH.zh-TW.md](STREET_POLISH.zh-TW.md)。既存 ObjectDB 音訊清理警告、人工試玩與真實桌面／硬體仍待驗證。

此外，以提交 `9eff39c` 的乾淨 Git archive 在獨立目錄重新匯入並無視窗啟動成功；未見腳本或 shader 錯誤，退出仍有既存 ObjectDB 音訊清理警告。這是 Godot 匯入／啟動驗證，不代表使用者桌面試玩。

## 圖片天空、角色及低清貼圖（2026-11-06）

[來源雜湊](evidence/character/integrity.json)確認使用者 GLB 與 repo 位元相同；影片僅抽看約 5.6、31.9、43.2 秒的影格。Godot 4.6.3 headless：角色與貼圖 14 項，以及風格、天空、貨車、街道、遊走、轎車、飛機與 S1 回歸均通過；各原始報告與日誌見 [regression](evidence/textured/regression/)。部分既有測試退出有 ObjectDB 音訊清理警告。

Godot Compatibility／Mesa llvmpipe 截圖與 60 Hz 模擬、20 fps 無聲角色步態錄影不是人工遊玩、目標 GPU 或實際效能測試。更多方法與限制見 [CHARACTER_TEXTURES.zh-TW.md](CHARACTER_TEXTURES.zh-TW.md)。

以本提交的乾淨 `git archive` 副本重新執行 Godot 4.6.3 headless editor 匯入及角色／貼圖 14 項測試，兩者退出碼均為 0；[匯入日誌](evidence/character/clean-import.log)、[驗證日誌](evidence/character/clean-verify.log)。乾淨匯入不代表使用者本機 GPU 測試。

## JSR／BRC 風格規範對照（2026-11-06）

使用者原始檔 SHA-256 為 `7547594616f67916d3d35c6c1211bf46f8731ba337c1c2a48793b0c0c287b0de`；與 `origin/main` 提交 `54a520d` 整理版皆已保留。Godot 4.6.3 headless 11 項取樣與材質切換檢查、既有風格 12 項回歸通過。固定場景、相同相機使用 Godot Compatibility／Mesa llvmpipe 比較線性及最近鄰；約 5.29% 畫面像素有差異，不能以差異量判定美術品質；[截圖及測試記錄](evidence/style-reference/)。未進行實機移動閃爍測試、硬體 GPU、人工驗收或官方技術規格查證。

從提交 `8b13d3d` 的乾淨 Git archive 副本重新匯入並執行取樣測試，兩者退出碼為 0；日誌見 [clean-import.log](evidence/style-reference/clean-import.log) 與 [clean-verify.log](evidence/style-reference/clean-verify.log)。這不是目標 GPU 測試。

## 環境 mipmap 匯入修正（2026-11-07）

三張 128×128 貼圖重新匯入後，Godot `Image.has_mipmaps()` 為 true，`get_mipmap_count()` 各為 7（不含原圖）；[紀錄](evidence/mipmaps/verification.log)。11 項既有材質取樣檢查再次通過；[紀錄](evidence/mipmaps/filter-regression.log)。未測試移動時閃爍、GPU 效能或真人遊玩。

## 飛機音效清理警告定位（2026-11-07）

飛機回歸 11 項通過，verbose 顯示退出時保留 `AudioStreamWAV` 與 `AudioStreamPlaybackWAV`；停止並清空 stream 的臨時實驗未排除警告。詳見 [原始日誌](evidence/audio-diagnostics/flyby-verbose.log) 和 [實驗日誌](evidence/audio-diagnostics/flyby-clear-stream-verbose.log)。無法由此確定記憶體洩漏根因或實際遊戲音訊表現。

## 立面花槽與外伸架（2026-11-07）

Godot 4.6.3 headless 的街景及遊走回歸通過，紀錄見 [balconies](evidence/balconies/)；1280×720 畫面透過 Xorg／Mesa llvmpipe 擷取，不是硬體效能或人工試玩。

## 店面遮篷、捲閘及管線（2026-11-07）

Godot 4.6.3 headless 街景與遊走回歸通過；Godot Compatibility／llvmpipe 擷取中段和人行道畫面，日誌與圖片見 [streetfront](evidence/streetfront/)。未驗證目標 GPU、硬體效能及真人遊玩。

## 住宅陽台與天線（2026-11-07）

Godot 4.6.3 headless 街景及遊走回歸通過；Compatibility／llvmpipe 固定鏡頭前後 draw calls 1,131→1,131、primitives 86,297→88,181；測量、方法和仰視截圖見 [residential](evidence/residential/)。未驗證真實 GPU、FPS、真人遊玩或風格定案。

## 近身格鬥第一版（2026-11-07）

- Godot 4.6.3，34/34 headless 格鬥邏輯與場景檢查：包括三段連擊、縮放傷害、朝向／高度／範圍、同時命中交換、衝刺無敵、頓幀和輸入緩衝、防禦破防、能量、挑空、KO／時間用盡／平手／重賽與暫停。
- Xorg dummy / Mesa llvmpipe，960×540，11/11 自動輸入檢查：以 `Input.parse_input_event` 經 viewport 驗證開始、移動、跳躍、重招、暫停、靜音、減少演出和雙向 F6 場景切換。不是真人鍵盤試玩。
- 既有 28/28 遊走及 13/13 街景回歸通過；後者仍有既存 ObjectDB 音訊清理警告。新格鬥檢查未見腳本錯誤或該清理警告。
- 1280×720 Godot Compatibility 軟體渲染截圖：主選單、戰場、命中、挑空和暫停；自動輸入示範另外標記為 scripted。
- 原始角色與場景來源不改。尚未驗證真人手感、實聽混音、目標硬體 GPU、幀時間、最終美術或獨立匯出。

證據與重現工具見 [COMBAT.md](COMBAT.md) 及 [combat 證據目錄](evidence/combat/)。

## 街口透視格鬥背景（2026-11-07）

14/14 新背景邏輯檢查、34/34 格鬥回歸及 11/11 Xorg/llvmpipe 自動輸入與場景切換通過。1280×720 及 960×540 的 Godot Compatibility 畫面已擷取查看。最終截圖和輸入日誌未見腳本、shader 或材質錯誤；試作時的材質清理問題在修正材質覆寫並保留資源後未再出現。詳細參數及影片抽樣限制見 [背景文件](STREET_COMBAT_BACKGROUND.md)，證據見 `evidence/street-angle/`。未做目標 GPU 效能、真人遊玩或音效驗收。

## 五點試玩回饋回歸（2026-11-07）

30/30 新實際骨架／動畫／統一透視／鏡頭／留白檢查、34/34 格鬥、11/11 原生 viewport 輸入與場景往返、28/28 遊走、13/13 街景通過，共 116 項。拳頭由架勢位置向對手伸出約 0.75 m（含視覺踏步），重踢足部向前、骨架取樣有限且正規化；這些是腳本量測，不代表真人手感評分。新日誌、畫面及授權來源見 `evidence/playtest-fixes/` 和 [PLAYTEST_FIXES.md](PLAYTEST_FIXES.md)。格鬥原始 GLB 和街道白盒無修改，既存遊走音訊退出警告仍在。軟體渲染不是目標硬體 FPS 證據。

## 場景接回、開放音訊與 VFX（2026-11-07）

新場景／音訊／VFX 33/33、警告編譯 3/3、格鬥 34/34、動畫與透視 30/30、自動 viewport 輸入 11/11、遊走 28/28、街道 13/13、固定 60 fps 飛機 11/11，共 163 項通過。四項截圖警告由三類警告提高為編譯錯誤覆核。來源場景比例、天空原圖、車輛、細節、貼圖 world UV、機鼻與速度同向、航道高度、CC0 音訊資源與開關、精準防禦與起手反擊均有自動檢查。

16 張 Godot Compatibility／llvmpipe 畫面已檢視構圖與描邊比較。7.1 秒含聲示範是腳本輸入；音軌 AAC 立體聲，FFmpeg peak -7.7 dBFS，不是真人實聽。獨立飛機／街道回歸仍有音訊退出 ObjectDB 警告；新格鬥擷取與影片另有清理檢查。來源及完整範圍見 [SCENE_AUDIO_VFX.md](SCENE_AUDIO_VFX.md)，日誌見 [本輪證據](evidence/scene-audio-vfx/)。未作真人試玩、目標硬體 FPS 或完整美術驗收。

## Web 匯出驗證（2026-11-07）

Godot 4.6.3 Web release 成功，單執行緒 Compatibility。實際 Web PCK 在 Native runtime 完成 8/8 檢查：JSON 存在／解析、動畫角色、天空／紅車、音訊、攻擊傷害、F6 原街景及返回。Node WebAssembly.compile 與原生 Web Streams 無損解壓、HTML JS 語法及資產雜湊檢查通過。不是瀏覽器 GPU、真人遊玩或實聽驗收；Sites preview relay 不可用，依技能未另起替代瀏覽器。日誌及後續部署結果見 `evidence/web/`、[WEB_PLAYTEST.md](WEB_PLAYTEST.md)。

## Web 公開發佈完成（2026-11-07）

試玩網址：https://afterhours-street-fight.beamingladybird1.chatgpt.site 。Sites version 1、部署 `appgdep_6aee954c0f3c8191866e36096a914642` 成功，native get_site 確認 public 及同一 current_live_url。GitHub 遊戲來源 `77c0026`，Site source `3dcb8dc`。分享頁、遊戲及授權共約 19 MB。

實際匯出的 PCK 8/8、WebAssembly／Web Streams／實際 fetch adapter compileStreaming、HTML 語法及本機資產雜湊通過。匿名 HTTP 下載被 Cloudflare 403／1010 阻擋，未驗證線上資產內容；預覽服務仍不可用，沒有宣稱完成瀏覽器遊玩或實聽。更多來源與重現見 WEB_PLAYTEST.md 和 evidence/web/。

## GitHub Pages 準備及權限阻礙（2026-11-07，香港時間）

同一 Web 匯出已推送 gh-pages c663ec5；15 件資產 SHA-256 通過，實際匯出 fetch adapter 在根路徑及 /Game-Lab-3/ 下的 WebAssembly.compileStreaming 通過。repo API public / admin=true / has_pages=false；POST 啟用 Pages 回應 403 Resource not accessible by integration，目標網址回應 404。尚未有 GitHub Pages 線上部署或瀏覽器驗證，未以成功推送分支冒充發佈成功。來源、API 訊息和檢查見 evidence/github-pages/ 及 WEB_PLAYTEST.md；等擁有人於設定頁啟用。

## 2026-11-08 戰鬥完善基線與邏輯

GitHub Pages built，舊版匿名 HTTP 15/15 及 Chromium WebGL／Enter、D、J、K、Esc 畫面通過，JS pageerror 為空。新 32/32、格鬥 34/34、場景／音訊 33/33、骨架／相機 30/30、警告 3/3、headless viewport 輸入 11/11，共 143 項通過。保留音訊退出清理警告；本機 Web 預覽被代理 Loopback targets forbidden 阻擋，改在公開發佈後驗證，未繞過限制。新版公開驗證完成後另補；詳見 COMBAT_POLISH.md 和 evidence/combat-polish/。

## 戰鬥完善版已上線（2026-11-08，香港時間）

https://yauchai2.github.io/Game-Lab-3/ ：Pages 2908503 / 遊戲來源 e2c7e10，公開 built；15/15 資產雜湊。新邏輯 35 + 格鬥 34 + 場景／音訊 33 + 骨架／透視 30 + 警告 3 + headless viewport 11 + Web PCK 8 = 154 項通過。最新 Chromium WebGL／F5／F7／AudioContext／IndexedDB／全螢幕／重載 7/7 通過，JS 與 console 錯誤空白；軟體 GPU，不是真人／聆聽／硬體效能驗收。

T 進無限練習、F5 重置、F7 切對手；正常對局 Enter。挑空僅在未被防禦的命中後允許 Space 追擊；前三次浮空命中後落地。模式／難度／演出與聲音保存在本機。所有目前狀態與後續限制見 COMBAT_POLISH.md；最新證據在 evidence/combat-polish/。舊音訊退出警告、投技、第二角色、手柄與手機觸控仍待後續。

## 原生 Godot 街角加密（2026-11-08，香港時間）

新 28 + 遊走 28 + 街景 13 + 骨架／相機 30 + 格鬥 34 + 練習 35 + 場景／音訊 33 + 材質 11 + X11 viewport 輸入 11 + 舊警告編譯 3 = 226 項通過。3,001 新實例、10 批次、8 材質、六棟鄰樓，三張 128×128 貼圖各 7 層 mipmaps；新增幾何／碰撞與戰鬥保留範圍交集為零。

七角度同鏡頭 baseline／candidate 是 Godot 4.6.3 Compatibility／llvmpipe 實際擷取，另保留原程式最初畫面。關閉新層的中央影像與最初中央影像完全相同。中央 draw calls 963→978，寬景 1053→1075；不是 FPS／目標硬體或美術品質評分。原 GLB 位元不變，保留舊音訊退出警告，擷取無腳本／shader 錯誤。來源、方法、日誌與限制見 CORNER_DENSITY.md 和 evidence/corner-density/。

依使用者規則本輪僅推送原始碼，不更新公開試玩；gh-pages 維持 2908503。未聲稱已同步或測試使用者電腦。

## 招牌與動態天空（2026-11-09，香港時間）

新 18 + 街角 28 + 骨架場景 30 + 天空切換 7 + 場景音訊 33 + 街景 13 + 遊走 28 = 157 項通過。角度漂移／暫停／F2 的 session 接線、環境光不變、長時間 wrap、圖片／程序雲切換及四個空白牌皆已檢查。七角度 Godot Compatibility／llvmpipe 擷取及同相機 0/60 秒雲圖見 evidence/scene-composition/；時點對照非連續錄影。保留既有音訊 ObjectDB／resource 退出訊息；非真人或硬體效能驗收。未部署 Web，gh-pages 保持 2908503。

## 分段打擊演出（2026-11-09，香港時間）

24 新規則／畫格＋格鬥 34＋練習 35＋場景音訊 33＋天空 18＋X11 viewport 輸入 11＝155 項通過。涵蓋 432 組左右畫格有限／可三角化／不透明，真實命中頓幀與釋放、交換／擋格／揮空、重置／主選單／回合／KO 和 F2。天空兩個 session 接線斷言改用 _process，重跑通過；舊測試只呼叫姿態函式的覆蓋不足已修正。16 原生擷取及 32 幀固定步進 GIF 在 evidence/impact-staging/，不是 realtime FPS、實聽或真人手感；舊音訊退出清理訊息保留。simulation 不變，公開 Web 未更新，gh-pages 仍 2908503。

## 交鋒壓力原型（2026-11-09，香港時間）

核心規則／整合新 59 + X11 viewport 新輸入 11 + 格鬥 34 + 練習 35 + 分段演出 24 + 場景音訊 33 + 骨架相機 30 + 天空 18 + 舊 viewport 輸入 11＝255 通過。涵蓋完整 3×3 結果及傷害、壓力衰減／觸發／冷卻、凍結／首鍵鎖定／超時、AI 承諾、暫停／重置／回合／KO、練習無限等待、場邊界及四腳本嚴格警告編譯。兩實例相同指令 20,000 步狀態一致且有界，混合對戰自然 20 次對峙，非正式平衡性／勝率評估。原生 1280×720／960×540 畫面與固定步進 GIF 見 evidence/pressure-exchange/，非真人、實聽或硬體 FPS。保留舊音訊退出清理訊息。沒有更新公開試玩／gh-pages，也未同步使用者電腦。

## 2026-11-10 統一像素及無聲恢復

144條戰鬥回歸、37條native操作、15條新呈現及6條PCM檢查通過；19條招式路由真命中擷取。4.6.3 Compatibility／llvmpipe，Dummy音訊混音，不宣稱目標4.7.2／Mac喇叭驗證。環境GLB編輯器VK匯入失敗及批次擷取退出ObjectDB警告有記錄。 詳見 [實作及證據](UNIFIED_PIXEL_RUNTIME.zh-TW.md)。Web不變。

## 2026-11-10 UI文字可讀性及4.7.2覆核

Godot4.7.2 Linux Compatibility：22條呈現／材質、37條原生操作、144條戰鬥回歸及6條PCM測試通過。壓力測試已重現截圖4類材質錯誤；frame_post_draw保留舊材質及延遲hero初始化後，6項材質生命週期嚴格回歸零engine error、pending歸零。Mac硬件仍待覆核。首次退出8個ObjectDB警告、最終verbose未重現，保留追蹤。 詳見 [本輪紀錄](UI_READABILITY.zh-TW.md)，Web不變。

## 2026-11-10 無臉半身封面

Godot4.7.2 native Compatibility／llvmpipe，37項原生操作／三視窗尺寸／音樂transport檢查通過，無ERROR。人工檢視兩個無五官上半身剪影，圖片alpha全255確保後方世界不透出。不是Mac或自動人臉檢測證明。 詳見 [封面紀錄](FACELESS_COVER.zh-TW.md)。未更新公開Web。

## 2026-11-10 全套Ink UI

Godot4.7.2 Linux Compatibility：37原生操作、10頁面／3D剪影／popup／實際角色材質隔離檢查、6材質生命週期檢查通過，strict runner無engine ERROR。初期嵌入popup擷取退出有4個ObjectDB警告，關閉嵌入窗口並等待音訊釋放後最終page-suite未重現。Result為明示fixture擷取，不是KO實玩證明；目標Mac未測。 詳見 [實作與證據](INK_UI.zh-TW.md)。原始素材及公開Web不變。

## 2026-11-10 Neon Facets規劃分支

完成六檔下載／ffprobe／SHA及完整時間軸2fps接觸圖檢視，總長80.200s；4張inline圖於對話檢視。分支基線885f1c1，godot runtime差異為空。僅驗證文件鏈接／JSON／來源雜湊與分支隔離；未跑新的shader／玩法／性能測試，也不拿基線通過結果當新風格證據。詳見 [計劃](NEON_FACETS_PLAN.zh-TW.md)。Web與穩定分支不變。


## 2026-11-11：CITY BREAKER 原生 KO

164新過場、17結果、37原生UI／持續音樂、62二段跳、45正式玩法、30SURGE通過；四角×雙方、真special傷害KO、逐鏡有限相機、資料不變、靜態batch／飛機／模型清理、輸入跳過、暫停、F2、重開與超時不誤觸。Godot4.6.3 Linux Compatibility／llvmpipe／Dummy audio，最終過場／UI log無ERROR或SCRIPT ERROR，最終過場無ObjectDB警告。舊Rhythm23/29六失敗在未改4177ef9隔離worktree重現相同結果；不稱全套零失敗。畫面與150幀15fps無聲影片見evidence/city-breaker，來源／切點／差異見CITY_BREAKER.zh-TW.md。初期headless換模null material及早期測試修正有界線紀錄；未將Dummy或renderer載入當作Mac、實聽或效能證明。


## 2026-11-11：KO聲畫FX

15新增FX／實際PCM／音量／mute／pause／清理，164KO、17結果、37原生UI／音樂及6原混音回歸通過。Godot4.6.3 Linux Compatibility／llvmpipe／Dummy音訊；最終log無ERROR／SCRIPT ERROR／資源洩漏。Movie Writer同錄640×360／30fps與立體聲48kHz，裁準備1幀後10秒，影片AAC解碼峰值0.467／RMS0.040／零削波，沒有事後配音。這不是Mac硬件、即時30fps效能或真人實聽證明；未重跑整個歷史suite，舊Rhythm六個基線失敗仍保留前輪紀錄。過早結束的result測試曾有音訊資源未drain，測試改為先停止player／等待混音後退出，最終17/17無警告。詳見evidence/city-breaker-fx。


## 2026-11-11：五秒快節奏KO

20項FX／實際PCM／節奏、165四角雙方KO生命週期、17結果檢查通過。驗證音軌及過場同為5秒、pitch_scale1、時間映射不倒退且正反一致、空爆局部慢拍、KO收尾>=0.9秒、4.983秒仍活動及5秒截止。最終原生log無ERROR／SCRIPT ERROR／洩漏；5秒Movie Writer聲畫及AAC解碼音訊見evidence/city-breaker-fast。Godot4.6.3／llvmpipe／Dummy，固定30fps匯出不代表目標Mac即時效能；未重跑整份歷史suite。


## 2026-11-11：勝者魚眼與四角色離場

86新檢查：四角×雙方、真模型／頭部構圖／不同骨架姿態、正確exit音軌、pause／resume／skip、實際出框、資料不變、near／fisheye／音訊還原、F2／重開／標題與自然結算。20FX＋165KO＋17結果回歸通過，最終log無ERROR／SCRIPT ERROR／洩漏。四套3.2秒原生Movie Writer聲畫與8.2秒完整KO流程、PCM量測見evidence/victory-exits。原5秒聲軌與HEAD版PCM解碼比對相同，未改基段音高。Godot4.6.3／llvmpipe／Dummy；不是Mac、即時GPU效能或真人實聽驗收。早期近鏡曾發現RIVET裁臉與LOOP手部遮擋，已按真head anchor與姿態改位，最終四角實際擷取並檢視。歷史suite未全重跑，舊Rhythm基線失敗仍保留。

## 2026-11-12 音訊重做
`verify_combat_sfx.gd` 32/32；`verify_unified_audio.gd` 無削波；`verify_music_audio.gd` 舊套件 13/20（改動前 12/20）。無人耳／Mac／真實喇叭驗證，見 docs/AUDIO_OVERHAUL.zh-TW.md。

## 2026-11-12 全部 PR 合併後驗證（Godot 4.6.3 Linux，xvfb＋llvmpipe，Dummy audio）

通過：warnings 嚴格檢查（17 腳本）、local_versus 68/68、story_opening 35/35、round_flow 24/24、city_campaign 50/50、city_expansion 86/86、ability_draw 69/69、banter 129/129、time_of_day 12/12、flyby_event 8/8，story_waves／live_combat／ink_fx／unified_audio／black_suit／street_tags／versus_social／secret_notes／combat_sfx 無失敗項。
失敗：reference_ui 37/38，「rapid navigation reverses existing crossfade」；在 PR #11 分支單獨同樣失敗（#11 把選單／戰鬥改成不同曲目，舊斷言過時），合併未改。reference_ui 與兩處原始碼已為合併調整：FREE PLAY 頁、`/1000`→`/1000.0`、`basis` 改名。
未驗證：實聽、Mac、實機手柄、目標 GPU、公開 Web。
