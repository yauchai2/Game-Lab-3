# 接續工作交接

## 2026-11-11：結果頁修復、決勝KO與四面反彈

修正RESULT空白：先前在CityBreaker仍active時提前設finish_menu_open，rebuild把controls隱藏；之後director清場但沒有再建選單。本輪在演出釋放後才建立結果操作，並對空白狀態自我恢復。原生測試驗真visible buttons、視窗內位置及pressed callbacks，涵蓋自動播完／暫停／F2／跳過、下一回合與重賽。

依最新指示完整KO只在兩勝制決勝回合；之前回合短結算。Street Run只在最後一站或本次Run敗退結束播完整KO；超時不偽造零生命KO。Demo仍沿真勝負loop，每場只有決勝KO，之後接下一場開場。

正式Rush／Demo／Street Run加入四面盒狀反彈：x±8.2、腳部y0–5.6（8m頂框），重擊／挑空／終結擊／符合推力的技能真命中才發射，普通輕拳不觸發。法線反射耗能、無額外碰牆傷害；每次飛行最多6個接觸／180物理tick，耗盡自動恢復＋18tick保護，不被新命中刷新預算，落地後才重置。接觸後18tick內可E花20能量受身；AI有有界反應延遲。暫停／hitstop不消耗飛行時間；F2保持物理，只減演出。

真3D透明線框圍場、每面重用一個撞擊格、既有SFX／揚塵／速度尾跡／軀幹中心翻滾。高速飛行鏡頭以雙人body bounds即時退開，避開HUD，反彈字卡移到底部。513項focused checks全數通過；9秒四角合法挑空反彈預覽及約56.7秒自然三回合／下一場有聲錄像。詳見[evidence/arena-box](evidence/arena-box/README.md)。同codex/combat-escalation-next／PR #6推來源，不發佈Web；Mac／真人平衡、鏡頭和混音待驗收。

## 2026-11-11：完整回合演出、AI Demo循環與煙霧

正式FIGHT／Street Run加入2.8秒同場3D開場：街景、P1／P2角色近鏡、ROUND，再交回原倒數及對戰。Enter／Space跳過，Esc暫停，練習保持即玩。AI Demo改正常有限生命、不回血，真KO後播完整5秒破壞＋3.2秒勝者魚眼與離場，之後自動下一回合；兩勝完場也繼續loop，沿用選角、不發XP。覆蓋舊Demo endless／無KO契約，正常FIGHT結果仍由玩家確認。

場景加入有界屋頂／街邊煙、命中揚塵及64團KO殘煙；重擊後可短暫魚眼近鏡，避讓Neon大招與KO，保持雙人及HUD留白。新增原創2.8秒開場音軌，沿原SFX／mute／pause及BGM duck。26回合／選角／清理＋86勝者＋20FX＋165KO＋37UI＋11Demo輸入＋7Demo規則＋17結果共369項通過；40.4秒連續兩個真KO有聲錄像。詳見[本輪證據](evidence/round-flow/README.md)。來源同codex/combat-escalation-next／PR #6，公開Web不更新；Mac／硬件效能與真人強度仍待驗收。

## 2026-11-11：勝者超近魚眼與專屬離場

依最新要求在K.O.後追加3.2秒，總長8.2秒，前5秒不變。victory_exit.gd以當局勝者／真骨架做四套姿態與離場：ZIP甩手側滑、RIVET雙拳重步、HUSH側頭回眸、LOOP右手花式轉身。124°FOV＋桶形fisheye，依各rig頭部取景，慢步真正出框後才出結果；背景破壞繼續慢動態。4套原創exit音軌第5秒切入，BGM／mute／pause保持；clear還原near／fisheye並停音，F2／重開／返回皆測。86新勝者＋20FX＋165KO＋17結果通過，四角及完整有聲影片在evidence/victory-exits。不是mocap／足底IK或物理魚眼校準；Mac／真人實聽／目標GPU待驗，來源同branch／PR #6，Web不更新。

## 2026-11-11：KO整體加快一倍

使用者要求整體加快一倍並保留節奏／爽感，本輪作用於這段KO過場：正式播放10→5秒，用timing.json共享非線性映射，保留撞樓短重拍、約3.61秒空爆慢拍及4.08–5秒KO收尾。動畫age保留原10秒作者時間；新增playback_elapsed是真5秒時鐘，session結算使用DURATION5。聲效按相同profile重新合成5秒，pitch_scale1保持低頻／音高；JSON加入export filter但未發佈。20FX／PCM＋165KO＋17結果通過，有聲Movie Writer影片見evidence/city-breaker-fast。F2／靜音／暫停／跳過清理保持；不改正式simulation速度／傷害。來源同branch／PR #6。

## 2026-11-11：KO聲音與誇張漫畫FX

依使用者最新要求，原CityBreaker正式KO入口加上原創10秒立體聲score、SFX bus／靜音／音量／暫停位置保持與clear停止，BGM原owner加入4–8dB duck但不停transport。邊緣放射模糊／短色差／高對比、漫畫速度線與字卡、3D衝擊環、FOV反衝／14°內roll由同一director擁有。15FX真PCM＋164KO＋17結果＋37UI音樂＋6混音通過；實際Movie Writer有聲10秒30fps影片見evidence/city-breaker-fx。原來源模型及判定不變；Mac／真人實聽／目標效能待驗。來源同branch／PR #6，Web不更新。

## 2026-11-11：CITY BREAKER 正式 3D KO 過場

使用者指定 codex/combat-escalation-next，按所附10秒影片接正式KO，現況與差異見 [CITY_BREAKER.zh-TW.md](CITY_BREAKER.zh-TW.md)。八鏡按24fps剪接點對齊、當局人物直接演出、同一街景／飛機可逆分件、回合結果延後、Enter／Space跳過與Esc暫停／F2／重開／退出清理。simulation傷害與獎勵保持權威，無影片貼圖或固定角色。164新過場＋17結果＋37UI／音樂＋62二段跳＋45正式玩法＋30SURGE通過；舊Rhythm23/29在未改4177ef9重現。Godot4.6.3／llvmpipe／Dummy audio，原生影片為15fps無聲取樣，不是Mac效能或逐像素復刻。沿同一branch／PR #6推來源，Web不更新。

## 2026-11-10：正式二段跳與落地輸入改善

已在現行共用空中 simulation 加入每次離地一次二段跳，Space 放開再按，10.5m/s，不取消攻擊／受擊／追擊或補回空中資源。落地恢復保留 8 tick 跳躍預輸入，加入收腿、月牙、上揚聲及操作提示。詳見 [DOUBLE_JUMP.zh-TW.md](DOUBLE_JUMP.zh-TW.md)／[本輪驗證](evidence/double-jump/README.md)。62 新規則、11 原生輸入、45 現行正式戰鬥、201 相關規則、13 鏡頭、37 原生 UI 通過。另 4 個舊斷言失敗已於未改動 f53c378 重現，完整 suite 並非零失敗；詳見證據。Godot4.6.3 Linux llvmpipe／Dummy audio，Mac／真人／實聽待驗收。沿同一來源 branch／PR #6；公開 Web 未更新。


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


同步注意：本輪最後核對時，遠端codex/street-combat已由其他工作合入PR4（e4329e9，LAST SERVICE角色文件／圖），不是本Lab所推送。本Lab保留原基線與獨立玩法；藝術總庫已跨連該批圖，沒有rebase或覆寫其他工作的文件。gh-pages仍為2908503。

## 2026-11-10：加長大招與藝術參考庫

使用者要求大招更長／近鏡／更多旋轉，已接入四人五段程序pose、overdrive共用時鐘0.22s hold／0.78s slow／0.44s release、36°起手鏡頭及最高14°roll；攝影機按雙方body bounds拉遠。真正受擊中斷／被招架才取消，護甲保持攻擊時不取消。見 [NEON_SIGNATURE.zh-TW.md](NEON_SIGNATURE.zh-TW.md)，覆蓋M1最高6°及短大招的數字。原模型／判定／音訊來源與Web不變。

藝術文件／六段風格原片／圖片與生成素材／兩段長篇完整時長壓縮研究版集中在 [參考總庫](../references/style-library/README.md)。原圖缺件及原Drive連結／hash皆列明；Release上傳401已改用Git內研究副本，空draft已刪。

[RPG／加點／解鎖](RPG_PROGRESSION_PLAN.zh-TW.md)只完成具體提案，尚未加入runtime。推薦單人街區＋三路技能板＋兩裝備節點，標準對戰固定數值，四角色和基本技巧不鎖。後續先完成新pose／逐招VFX與M2場景，再切RPG存檔及結算。


## 2026-11-10：Neon Facets M1已實作

`codex/neon-street-lab`已從規劃進入可玩切片：場景／既有細節合批的Lab材質、五階桃紅天空、四人切面shader、格擋／蓄力／重擊／BREAK／KO單一全屏director、短剪影與回氣、24個局部效果上限、最高6°roll及獨立Lab偏好。原GLB／判定／音檔保留；Web與穩定分支不變。

詳見 [NEON_FACETS_RUNTIME.zh-TW.md](NEON_FACETS_RUNTIME.zh-TW.md)及[連續錄像／驗證](evidence/neon-facets/README.md)。21 Lab＋53 native UI／材質＋134規則＋6音訊檢查通過；30s virtual-wall自由AI19／32命中、強stage7.44%。不是目標Mac性能證明，未同步使用者電腦。下一包M2全道具語義材質／葉端／雲動畫，然後M3新輪廓與pose；不得把M2–M6當已完成。


## Neon Facets實驗分支：規劃階段（2026-11-10）

本worktree屬 `codex/neon-street-lab`，由885f1c1另開，主線及公開Web不變。使用者要求整個遊戲轉新附TR3B參考風格並詳細規劃；六片80.200s以2fps抽樣、10張contact sheets已檢視。具體方案在 [NEON_FACETS_PLAN.zh-TW.md](NEON_FACETS_PLAN.zh-TW.md)：常態切面材質／色塊人物，格擋／蓄力／重擊才短剪影；含地圖、4人、FX、鏡頭、三時鐘、音訊、背景director及M1–M6驗收。

**本輪只建立規劃分支與來源研究，godot runtime檔案未變；不是已完成風格版試玩。** 下一包是M1代表切片（雙樓／道路／2人＋parry/charge/release＋30s A/B），實作時保留F2／4.7.2材質退休機制與原始GLB。


## 2026-11-10：新封面、Logo及全套Ink UI

使用者要求重新生成、不要項鍊，並將其他頁面與Logo統一。已接入新兜帽／帽沿半身圖、無皇冠白字Logo、共用黑白城市／桃紅背板、原生按鈕及方切控件。選角仍為真3D不同pose，但用純色無五官剪影；戰鬥原材質保持。詳見 [INK_UI.zh-TW.md](INK_UI.zh-TW.md)。37原生操作＋10頁面＋6材質檢查通過，素材拆件於 `godot/assets/ui/ink`。只更新來源分支，不更新Web。


## 2026-11-10：無臉半身剪影封面

使用者提供兩段低多邊形影片作風格參考，並要求不見人臉；後續指定低調酷的插袋姿勢、僅上半身。已生成並接入雙人青／螢光綠純色半身剪影，黑白城市及桃紅天空；主選單改為原生5選項與既有Logo，維持清楚像素字體。角色選擇及戰鬥仍沿用原模型。見 [FACELESS_COVER.zh-TW.md](FACELESS_COVER.zh-TW.md)，37條native操作通過，原始素材及Web不變。


## 2026-11-10：UI可讀性及Godot4.7.2覆核

使用者回報字太細與6項診斷。已放大設定／按鈕／HUD提示，面板擴闊與增加行距；採新14px body／16px display bitmap衍生，常用邏輯字級24／28／32（內部12／14／16），大標題保留較高解析來源。底部操作列、Pause及Enter／Esc提示改為原生清楚文字。修正swap變數作用域與ArrayMesh／BoxMesh三元警告，新增幾何基礎材質並先完成surface替換才釋放override。詳見 [UI_READABILITY.zh-TW.md](UI_READABILITY.zh-TW.md)。已用與截圖相同Godot4.7.2 Linux Compatibility覆核；已重現首幀換模過早釋放材質並修正：舊材質保留至frame_post_draw，3次場景／24次選角嚴格測試零renderer error且佇列歸零；Mac硬件仍待覆核。原模型／圖／音檔不改，Web不動。


## 2026-11-10：統一像素、活街景及音訊恢復已接入

本輪開始執行 [統一美術計劃](UNIFIED_PIXEL_ART_PLAN.zh-TW.md)，實作與界限見 [UNIFIED_PIXEL_RUNTIME.zh-TW.md](UNIFIED_PIXEL_RUNTIME.zh-TW.md)。全畫面640×360整數放大、兩款衍生bitmap字體、5個隔離3D選角viewport／四人不同姿態、分級放大的向量技能、低解析路面貼圖／不齊立面／植物剪影／28件路邊垃圾、4位背景人物及遠景車／樹葉／紙片／燈光動態已接入。新增音訊bus、可見靜音恢復及測試入口，音樂繼續播放且暫停只降低音量。原始GLB／音樂／UI來源圖保留，Web不變。


## 最新規劃：統一像素美術與活街景

使用者要求詳細規劃，方案見 [UNIFIED_PIXEL_ART_PLAN.zh-TW.md](UNIFIED_PIXEL_ART_PLAN.zh-TW.md)。先統一世界／UI／VFX／字體640×360合成，再做JSR式字族、3D選角與4人不同pose、特效尺寸、手工街景／植被／垃圾及有界背景動態。現有world-only pixel shader是主要風格差距；天空／飛機可沿用。本輪僅文件，runtime與Web不變。


## Latest: reference UI and continuous music

Current policy: [REFERENCE_UI.md](REFERENCE_UI.md). Exact title art, five buttons, native card/P1/P2 selection and reference-layout HUD. English; original files remain. Pause ducks music and transport continues; two dedicated crossfade decks. Active combat renderer is authored vectors, old generated stamps/echo sticks retired. Native37/37,19 actual move routes,144 headless and47 rhythm/red-stage checks. Web unchanged.


## JSR UI 正式接入／四流派／新音樂

本輪正式採用上一輪 JSR 方向，並加入四角色差異、護目鏡94%身高、低解像設定與兩首使用者音樂。詳見 [JSR_RUNTIME.md](JSR_RUNTIME.md)。這覆蓋先前研究未接入／四人共用能力／scale1.4／wev 預設；Web 仍不更新。


## 最新：JSR UI 研究與生成素材（2026-11-09）

使用者要求詳細研究 Jet Set Radio UI 並生成 UI/assets。已完成 [研究／接入規格](JSR_UI_ART_DIRECTION.zh-TW.md)，以 2000 原版語言＋香港地下電台為主線。實看 4 張 SEGA 官方 2012 PC 截圖、英文 Dreamcast 手冊掃描 10 頁，原作／提案數值清楚分開，字體名稱未假稱已核實；源圖／手冊不入素材包。

共 9 張生成稿，主要交付 6 張 PNG：3 個主選單／精簡 HUD／角色方向圖，3 個 RGBA Logo／8 框架／16 圖示。完整提示詞、來源 SHA、圖集座標及 ZIP 在 references/ui-jsr-2026-11-09。45/45 素材檢查，Godot 原生棋盤合成已檢視，strict 靜態稽核 0 errors（不代表 native A11Y）。首張預覽畫布裁切已修正，首稿保留。

**沒有替換 runtime UI／色票／字體／操作，也沒更新 Web**。下一輪若繼續 UI，沿此方向接回既有 ui_theme／fight_hud／ui_text／fight_session；文字／HP／能量／時間仍原生繪製，50／75 刻度由真資料畫。角色頁 Hero 是插畫提案，實機先保留原模型預覽。能量框隔線僅裝飾，不當作實際門檻。


## 最新：蓄力重砲與分招式鏡頭（2026-11-09）

完成 [CHARGED_CANNON.md](CHARGED_CANNON.md)：正式／自由練習 W＋L／↑＋L 支付 75 能量，30 tick 起手、38 基礎傷害、3.8m 真實判定、一次命中；不是可變持鍵蓄力，L 原本 50 消耗保持。起手受傷但抗拳腳中斷、投技可打斷，連段減傷與受擊能量回報保持，手動重砲不被按住 J 吞掉。新增後拉／雙掌姿勢、1.45 秒紫紅蓄力、真命中後光束；依施放者高度對接手部與接觸點。重砲低視點／38°、暴扣向下、反制反向繞鏡，挑空另有收身／上勾。

無限 AI 依自己完成地空五連記住機會，合適能量／距離才用重砲，600 tick 每方間隔；維持真實自由交戰、資源規則與普通 L。原模型／音樂／縮高及四角色配搭保持，只推來源，Web 不更新。完整可變蓄力／角色專屬技能仍未做。


本輪 504 項無視窗／144 項原生不同檢查通過（多次有出處的回歸集合，648 不重複計數）；最終優先級／光束覆核 99/99。120.009 秒最終原生交戰 173 命中、27 追擊、11 重砲命中、23 BREAK、無重置。30 秒無剪接 Demo／4 秒真輸入重砲片段及驗證見 charged-cannon 證據。

## 最新：節奏第二版與角色 4 身高（2026-11-09）

已完成 [COMBAT_RHYTHM.md](COMBAT_RHYTHM.md)。角色 4 縮放 2.1→1.4（高度減 1/3），原檔／共用判定保持，特效錨點／陰影／殘影粗細配合。combat_rhythm.gd 在正式／自由練習／Demo 依真事件調度共同 60Hz 步進：全停、0.22x 慢鏡、1.65～2x 釋放；有優先級／低階冷卻、最多兩步及停頓輸入保留。F2 回 1x；暫停／重開／退出清理，音樂不變速。技能紅幕 1.0、命中 .65、BREAK 1.1、KO 1.2／結果 1.4 秒，覆蓋舊時長。新增三種紅幕色階、全屏收束／遮幅／速度線、約 11° 甩鏡與環繞／FOV 對比，清理慢鏡殘影重疊。

494/494 無視窗、135/135 原生及最後視覺覆核 73/73 通過（共 629 個不同檢查）；120.007 秒原生運行 177 命中／28 追擊／24 BREAK，零重置，最多 15 效果／541 節點、孤立節點取樣 0。30 秒連續片段／1.6 秒長 KO 已保存。

只推來源分支，Web 不更新，使用者電腦需 Desktop Pull。角色專屬技能／名字仍未做，真人節奏／舒適度與目標硬體需後續評價。


## 最新：三個新角色已接入（2026-11-09）

使用者提供 1.glb／3.glb／4.glb，原樣保存為 assets/characters/CHAR_FIGHTER_1／3／4.glb，來源 ID／SHA-256 見 references/characters/uploads-2026-11-09.json。各 1,502／1,535／1,548 tris、65 骨骼、1024² 貼圖，無內嵌動畫；沿用現有重定向、程序空戰、toon／描邊及巨拳腳。主選單角色配搭可選兩方、即時預覽及保存，預設原角色對角色 1；正式／練習／Demo 共用，探索仍原角色。四位共用規則，未做角色專屬技能或正式命名。詳見 [CHARACTER_ROSTER.md](CHARACTER_ROSTER.md)。Game Asset Production CLI 缺少，未做其封裝流程；用既有 Python／Godot 接入，無生成／付費。

原生回歸 107/107，最終加反覆換角清理後新檢查 30/30；無視窗 104/104，共 212 個不同檢查。已看預覽／KO，三位都實際空連贏回合，雙語三尺寸與 Demo 保留配搭。軟體 GL／自動輸入，不是人手或目標電腦驗收。原始 43 件模型／圖片／音訊保留，僅字體子集更新；只推來源，不更新 Web。


## 最新：Rush 主玩法、無限 AI 與紅幕 KO（2026-11-09）

正式對戰／自由練習已整合空戰：**按住 J** 真實地空連段＋自動追擊，**K** 挑空／暴扣，**L** 開局可用爆發。**F12** 改成沒有章節／KO 重開的雙 AI 自由交戰，R 重開、Esc 暫停。新增技能紅幕、實際重擊 BREAK 及近鏡環繞紅幕 KO；F2 可停用。見 [RUSH_REWORK.md](RUSH_REWORK.md)／[參考影片觀察](COMBAT_VISUAL_STUDY.md)。這覆蓋以下舊「正式不改／23 章 Demo／N 下一段」說明，F8/F10/F11 專用教室仍保留。

494/494 無視窗、221/221 原生流程通過，最後視覺修訂再查 45/45；補時間到／平手不冒充紅幕 KO 後再查 46/46（新增一項，其餘不重複加總，共 716）。紅幕版 120.14 秒真實時鐘運行：169 命中、27 追擊、23 BREAK、零重置，最多 13 效果／540 節點，孤立節點取樣 0。Godot 4.6.3／Compatibility／軟體 GL／Dummy 音訊，不是人手試玩或目標 GPU／實聽驗收。43 件既有模型／圖片／音訊保留，wev 繼續使用。只推來源分支 `codex/street-combat`，公開 Web 不更新；使用者電腦尚需 Desktop Pull。


## 最新接續：格擋／反擊更易成功（2026-11-09）

依使用者要求完成 FRIENDLY_DEFENSE.md：地面／空中精準窗口 12 tick，地面短按防禦保留及 14 tick 攻擊緩衝；成功後 +18 能量上限、對手硬直 30／冷卻 60、36 tick J 反擊提示，按住 Shift 亦可反擊，短按後跳躍不被吞。空中選擇 30／反踢起手 14；F10 窗口 12/10/9/8、最後八 tick 壓縮期早按緩衝；三選 36 tick。真實命中才顯示「反擊成功」，普通擋格亦有回饋，不加假傷害；投技／空揮／資源與有限退出保持。489/489 無視窗、187/187 原生回歸通過；補跳躍取消後再驗證完整規則與原生 13 項，保留首跑準備／舊時機錯誤。驗證見 VALIDATION.md，四張原生成功圖，不當作真人平衡或實聽。只推來源，不更新 Web，未操作使用者電腦。

## 最新接續：雙 AI 技巧 Demo（2026-11-09）

已新增 AI_DEMO.md：主選單 F12／按鈕，23 段自動展示全部已實作技巧、自由交戰與真實 KO 後循環；下一輪交換左右角色。N 下一段、R 重播、Esc 暫停、F12 結束，保留 F2／wev 音樂與原練習 F9。是明示預設情境的決策器，不聲稱競技 AI 自然學會所有技巧；切段初始站位／資源後全部由正常命中／防禦計算，不注入假事件。Demo 隔離玩家按鍵、原生傳輸控制與陪練偏好恢復；正式玩法不改。384 項無視窗／138 項原生回歸通過；120.005 秒真實時鐘跑完一次循環、43 次命中及 1 次 KO，最多 9 效果、孤立節點樣本 0。初次 KO 終止等待失敗及證據見 VALIDATION.md，不當作真人或目標 GPU 驗收。只推來源，Web 不動，未操作使用者電腦。

## 最新接續：wev 音樂已下載及接入（2026-11-09）

使用者要求自行下載。已用官方 Bandcamp 免費下載／官方過期連結重試取得 family ties (wev edit) MP3 320 全曲，衍生 4.05 MB OGG 接入選單／練習／戰鬥／結果。非 SoundCloud 串流抽取，未購買付費 OST。原始 MP3 未提交，衍生保留來源／權利說明及 SHA-256；WEV_MUSIC_PLAN.md／admitted.json 為最新。獨立音量、暫停、duck、單一持續播放頭及缺檔 fallback 保留，設定有曲名署名；保留原打擊聲。修正退出時 OGG 音效播放實例釋放。驗證見 VALIDATION.md，真人實聽仍待。只更新來源，不部署 Web、未操作使用者電腦。以下「待音檔」已是歷史。

## 最新接續：wev 已可用，待提供音檔（2026-11-09）

使用者表示「wev 音樂已可用」，已更新 WEV_MUSIC_PLAN.md，按可用狀態推進，不再重問是否取得使用授權。目前工作區未找到 wev 音檔，本訊息未附素材／下載連結；需取得實際音檔後才可選曲、循環及混音。未換遊戲音樂、未抽串流或部署 Web；保留 CC0 fallback 與私人音訊素材／公開程式分離。以下為前輪歷史。

## 最新接續：空中反制與教室（2026-11-09，香港時間）

已完成 [AIR_REVERSAL.md](AIR_REVERSAL.md)：F11 → F8 → K 開始，Shift 六幀終結反制花 25 能量、每次離地一次；成功 18 tick 定格後 J 反踢／E 抽身。反踢十幀起手可閃避，不瞬移、不無限互鎖；原創踩踏／後仰姿態及雙語可點按提示。普通空戰中／高陪練可依公開起手反制。正式三選及公開 Web 保持；wev 未錄用，無需 Tripo。後續優先真人窗口／回報平衡，再決定正式整合。427/427 無視窗、143/143 原生檢查通過；120.134 秒連續操作有 77 次反制／24 次反踢命中、效果最多 7，孤立節點樣本 0。證據與首跑重播工具失敗見 VALIDATION.md，不代表真人平衡或目標 GPU。本機需使用者 Desktop Pull，沒有操作使用者電腦。

## 最新接續：空中街鬥可試玩（2026-11-09，香港時間）

使用者「繼續」後，落地 [AERIAL_STREET.md](AERIAL_STREET.md)：F11 空中訓練、三幀起跳預備／分段重力／有限滯空／急降、十幀 E 追擊花 20 能量、三拍空連、↓＋K 暴扣與一次地面反彈。純 simulation 決定位置／時間，程序姿態與短旋身不改碰撞。主選單 F10／F11 並排，F5 回自由練習；正式跳躍／壓力三選保持。

新增 STEP 位移／旋轉取樣、快按 W＋K／↓＋K 修飾鍵快照、空中包圍盒鏡頭、連段提示避讓及合成追擊音。現有 GLB／天空／音樂保留，wev 未錄用、無需 Tripo。新姿態是程序疊加，不是假稱新增十段下載動作。空中格擋逆轉、完整空中換手、全身蒙皮硬邊殘影／巨拳與專用 AI 等待下一輪。

本輪 370 項無視窗及 110 項原生檢查通過；原生短觀察 120.019 秒、25 次追擊及 100 次真實命中，無孤立節點樣本；不代表真人手感、實聽或目標 GPU。初次原生 17/30、中間 27/30 失敗紀錄保留，已修快按方向遺失和腳底貼近提示板。基線、14 張圖及 105 幀動畫見 evidence/aerial-street。只推送開發分支，公開 Web 不動，未操作使用者電腦。

## 最新接續：空中動作及 wev 音訊研究（2026-11-09，僅文件）

使用者提供第三份 R&D 文字，之後再次強調報告五至八的起跳／空連／誇張動作；已完整閱讀並保存 18,127 bytes 原檔、SHA-256，見 references/rd-aerial-2026-11-09。下一輪詳細規格見 [AERIAL_ACTION_AUDIO_PLAN.zh-TW.md](AERIAL_ACTION_AUDIO_PLAN.zh-TW.md)，推薦先做 A0＋A1＋第一批四個關鍵姿勢，再追擊／空連／反制；正式仍保留壓力三選。參考幀數與原遊戲實作未獨立核實；獨立 60Hz 試算只證明跳高／體積算術，不代表實作驗證。

使用者指定 worldwidewev、允許換音樂及音效；詢問後已明確回答「尚未取得，先完成選曲及接入規劃」。已讀 7 個公開頁面，記錄《OST》15 首及 2 首 SoundCloud 權利欄位，見 references/audio-sources/worldwidewev/catalog.json。已查頁面標示 All Rights Reserved，沒有下載音樂／抽串流／購買／聯絡藝術家，也未實聽或量測 BPM。見 [WEV_MUSIC_PLAN.md](WEV_MUSIC_PLAN.md)：候選曲、授權範圍、合法音檔到位後的接入、音訊分層與驗收；目前保留 CC0 音訊，不阻塞空中原型。

此輪未改執行程式／遊戲音檔，未重跑遊戲測試；只做文件、來源及參數算術驗證。只推送開發分支供 Desktop 拉取；Web 不更新，未操作使用者電腦。以下為前輪已實作成果。

## 最新接續：動能換手及漫畫爆發已實作（2026-11-09）

使用者授權開始優化並允許誇張視覺。本輪落地 [KINETIC_OVERDRIVE.md](KINETIC_OVERDRIVE.md)：F10 專用練習、四級快反／再格擋、五次格擋散能及 300 tick 上限；正式仍是壓力三選。K 持放、連鎖投技、選角／VS 未做，不能宣稱已完成整份路線。

正式對戰同步加強三層衝擊弧、骨架殘影、透視地面環、短暫世界三色階（HUD 不染色）、方向鏡頭反衝、合成換手音、能量技切入及 0.82 秒可跳 KO。新增所有展示遵循 F2；主選單、操作提示及字體雙語同步。原模型／天空／留白招牌保留，不需要 Tripo。

最終 316 項無視窗及 79 項原生 viewport 回歸通過，最後主選單留白另有 35 項檢查；固定步進畫面與序列保存在 evidence/kinetic-overdrive。原生自動輸入觀察見該輪報告，不代表真人手感、實聽或目標 GPU 驗收。只推送開發分支，Web 不動、未操作使用者電腦。以下保留前輪規劃與實作歷史。

## 最新接續：爽感規劃與來源保存（2026-11-09）

本輪使用者要求吸收兩份貼上文字並詳細規劃，沒有實作新機制。完整規格見 [GAME_FEEL_ROADMAP.zh-TW.md](GAME_FEEL_ROADMAP.zh-TW.md)，原始來源、大小及雜湊見 [references/feel-2026-11-09](../references/feel-2026-11-09/README.md)。已完整閱讀文字；未獨立觀看 YouTube 原片或量測時間碼／FOV／速度門檻，不可將筆記當官方實作證據。

推薦下一輪先做 P0／P1a：練習內互斥的有限格擋換手原型，先只有快反與簡單效果。既有三階壓力／三選對峙仍是正式基線，未決定替換。新模式的持放蓄力、AI 再格擋、選角、VS、KO 鏡頭皆是後續計劃；沒有球、不直接套範例 Autoload。本輪無需 Tripo 或新增美術資產。只推送開發分支文件，未更新公開 Web，未存取使用者電腦。

以下為上一輪已實作成果；不要把其測試數量當成新規劃已驗證。

## 最新接續：原生 UI 與近身交鋒（2026-11-09，香港時間）

目前主場景是 `godot/scenes/combat/street_fight.tscn`，最新規格見 [EXTENDED_POLISH.md](EXTENDED_POLISH.md)、根目錄 DESIGN.md／UX-CONTRACT.md。以下早期段落保留歷史，不能以早期「街景主場景／尚無無限練習」描述覆蓋目前狀態。

藍樓大直牌已移除，窗列補回，`BlueCornerShopSign` 留待使用者貼圖。已加入繁中／英文原生 UI、可點按對峙、G 投技／拆投、E 場邊受身、AI 預選假動作、近身追鏡與靜態批次繪圖。F6 遊走也換成共用 UI 與音量偏好；`a238e3e` 補修結算反白和逐回合演出時鐘。

累計互動工作已超過三小時，等待續接的空檔不計。374 項整合、104 項原生介面／輸入、7 項實際視窗失焦、結算 15 項及針對性重測通過；512 次介面循環穩定。20 分鐘原生輸入走過 31 回合／13 場。環境重連中斷舊長測，已明確分開記錄；恢復後另完成 30 分鐘、21 次回合重開，詳見 extended-polish/stability.json。只推送 `codex/street-combat`；不可更新公開 Web，亦未操作使用者電腦。

以下為 2026-11-06（Asia/Taipei）的首輪交接及其後歷史。最新範圍以上方接續段落為準；各輪只根據本聊天與實際檔案，不假設其他對話內容。

## 同步前讀取範圍

- 原工作區 repo：`/workspace/Game-Lab-3`，本地分支 `work`，乾淨，HEAD 為 `cbf117aa36b0237bcf1c1c083ae33cd148c5d0c4`。
- GitHub 遠端當時只有 `main`，同一初始提交，只有 README.md；未發現 AGENTS.md、設計／待辦／交接文件或開啟中的 PR。
- 本次已讀當時 README，查詢遠端分支／檔案／PR，再 fetch 建立獨立任務分支 `codex/flight-street-handoff`。本次新增 AGENTS.md 以記錄使用者要求的協作規範。
- 這是讀取時的快照，不表示未來 main 或其他任務分支沒有新增成果；接續前必須重新確認。

## 現有成果

`godot/` 已包含六件資產展示及 S1 街道白盒。主場景為 S2 `scenes/street_walk.tscn`，已可操作測試角色；1–5／Tab 為固定視角、0 返回角色。原 S1 `street_whitebox.tscn` 與資產展示 `review.tscn` 保留。所有 GLB 原始資料未改動；尺寸與簡化碰撞在各包裝 .tscn。`assets-manifest.json` 記錄來源雜湊與狀態；`references/assets/` 包含七種資產的參考圖；`docs/evidence/` 有原型預覽與載入紀錄。

已確認的偏好與取捨見 [DECISIONS.md](DECISIONS.md)。設計基準見 [DESIGN.md](DESIGN.md)。完整原聊天計劃保留於 [archive/chat-plan.zh-TW.md](archive/chat-plan.zh-TW.md)，其中歷史工作區附件路徑不可當成 repo 檔案。

## 從哪裡接續

1. 讀取 AGENTS.md、README.md、本文件、TODO、DESIGN、DECISIONS 和 VALIDATION，確認最新分支與修改。
2. 重跑 Godot 匯入與 `verify.gd`，確認當前環境能使用六件資產。
3. 讀取 [WHITEBOX.md](WHITEBOX.md)，查看 S1 的四個固定視角與俯視布局；白盒已實作，等待使用者構圖回饋。
4. 保留 `godot/scenes/review.tscn` 作資產對照；新街道另建場景。
5. S2 控制器與 28 項無視窗檢查已完成，詳見 WALK.md。S3 入口風格樣片已完成原始／兩段／三段材質比較及軟體渲染檢查，詳見 STYLE_SAMPLE.md；S4 飛機事件原型已實作，見 FLYBY.md；下一步是人工看圖、試玩與聆聽，並按回饋精修。先不要求使用者追加付費道具生成。

## 驗證與缺口

來源 GLB 雜湊、Blender CPU 預覽和 Godot 無視窗載入有證據；GPU 畫面、實際遊玩與效能尚未驗證。詳細範圍見 [VALIDATION.md](VALIDATION.md)。

原參考照片、三段影片及部分額外三視圖未加入 repo。需要時請明確說明缺少哪些素材，不能聲稱已觀看不存在的來源。轎車只有參考圖，尚未收到模型。

## 同步原則

本次僅提交與推送任務分支，供審查及跨對話接續；不自動合併 main 或發佈。若其他分支後續新增成果，先讀取並保留，再整合本任務所需部分。

## 此次 repo 重新驗證

六件原始 GLB 與來源 SHA-256 一致；Godot 4.6.3 在本 repo 重新匯入和載入成功。模型、場景、參考圖及非歷史文件的本地連結均核對存在。證據見 VALIDATION.md 的「任務分支重新驗證」。

## 遠端接續位置

- 任務分支：[codex/flight-street-handoff](https://github.com/yauchai2/Game-Lab-3/tree/codex/flight-street-handoff)
- 草稿 PR：[#1](https://github.com/yauchai2/Game-Lab-3/pull/1)
- 首次完整同步提交：`532670dadee274a643d8faea88b1484714354ae8`。本節連結為後續補充紀錄；以遠端分支最新提交為準。

目前未合併 main、未發佈。若後續要接續本成果，先讀任務分支或 PR 的最新內容，不要只讀尚未合併的 main。

## S1 街道白盒更新

已讀取任務分支最新規範並保留六件來源資產及原展示。新增參數配置、生成器、街道場景、四個固定相機與俯視相機、1–5／Tab 切換，以及 Godot 結構／相機／物理射線檢查。飛機位置與朝向經入口預覽調整，屬美術構圖參數，非航空實測。

現有環境沒有 Xvfb 顯示服務，未取得 Godot GPU 畫面；改用 Godot 匯出的同一份幾何在 Blender Cycles CPU 產生五張預覽。操作與重現步驟見 WHITEBOX.md。尚未完成玩家控制器、事件聲音、最終 toon 或硬體效能。

五張 CPU 預覽已完成並檢查，側巷缺少地面基底的問題已修正；入口保留道路與現有道具前景。新白盒檢查涵蓋 1–5 鍵、Tab 循環、八個地面射線取樣與配置指紋，結果見 docs/evidence/whitebox/。下一步等待構圖回饋並實作 S2，勿將 S1 固定相機當成行走控制器。

## S2 遊走更新

新增獨立遊走組裝場景與比例替身控制器，保留 S1 幾何、固定相機及六件來源 GLB。已實作第三人稱預設、V 切第一人稱、走／加速／跳、滑鼠視角、SpringArm 碰撞縮短、0／1–5／Tab 相機切換、R 重設及掉落回復。游標釋放或失焦時暫停移動輸入，點擊恢復。

Godot 4.6.3 在 headless 模式以實際物理幀測試 28 項情境通過，包括超過 50 m 的主街移動、人行道跳躍、側巷與主要障礙碰撞。游標鎖定僅驗證應用程式要求，無視窗環境不能驗證真實桌面游標。未新增 S2 畫面或人工試玩證據，操作與範圍見 WALK.md。

## S3 風格樣片更新

入口左右約 14–16 m 立面、主招牌及消防栓／廂型車已加入可逆材質樣片；B 鍵比較原始材質、兩段與三段明暗。樣片裝飾包含欄杆、球燈、遮雨棚與冷氣，來源 GLB 未改動，原 S1 場景保留。細節與圖片見 [STYLE_SAMPLE.md](STYLE_SAMPLE.md)。

Godot Compatibility 使用 Xorg dummy + Mesa llvmpipe 軟體 OpenGL 實際擷取，12 項樣片結構檢查、28 項遊走回歸及來源雜湊均通過；投影開關與兩／三段畫面差異有記錄。這不是硬體 GPU 效能測試，也未代替人工風格／遊玩驗收。招牌使用系統字型後備，跨平台需確認。

## 新增風格參考與下一步

使用者於本聊天提供兩張自行生成的街景風格參考，並詢問下一步。兩圖分別偏立體低面數暖日光與高對比漫畫式陰影；共同強調低空客機、黃框直立招牌與窄街冷暖對比。詳細觀察及建議順序見 [風格參考紀錄](design/style-references-2026-11-06.zh-TW.md)。

建議先依新參考微調 S3 的局部風格，再推進 S4 客機機腹／輪組與可重設掠過事件。這是工作建議，使用者尚未確認最終混合比例或完成風格驗收；當時新調整與 S4 尚未實作；後續實作見下方。當時僅新增規劃紀錄；後續實作見下方 S4 更新。

新參考原圖僅在聊天內可見；本次環境沒有可保存的圖檔識別，原圖未同步至 repo，後續對話不得假稱已讀取 repo 中的原圖。

## S4 飛機事件與參考圖調整（最新）

延續前次建議，調整天空／暖光、窗框與街道招牌，並在遊走場景加入自動觸發 9 秒飛機航路、P 重播、程序補充的輪組／襟翼及可替換的原創合成測試音。S1 獨立場景、六件原始 GLB 未改動；玩法優先級、風格定案均未決。事件詳細規格、入口三個凍結畫面、控制與限制見 [FLYBY.md](FLYBY.md)。

Godot 4.6.3 headless 11 項事件檢查、28 項遊走、12 項風格回歸與六件資產載入／雜湊通過。Godot Compatibility 在 Xorg dummy／llvmpipe 輸出截圖，非硬體效能或動態人工遊玩。Dummy 音訊僅測狀態，未實際收聽；測試退出有 ObjectDB 清理警告待追查。下一步請使用者實際打開專案確認構圖、操作、飛機時機與聲音，再按回饋精修飛機／招牌並評估 S5；不用先新增付費 Tripo 資產。

## GitHub Desktop 協作與天空參考（最新）

使用者提議以 GitHub Desktop 取得更新、在 Godot 本機查看。建議採用；完整首次 clone、切換任務分支、後續 Fetch／Pull、保留本地修改及試玩回饋見 [GITHUB_DESKTOP.zh-TW.md](GITHUB_DESKTOP.zh-TW.md)。不假設使用者已完成同步，現有草稿 PR 未合併。

使用者在本聊天提供一張藍天與分層白／淺藍積雲圖片，詢問是否需要；可作雲形、色彩及圖形化分層的方向參考。聊天內可見圖片，但目前沒有可存取的原圖檔案識別或已保存副本，未納入 repo 或實際遊戲；是否直接採用圖像及最終天空表現尚未決定。單張橫幅不自動等同可無縫環繞的 360° 天空，實作前需處理接縫／極區，或改用程序天空與雲層。現階段不要求額外付費生成。

本次僅新增操作與交接文件，未更改 Godot 程式或實作天空；首次建議由使用者本機查看 S4，回報飛機構圖與時間、天空色調及暫用音量。

## 程序天空樣片（最新）

在遊走場景加入深藍天空和靜態白／淺藍分層雲；按 C 與原青藍純色背景比較，B 材質和 P 飛機操作保留。以程式依聊天中圖片的可見風格詮釋，並未匯入原圖；S1 白盒未變。實作、四張 Godot 軟體渲染截圖和局限見 [SKY_SAMPLE.zh-TW.md](SKY_SAMPLE.zh-TW.md)。

Godot 4.6.3 headless 的 7 項天空邏輯、12 項風格、28 項遊走及 11 項飛機事件回歸通過。雲是靜態簡化圖形，完整 360° 接縫、使用者電腦的 GPU、實際畫面和音效仍待人工驗證；現有飛機回歸的 ObjectDB 退出警告未解決。下一步請使用者透過 GitHub Desktop 同步任務分支並比較天空及飛機，再依回饋調整。

## 天空環視與雲形調整（最新）

入口上方加入兩朵不同尺寸／比例的小雲，後方一朵跨越角度接縫；使用者仍可按 C 比較原純色背景。新畫面與特定角度、指定像素區域的接縫測試見 [天空文件](SKY_SAMPLE.zh-TW.md)。Godot Compatibility／llvmpipe 擷取八方向，以及 0°／360°、±180° 與 ±179.75°；匹配與對齊差異檢查通過，並非所有俯仰／硬體均已驗證。天空邏輯 7 項回歸通過。原 S3／S4 截圖保留為歷史，音效與飛機回歸退出警告仍需後續處理。

接續仍應請使用者透過 GitHub Desktop 的任務分支查看，確認天空、飛機時機與聲音，並依回饋調整；這次沒有發佈、合併或使用 Tripo。

## Tripo 轎車候選準備（最新）

使用者詢問還可用 Tripo 生成甚麼；建議先選原有參考但未收到 GLB 的靜態港式轎車，作為廂型車之外的第二款車輛。AI 根據 repo 既有三視圖拼版生成獨立的左前斜角單車圖 [VEH_CAR_A01_ref_v002_3quarter.png](../references/assets/VEH_CAR_A01_ref_v002_3quarter.png)，用於單圖測試；原拼版保留。生成、匯出規格與回傳後檢查詳見 [TRIPO_CAR.zh-TW.md](TRIPO_CAR.zh-TW.md)。

建議沿用 P1.0、先生成 1 個候選、三角面 1,500 作起點、GLB 1K；車輛靜態無需拆分。這些是建議非使用者已執行的操作，具體可選設定與費用須以其網頁為準。目前尚未收到轎車模型，未匯入／未驗證，既有六件與遊戲程式未改；天空、建築等仍可由 AI 製作。

## 轎車整合與下一個 Tripo 候選（最新）

收到使用者轎車原始 GLB，SHA-256、面數 1,524、1024×1024 貼圖與尺度見 [資產清單](../assets-manifest.json) 及 [完整性證據](evidence/car/integrity.json)。檔案直接複製，未修改來源；在 `street_walk.tscn` 以 `VEH_CAR_A01.tscn` 包裝為長 4.2 m 靜態碰撞物，放在街道左側，原 `street_whitebox.tscn` 與六件展示場景不變。轎車包含在 B 材質比較中。使用者未提供此檔實際 P1/P2 設定，不能從檔案推定。

Godot Compatibility／llvmpipe 的[街道正面](evidence/car/01_front_street.png)與[背面](evidence/car/02_back_street.png)顯示車輛輪廓可辨；車身在陰影下較暗，等待人工評估。headless 6 項轎車／碰撞檢查、28 項遊走、12 項樣片、11 項飛機回歸及 7 件載入檢查通過；退出仍有既存 ObjectDB 音訊清理警告。未進行硬體 GPU／人工試玩或聲音驗收。遊戲資產製作 skill 建議的 `game-dev` CLI 此環境不可用，本次使用現有 Godot 與靜態檢查流程，未執行 CLI 正規化或建立 canonical package。

依使用者詢問，建議可選下一個 Tripo 候選為箱式貨車，單車參考圖及設定見 [TRIPO_TRUCK.zh-TW.md](TRIPO_TRUCK.zh-TW.md)；尚未收到貨車 GLB，費用及生成由使用者控制。

## 使用者貨車與生成圖片天空（最新）

收到 `tripo_convert_8e7c67cc-8882-42c4-9474-56e4cb8c677c.glb`，原始 SHA-256 `b15a7535ab7f2f173472ffe002ead8e246883ff9255cc11efb6769cc09b83228`，1,510 三角面、1K 貼圖，生成版本未由使用者明示。原始檔未改，新增 5.5 m 盒碰撞包裝並放在主遊走場景右側 `Vector3(2.6,0,-36)`，包括在 B 材質樣片；原 S1 白盒不變。Godot llvmpipe [前](evidence/truck-sky/03_truck_front.png)／[後](evidence/truck-sky/04_truck_back.png)顯示駕駛室及箱體可辨，背面為平面、無明顯門件，待人工評估。

依使用者提供遊戲畫面，生成原創 1774×887 圖片 `godot/assets/SKY_BLUE_A01.png`，N 切換該圖片／程序天空，C 仍控制純色／程序。截圖及原圖邊界／指定視角檢查見 [天空文件](SKY_SAMPLE.zh-TW.md)，原參考截圖僅在聊天中，並非 repo 素材；圖片全景尚待人工、其他角度及目標硬體驗收。

Godot headless 11 項貨車／天空切換測試、28 項遊走、12 項風格、7 項天空、11 項飛機、6 項轎車及八件資產載入回歸通過；部分測試退出仍有既存 ObjectDB 音訊清理警告。未進行人工試玩、實際音效或硬體 GPU／效能測試。

## 港式街景優化、飛機與描邊（最新）

依使用者要求持續製作，新增程序街景 `godot/scripts/street_dressing.gd`：店面、原創招牌、窗框、冷氣、街燈與碰撞、天線電線、斑馬線、路面細節及遠景。貨車原 GLB 不動，包裝場景增加後門。遊走飛機位置改至 `(-6,41,-52)`、yaw −150°、12 秒航路，加入綠色機頭與機身色帶；S1 白盒原設定不變。O 開關可選描邊，預設關閉；B、C、N、P 等原功能保留。

Godot 4.6.3 headless 13 項新場景檢查、28 遊走、12 風格、7 天空、11 飛機、6 轎車、11 貨車及 S1／八件載入／雜湊回歸均通過。Godot Compatibility／llvmpipe 擷取 16:9 前後對比、輪廓對照與 12.1 秒無聲連續飛越影片。指定 800×450 鏡頭的渲染繪製呼叫從 1,871 降至 1,131，兩次含少量細節差異，非 FPS 數據。方法與[證據](STREET_POLISH.zh-TW.md)；音效未實聽、目標 GPU 未測、ObjectDB 退出清理警告未解決。最終風格及人工操作仍需使用者回饋。

乾淨副本驗證：從提交 `9eff39c` 的 Git archive 在另一目錄重新匯入並 headless 啟動成功，未見腳本或 shader 錯誤；退出的 ObjectDB 音訊清理警告仍存在。詳見 STREET_POLISH.zh-TW.md。

## 角色、圖片天空與低清街景（2026-11-06，最新）

使用者明確選圖片天空、提供 `character-1.glb` 和 Hinata 參考影片。圖片天空現在為預設，N 可比較程序天空。角色原始 GLB 不改，含 65 骨骼、1,664 三角面、0 動畫；包裝縮放 1.75，使用速度驅動暫用步態。原始骨架與材質、影片識別及取樣範圍、貼圖與局限見 [CHARACTER_TEXTURES.zh-TW.md](CHARACTER_TEXTURES.zh-TW.md)。

環境新增 128×128 程序路面／行人道／牆面貼圖、生成塗鴉、招牌支架及飛機自陰影斑點修正；保留獨立 S1。headless 九組場景檢查均通過，角色與街景截圖由 llvmpipe 擷取。這不是人工試玩或目標 GPU 驗收；正式角色動畫、聲音、性能仍待處理。使用者可在 GitHub Desktop 同步 `codex/flight-street-handoff`，以 Godot 開主場景。

## JSR／BRC 製作規範（2026-11-06，最新）

收到使用者 `jsr_brc_3d.md`，原檔保存於 `references/guidelines/`（SHA-256 `7547594616f67916d3d35c6c1211bf46f8731ba337c1c2a48793b0c0c287b0de`）；另將其他對話提交於 `origin/main` 的 `docs/JSR-BRC-style-reference.md`（提交 `54a520d`）原樣複製至本分支，未合併整個 main。規範作製作目標，非已獨立驗證的原遊戲技術事實。

現有角色 1,664 tris，入口牆與道路 32 texels/m；卡通牆面 Shader 原本線性過濾與標準材質不一致，現改用 nearest+mipmaps，角色／道具 UV 取樣不變。具體對照、保留 mipmaps 的取捨、未實作清單與圖像檢查見 [專案對照](JSR-BRC-project-application.zh-TW.md)。

## 環境貼圖 mipmap 匯入修正（2026-11-07，最新）

前次材質選 nearest+mipmaps，但三張貼圖匯入實為 `mipmaps/generate=false`；已將道路、行人道和牆面的 `.import` 設為 true，不改原圖。Godot 實測每張 128×128 的 mipmap 數量為 7 層（不含原圖），材質切換回歸通過。未進行移動畫面與硬體 GPU 驗收，舊比較截圖為修正前。詳見 [專案對照](JSR-BRC-project-application.zh-TW.md)。

## 飛機音效退出警告調查（2026-11-07）

Godot 4.6.3 headless verbose 飛機測試 11 項通過，但退出仍提示 `AudioStreamWAV` 和 `AudioStreamPlaybackWAV` 未釋放；臨時測試停止後把 `sound.stream` 設為 null，警告仍存在，該實驗沒有保留於程式。原始及實驗紀錄位於 `docs/evidence/audio-diagnostics/`。這只定位測試退出時的現象，尚未證實原因或修復，未聆聽音效。

## 陽台花槽與外伸架（2026-11-07）

依原照片右側橙色立面，遊走場景增添三層低面數花槽、綠色植物與數個外伸金屬架；全部使用既有 MultiMesh 批次、位於高處且不加碰撞，獨立 S1 及原 GLB 不改。[入口畫面](evidence/balconies/01_entry.png)、[側面畫面](evidence/balconies/02_sidewalk.png)為 Godot Compatibility／llvmpipe 軟體渲染；場景結構與遊走測試通過，硬體 GPU、人工操作與最後美術仍待驗證。

## 中段街道店面層次（2026-11-07）

依使用者希望增加場景複雜度，在遊走場景加入四處淺遮篷、兩處捲閘及外牆管線，使用現有 MultiMesh 材質分組、不新增碰撞。S1 與原 GLB 保留。Godot Compatibility／llvmpipe 截圖與 headless 街景、遊走回歸見 [streetfront](evidence/streetfront/)；未作目標 GPU 或人工驗收。下一步仍是逐段提升立面差異、遠近景深及角色描邊，同時維持可走性與效能。

## 舊樓陽台與天線（2026-11-07）

在遊走場景五個舊樓位置加入三層外伸陽台、欄杆及簡化晾曬色塊，四處加天線；均使用現有批次及高處非碰撞裝飾。原始 GLB 和 S1 保留。Godot llvmpipe 仰視圖見 [住宅立面](evidence/residential/03_left_facade.png)，街景與遊走測試通過。相同 800×450 固定鏡頭軟體渲染，開啟街景細節時的 draw calls 前後均為 1,131，primitives 為 86,297→88,181；不是 FPS 或目標硬體效能測試。

## 角色近身格鬥：第一個可玩里程碑（2026-11-07）

依使用者本聊天指定「類 Lethal League Blaze 但不是擊球，而是打鬥」，從 `codex/flight-street-handoff` 的 `f9cd82d` 建立 `codex/street-combat`，復用現有街景與角色，加入玩家對 AI、固定對手練習、三段輕連擊、重擊、挑空、防禦破防、衝刺、能量技、動態頓幀、輸入緩衝、計分、兩勝賽制、暫停和重賽。主場景改為格鬥主選單，遊戲內 F6 在格鬥／原遊走之間切換。

原始 GLB 不改；近側街牆和道具僅在格鬥組裝場景隱藏以保護戰鬥可見性。外掛 toon、程序姿勢、2D 幾何特效、鏡頭及合成音。這些不是完成的手繪特效、正式角色動畫或最終音效。

34 項 headless 格鬥檢查、11 項 Xorg/llvmpipe 自動輸入與場景往返、28 遊走及 13 街景回歸通過。新格鬥測試無退出 ObjectDB 警告；街景回歸仍有既存音訊清理警告。截圖及自動示範見 `docs/evidence/combat/`，並非真人試玩或硬體效能證據。下一步先真人調校手感與正式動作／特效，再擴充格鬥深度。完整操作、架構與後續順序見 [COMBAT.md](COMBAT.md)。

## 使用者指定的街口仰角背景（2026-11-07）

依本聊天三張圖片改用沿街望入、向上仰視的構圖：雙側冷暖街牆、直立招牌、深藍天空和斜向四引擎客機。背景在獨立 SubViewport world 渲染，前景正交角色與原格鬥判定保留；相機追隨不改背景仰角，暫停會凍結飛機。頂部 HUD 收窄、臨時大牌和凸起舞台正面移除。原街景與 GLB 無改動。

已讀取使用者 Drive 影片並抽查六張等距畫面，未完整觀看或量測原遊戲幀數。14 項新背景檢查、34 格鬥與 11 自動輸入回歸通過，1280×720／960×540 的 Godot llvmpipe 畫面與自動示範見 `docs/evidence/street-angle/`。下一步是使用者確認構圖，再精修建築／客機與正式角色動作；目標 GPU 和真人手感未驗證。完整來源及參數見 [背景文件](STREET_COMBAT_BACKGROUND.md)。

## 五點試玩回饋修正（2026-11-07）

修正模型 +Z 朝向與 gameplay facing 的相反轉換，雙方現在面向彼此且能換邊。匯入 Quaternius CC0 Standard 的 14 段拳擊／移動／跳躍／翻滾／受擊／KO／發力動畫，使用休止姿態轉接和肢體校正；重踢與挑空另作方向疊加。來源、授權、雜湊與可重現抽取器均已保存，角色 GLB 無改動。

依使用者澄清，移除雙 world 合成，角色 Z=3 在現有斑馬線上戰鬥，使用同一個透視世界、陰影和相機；相機依雙方中點與距離平滑追蹤，左右輕微環繞。兩種模式的場景文字／舊字形均隱藏，招牌面板留白。

30 項新回歸、34 格鬥、11 自動鍵盤、28 遊走和 13 街景通過，共 116 項；新畫面與示範見 `docs/evidence/playtest-fixes/`。既存遊走音訊清理警告仍在；真人手感及目標硬體未驗收。詳細來源、轉接方式和剩餘限制見 [PLAYTEST_FIXES.md](PLAYTEST_FIXES.md)。接續優先看真人試玩對接觸節奏、腳步、鏡頭及素材整合的回饋。

## 場景接回、音訊與戰鬥演出（2026-11-07，最新）

已重新核對指定街景對話及來源分支 `f9cd82d`，補回前版漏載的圖片天空、紅車、箱式貨車、原世界 UV 環境貼圖和 style_sample 細節。取消全街 X=2.4 拉伸，只延伸入口斑馬線漆。飛機沿本地 -Z 機鼻飛行並移高避開屋頂。角色黑邊保留，場景額外描邊預設關，O 比較；招牌仍留白。

加入 Juhani Junkala CC0 電子樂、Kenney CC0 14 個音效，以及原創分段幾何 VFX。Shift 前六幀精準防禦及起手反擊已接入；F4 獨立音樂、M 靜音、F2 減少演出。四項使用者截圖警告已修正，三份相關腳本在提高警告為錯誤後通過。

163 項相關檢查及含聲腳本示範已完成，細節、來源和限制見 [本輪文件](SCENE_AUDIO_VFX.md)。來源 GLB／白盒及歷史證據保留。仍需真人調手感、實聽混音與目標硬體驗收；原獨立飛機測試的音訊退出警告按本輪日誌記錄，不宣稱全面排除。

## Web 分享試玩準備（2026-11-07）

已按使用者要求加入 Godot Web preset、分享入口、載入／失敗提示、全螢幕、複製連結及授權頁。桌面鍵盤單人對 AI，保留 F6 原街景。單執行緒 Compatibility，不要求跨來源隔離；動作 JSON 明確打包。Wasm 無損壓縮，總下載約 19 MB，Sites ID 與更新方法見 [WEB_PLAYTEST.md](WEB_PLAYTEST.md)。

Web 匯出、匯出包 8 項 Native 資源／玩法／F6 往返，以及 Wasm 編譯、Web Streams 解壓和檔案雜湊通過。Sites preview relay 及 cua_repl.js 不可用，瀏覽器實際遊玩未驗證；發佈結果另補紀錄，不把預期網址當作已上線。

## Web 公開發佈完成（2026-11-07）

試玩網址：https://afterhours-street-fight.beamingladybird1.chatgpt.site 。Sites version 1、部署 `appgdep_6aee954c0f3c8191866e36096a914642` 成功，native get_site 確認 public 及同一 current_live_url。GitHub 遊戲來源 `77c0026`，Site source `3dcb8dc`。分享頁、遊戲及授權共約 19 MB。

實際匯出的 PCK 8/8、WebAssembly／Web Streams／實際 fetch adapter compileStreaming、HTML 語法及本機資產雜湊通過。匿名 HTTP 下載被 Cloudflare 403／1010 阻擋，未驗證線上資產內容；預覽服務仍不可用，沒有宣稱完成瀏覽器遊玩或實聽。更多來源與重現見 WEB_PLAYTEST.md 和 evidence/web/。

## GitHub Pages 已準備，待啟用（2026-11-07，香港時間）

使用者改要 GitHub 遊戲網址。`gh-pages` 分支 `c663ec5` 已推送同一份 Web 遊戲及 `.nojekyll`，期望網址 https://yauchai2.github.io/Game-Lab-3/ 。GitHub repo public、帳戶 admin，但 integration 啟用 Pages 的 API 回傳 403；目前 has_pages=false、網址 404，尚未上線。請擁有人在 Settings/Pages 選 Deploy from a branch → gh-pages → /(root) → Save。主分支及既有 Sites 不刪改。

已驗證 15 件靜態資產雜湊，實際 fetch adapter 在根路徑及 /Game-Lab-3/ 皆可 compileStreaming；不是線上瀏覽器實測。設定完成後接續執行 HTTP 資產及瀏覽器鍵盤／音訊檢查。API 失敗和準備提交見 docs/evidence/github-pages/；完整指引見 WEB_PLAYTEST.md。

## 戰鬥完善（2026-11-08，香港時間）

GitHub Pages 已由擁有人啟用，API built，舊版 HTTP 資產 15/15 及真實 Chromium WebGL／鍵盤測試成功。新增無限練習、站立／防禦／陪練、F5 重置、F7 切換、六筆輸入及上次連段統計；挑空命中 Space → J 追擊、三次浮空後落地；三段 AI、本機設定保存及可捲動選單。新 32 項與相關回歸共 143 項通過，新版 Web 發佈與公開測試另補記。詳見 COMBAT_POLISH.md；原 GLB／場景及歷史不覆寫。

## 戰鬥完善版已上線（2026-11-08，香港時間）

https://yauchai2.github.io/Game-Lab-3/ ：Pages 2908503 / 遊戲來源 e2c7e10，公開 built；15/15 資產雜湊。新邏輯 35 + 格鬥 34 + 場景／音訊 33 + 骨架／透視 30 + 警告 3 + headless viewport 11 + Web PCK 8 = 154 項通過。最新 Chromium WebGL／F5／F7／AudioContext／IndexedDB／全螢幕／重載 7/7 通過，JS 與 console 錯誤空白；軟體 GPU，不是真人／聆聽／硬體效能驗收。

T 進無限練習、F5 重置、F7 切對手；正常對局 Enter。挑空僅在未被防禦的命中後允許 Space 追擊；前三次浮空命中後落地。模式／難度／演出與聲音保存在本機。所有目前狀態與後續限制見 COMBAT_POLISH.md；最新證據在 evidence/combat-polish/。舊音訊退出警告、投技、第二角色、手柄與手機觸控仍待後續。

## 街角加密與日常同步規則（2026-11-08，香港時間，最新）

使用者明確更正：平時只更新 GitHub 原始碼供 Desktop 同步，只有點名時更新公開試玩版。已寫入 AGENTS.md；本輪未更新 gh-pages，仍為 2908503。這裡只有雲端 /workspace 存取，沒有操作使用者電腦或替其 Desktop Pull，不能聲稱本機已同步。

依最新寬幅照片，新 `corner_streetscape.gd` 共用於格鬥與遊走：藍／橙正立面、左右六棟鄰樓、窗籠冷氣／風扇、陽台燈球、店面遮篷／捲閘、路面／人行道、兩輛程序摩托車、兩輛既有轎車及街邊物件。3,001 實例以 10 批次、8 材質呈現；新增三張 128×128 原創低清貼圖。來源模型、白盒、圖片天空及飛行／相機規則保留，招牌無文字。保留 X±8.8、Y0.04–4.3、Z2.4–4.4 的戰鬥淨空。

226 項檢查通過，七視角原生 Godot／llvmpipe 前後對照已檢視。不是使用者電腦／GPU、真人或效能驗收。Desktop 當前應選 codex/street-combat，Pull 後 Godot F5；F6 遊走。見 CORNER_DENSITY.md 與更新的 GITHUB_DESKTOP.zh-TW.md。

## 招牌與動態天空（2026-11-09，香港時間，最新）

使用者授權合理大改和增刪招牌；已保存新版 LLB md 與吸收對照。移除重複遠牌、補橫牌支撐，四個外側空白挑牌預留 artwork_size_m。圖片天空以 0.08°/s 漂移，共用於格鬥／遊走，不改光源；暫停與 F2 停漂移。新 18 加回歸共 157 項通過、七個場景視角及 0/60 秒天空原生擷取。見 SCENE_COMPOSITION.md。這輪不需 Tripo；如後續需模型先給參考圖。只推 codex/street-combat，公開試玩不更新；雲端檢查不等於使用者電腦同步。

## 分段打擊演出（2026-11-09，香港時間，最新）

六招原創硬邊向量畫格；命中核心保持到 hitstop 結束，再放氣浪／碎片，依方向鏡頭回彈與既有聲庫釋放音同步。保留雙向／交換命中、暫停、重置、換回合及 KO 清理；F2 降低形狀密度並停反衝。simulation 位元不變。新 24 + 回歸共 155 項通過，16 原生畫面與重擊固定步進 GIF 見 IMPACT_STAGING.md。修正天空測試使用真正的 _process，18 項重跑通過。只推開發分支，不更新公開 Web；本機 Pull、真人手感和混音仍待驗收。

## 借勢街鬥原型（2026-11-09，香港時間，最新）

使用者已接受新核心，實作 pressure_exchange.gd：命中／擋格／精準防禦累積共用三階壓力，第三階地面重踢與可應對對手接觸開 24 tick 對峙。J PRESS 剋 SLIP、Shift TURN 剋 PRESS、E SLIP 剋 TURN；鎖首個選擇、固定期限、平手／超時處理。PRESS 22 傷害及強擊退、TURN 16 傷害及硬直、SLIP 無傷後撤；結算清壓並冷卻。AI 在開始前決定意圖，不窺讀選擇，有明示站姿／文字。三階表、選擇倒數、原有 VFX 和清理路徑已接上。

主選單 PRESSURE DRILL 或 T→F8；先不限時看相剋提示，按 K 才開始，對峙按 J／Shift／E，F5 退出普通練習。正常對戰自然累積壓力。新核心 59、原生輸入 11，加回歸共 255 項通過；20,000 步雙實例重播有界、一致，混合戰鬥自然出現 20 次對峙。原生畫面及短 GIF 見 PRESSURE_EXCHANGE.md。只推 codex/street-combat，未部署 Web；真人對窗口、提示明顯程度、冒險回報的驗收尚待使用者。本輪未加投技／彈射牆／Tripo 模型。
