## 2026-11-14：依最新明確授權將game-ready動作隨GitHub提供

使用者明示「授權允許，把它放進GitHub，繼續把全部做完」，覆蓋先前私有曲線安裝流程。兩份衍生JSON隨assets／PCK提供，原始FBX保留，來源條款notice明示Mixamo非CC0；loader預設讀資產，環境override僅開發用途。GetUp去padding後以64tick共同恢復取代28tick，depth漸回戰鬥平面；不改第60tick落地傷害。現有招式全覆核，23來源clip全啟用，適用CC0全身動作仍保留而非假稱49Mixamo下載。舊RIVET固定下盤不再疊轉髖，新舊模式原／新版19項均通過；詳MOTION_COMPLETION.zh-TW.md。

## 2026-11-15：以原命中及接觸時鐘接入誇張動作

RIVET 挑空按左手上勾、ZIP 空中收尾按右腳旋踢對齊原 hit tick。移動保持原 simulation root、按來源步速累積循環相位，既有護架及短棍手臂遮罩可疊到新步態。勝利鏡頭和離場路徑按時間取樣。範圍及來源見 [全遊戲動作覆核](WHOLE_GAME_MOTION_REVIEW.zh-TW.md)。

## 2026-11-14：慢速後退採 Mixamo Unarmed Walk Back

Adobe 登入後以 V1xel Mixamo MCP 從官方目錄下載 X Bot 的 Unarmed Walk Back（動作 ID 128650946，FBX 2019、30 fps、無蒙皮）。原始 FBX 的 SHA-256 為 `2096d62a1b6ea6c74003f23f9624e7b2be9a053738d80bb4aea4f25c26fa8531`。取完整 1–40 樣本循環，去除約 1.159 m 的後退位移，按來源 0.89 m/s 配速。四角在地面以 0.3–2.0 m/s 背向移動時採用，按住護架及 LOOP 持棍時沿用既有手臂遮罩。速度與位移由原 simulation 決定，舊動畫庫仍可載入。

## 2026-11-14：第一批Mixamo沿canonical rig重定向，保持simulation權威

來源65骨world rest／rotation私有取樣後離線轉canonical，沿既有CombatMotions→四角；新profile獨佔姿勢，contact phase／實際骨同時供FX與接地。去來源淨位移，保留有界重心，鞋底以skin最低點校正。Walking只配慢速正向步態；複合拳拆單招，Hurricane取單圈加回收，Boxing按實際低位身擊使用。原判定／傷害／物理／過場不改；不適合挑空及未驗死亡／起身owner的來源不強塞。23私有clip中20啟用，另外3個待驗；缺檔與不相容SHA透明fallback。詳MIXAMO_FIRST_BATCH_RUNTIME.zh-TW.md。

## 2026-11-14：正式肩摔採雙人共同時鐘與落地結算

合法grab才進paired_throw；原片共同裁61–121，來源106幀／第60 tick透過原_resolve_hit一次結算，防止立即扣血擊退或重入。骨架／手指保持角色骨長，平面共1.0、垂直參考1.15、腕部雙骨IK與每臂最多3.5cm肩胛修正；真蒙皮貼地，F2不改物理。地面回復用CC0 Roll末段接角色idle。普通群戰鎖原target到收尾，巨型Boss保原規則，致命落地不重播普通KO飛行。詳PAIRED_SHOULDER_THROW。

Mixamo原檔及可還原曲線只私有安裝；公開提交loader／Blender importer／installer／metadata／影片。缺檔fallback保相容，使用者Pull不會自動取得曲線，需安裝對話私有JSON或本機自原FBX重建。原模型／存檔／音樂不改、不發Web，其他候選動作仍待來源。

## 2026-11-14：完整替換生硬動作，接受官方手動下載

最新使用者授權涵蓋全部動作家族；無法代理下載時列名由使用者官方取檔。49項候選按P0=19／P1=24／P2=6分批，名稱metadata不是官方預覽驗收，不採第三方動畫鏡像。LOOP斧擊是改編素材而非專用短棍mocap；同名Boxing依描述辨識。修來源選片也修blend／root／支撐腳／時序，沿原simulation與過場owner，不因換動畫改傷害／存檔／公開Web。見MIXAMO_REPLACEMENT_PLAN.zh-TW.md。

## 2026-11-14：使用者直接提供Mixamo攻守配對

Aggressor固定為施技者，Victim為被摔者；兩段FBX已到手，不再以Adobe token／MCP下載作這組素材檢查的前置條件。先保持原座標與同一幀號檢查，不各自置中或各自裁剪。公開repo只存metadata／工具與渲染預覽，原FBX／可還原逐幀資料放repo外；來源非CC0。近身戰鬥共同裁切先候選46–121，接觸及四角重定向未驗前不錄用為正式招式。不改原GLB、不發Web。

## 2026-11-13 接續：區分官方API錯誤、公開目錄與認證下載

新環境unrestricted／enforced且實際官方目錄HTTP200，不再要求重複加入網域。公開X-Api-Key沿指定上游取得目錄，不使用第三方鏡像或繞過認證；MCP本身要求token，未認證搜尋不當成功。官方GIF只作預覽候選驗證，不抽取成遊戲曲線。launcher可從環境秘密MIXAMO_ACCESS_TOKEN僅記憶體注入，保留私有檔fallback；不經記錄中的MCP參數傳憑證、不提交原始FBX或token。詳MIXAMO_MCP_SETUP最新節。

## 2026-11-13：使用指定Mixamo MCP

採[HaD0Yun獨立Server](https://github.com/HaD0Yun/unity-mcp-mixamo/tree/6170d5eca609eb5cdbbbd6b1a3fc6276362f6701/Server)，不用Unity Helper。固定SDK1.30.0解決2.x破壞性API，client除錯送stderr維持stdio。Playwright作預覽備援。token只在server同主機私有檔，不經聊天／公開repo；本工具不解決proxy403。上游授權標示不一致已記錄，沒有把MCP程式授權當Mixamo素材授權。

## 2026-11-13：以官方Playwright MCP完成工具接入

使用者確認使用MCP，採官方@playwright/mcp固定0.0.85，不直接執行社群Mixamo MCP。雲端Codex CLI已註冊並以真JSON-RPC工具驗證；和本機Extension連線分開記錄，避免把雲端設定當成已控制使用者Chrome。現Mixamo被proxy403拒絕，沿環境設定流程處理網域，不繞過政策。私有profile／下載在repo外；新增本機helper只註冊MCP、不覆寫既有同名設定、不處理密碼。詳[MIXAMO_MCP_SETUP.zh-TW.md](MIXAMO_MCP_SETUP.zh-TW.md)。

## 2026-11-13：免費限制覆蓋較早付費候選建議

## 2026-11-14：選單與彈出文字清晰度覆核

修正原生PopupMenu／TooltipLabel獨立Window的主題及取樣繼承：新Viewport明確nearest、Window缺主題時補共用theme，相關文字明確BODY並移除PopupMenu舊4px描邊。探索Overlay/Help亦補像素字體。5／8／100、字圖與字級保持。87項（原生43／語言21／strict23）通過，包含設定與P1/P2裝置下拉選單的embedded／獨立視窗、真hover提示框、主介面／城市六站／天賦／故事／HUD／暫停／結算。圖及限制見[evidence/pixel-text-audit](evidence/pixel-text-audit/README.md)；雲端Linux4.7.2，非使用者Mac驗收，來源同步main，Web不更新。取樣值4是繼承而非linear，不可只看root nearest便判斷popup已清晰。

## 2026-11-13：中文字體亦套用5／8／100

中文原本仍經向量fallback。本輪新增918字形的RadioPixelChinese／RadioChinese，正文／標題、開場字幕與3D中文字牌改用同一像素preset：24px格、80%二值＋20%coverage，原UI字級不改、繁中字元進位相同，拉丁字圖四檔不改。3D Label採nearest。subset_ui_font.py自動接續字圖生成，未來新增翻譯需一起補字。72項語言／原生／strict／英文／atlas／PCK檢查通過，見[evidence/chinese-pixel-preset](evidence/chinese-pixel-preset/README.md)。來源同步main，Web不部署。

## 2026-11-13：繁體中文語言已加入

設定最上方新增English／繁體中文，選擇保存並於重啟恢復。1034條共用catalog涵蓋選單／HUD／教學、城市六站、成長／裝備／合約／核心、六章及各結局。原生控制項與Canvas繪字統一，中文字體補齊，動態數字及百分比／角色佔位符保持；故事打字按中文長度，天賦全覽與穿戴分開譯。拉丁字體5／8／100、simulation、資料ID與存檔schema保持。264項規則／原生／英文回歸／strict／PCK檢查通過，見[evidence/traditional-chinese](evidence/traditional-chinese/README.md)。品牌、按鍵、音樂名及原圖內文字保留，沒有新增配音；來源同步main，Web未部署。

## 2026-11-13：使用者授權字體最新設定合入main

依「好，推上main」，以main f69fc9f合併story-waves-m1 f4f0742。main原已含352c524及其他分支更新；本輪補入最後兩輪字體設定，保留5／8／100及現有main的介面／據點／開場／角色動作。只有文件衝突，兩邊歷史保持。121項最終檢查通過（整合70／Ink10／城市22／strict19），log無ERROR／SCRIPT ERROR，見[evidence/main-pixel-preset-merge](evidence/main-pixel-preset-merge/README.md)。此授權覆蓋以下舊「不合main」指示；來源同步main，公開Web不更新。既有真人／Mac／硬件及配對投技限制保持。

## 2026-11-13：數值化字體設定5／8／100

使用者接受像素強度5、邊緣硬度8、文字大小100%。設定保存在godot/assets/fonts/pixel-type-preset.json，生成器實際讀取；強度以34−2×數值映射字圖大小（5→24px），硬度8為80%二值輪廓＋20%原字形coverage，字級／布局維持原大小。保留display字距，720p／nearest與場景保持。這是本專案相對美術尺度，非客觀畫質單位或遊戲內設定滑桿；未實作任意文字百分比的自動重排。畫面及驗證見[evidence/pixel-preset-5-8](evidence/pixel-preset-5-8/README.md)。仍同branch／PR #12，不合main／Web。

## 2026-11-13：加強像素與清晰階梯鋸齒

依使用者最新要求，文字字圖24px→20px，alpha三階→二值0／255，去除灰色柔邊；display每字多一個來源像素間距，防止粗斜字黏連。採128中性切割而非最初96加粗閾值，保留字腔。720p／nearest、字級／布局／繁中fallback與無AA toon場景保持。來源tools/build_subtle_pixel_fonts.py及manifest可重建；畫面及檢查見[evidence/crisp-pixel-type](evidence/crisp-pixel-type/README.md)。仍同branch／PR #12，不合main／Web。

## 2026-11-13：收尾與main整合

使用者明確要求所有更新合main並處理未完成工作。採現有owner整合，不新增另一套玩法／時鐘。接地使用有界平地兩骨IK與視覺骨盆補正，不移動simulation root；showcase共用英雄profile須明確opt-in，保留裝備／NPC導演姿態及不露臉取景。主選單5項，正式城市STORY單一入口；舊練習／SQUAD／Legacy Run集中LABS，AI DEMO只留F12。音量0只靜音不停止transport。免費配對投技仍需官方素材，不以現有grab或付費候選充數；原GLB／存檔／Web規則保持。

## 2026-11-12 開場貼近參考影片

Alan 要求開場更貼近參考影片但只做小調整：保留 18 秒結構，移除影片沒有的漫畫字／名牌，場景改暗並補雜物；對白字句沿用 Alan 的表（影片字幕不同，待決定）。

## 2026-11-12：開場 polygon／警告截圖修正

修復眼鏡 glint 零半徑及細小ray的triangulation錯誤：略過不可見burst並以draw_primitive直接提交三角形；整理外層title_progress、未用_t與equipment metadata的獨立ternary。19腳本／七類fatal warnings、288組原生burst及既有37項開場流程通過，15個3D抽格無ERROR／SCRIPT ERROR。證據[evidence/opening-bugfix](evidence/opening-bugfix/README.md)。來源codex/fix-opening-polygons；Godot4.6.3 Linux llvmpipe，Mac／4.7.2待使用者覆核，Web未更新。

## 2026-11-12：完整短篇故事、雙巨型Boss與技巧優先成長

最新見[CAMPAIGN_COMPLETE_RUNTIME.zh-TW.md](CAMPAIGN_COMPLETE_RUNTIME.zh-TW.md)，覆蓋下方「Boss／城市九核心／獨立場景／完整短篇故事未做」的舊狀態。六區18場、兩／三階段Boss與讀招弱點、有限增援／新敵型、危險地面預告／破箱連鎖、分支休息與補給、六章劇本／三NPC／五能力課程／12專屬招式三選二、九核心真DRAW→EQUIP與一次性出擊預算、工坊及裝備骨架外觀已接正式STORY。12個原創低模GLB與Blender來源可重建；原Tripo及英雄GLB保持。schema3保v2樹／裝／局內進度並留.v2.bak，v1遷移仍保持。

裝備直接增傷封頂12%，不增最大HP／parry窗口／無敵；總條件增傷50%／真parry反擊60%，Boss閉甲／弱點限制不可略過，合約HP／傷害亦封頂。四角從零合法掉落／解鎖／付費補給通18場、八組裸裝讀招Boss通關；九種極端裝／核心攻擊spam都敗於最終Boss。這是自動測例，非真人平衡或FPS驗收；簡單原創低模及無配音仍是本版本美術範圍。證據見[evidence/campaign-complete](evidence/campaign-complete/README.md)。只推codex/story-waves-m1／草稿PR #12，main／Web不動。
## 2026-11-12：命中特效改用CC0素材、影子改柔和（Alan要求）

Alan指出命中特效（紫／青多邊形線圈、五邊形、放射線）、地面白色碎片與腳下深藍橢圓影子品質劣質，要求改用線上素材。命中／釋放／格擋破防／蓄力改為Sinestesia CC0命中火花flipbook（白色＋alpha烘焙，按角色色著色，加深色墊底以保可讀）；腳步／落地／滑行塵與slam／ground_ring改為Kenney CC0白煙貼圖；影子改程式生成的三階平色橢圓影，離地時變淡。來源與授權見godot/assets/vfx/SOURCES.md，烘焙腳本tools/build_vfx_sheets.py。不改傷害／hitstop／Rhythm／Neon；swing弧線保留。此決定取代上條「不引入素材採購」中關於命中圖形的部分。未在實機GPU／Mac／真人手感驗收。

## 2026-11-12：命中閃白、墨線速度線、雙色星爆

依Jet Set Radio／Bomb Rush Cyberfunk／Lethal League Blaze方向：重擊星爆改雙色疊層（隊色＋黃色底層，粗黑邊）；Neon RELEASE／BREAK／K.O.在開頭兩幀加紙白全屏閃（Neon仍是唯一全屏owner；F2降低演出時不顯示），並加2px對齊的墨線速度線；Neon原本的斷線菱形與蓄力弧線改為星爆／匯聚墨線。fight_spectacle的放射線與圓點同步改為速度線與方塊（僅非Neon路徑使用）。

## 2026-11-12：特效像素格對齊場景（1素材像素＝1遊戲像素）

Alan指出特效像素比場景／UI粗、不吻合。規則：HUD畫布為1280×720、最終640×360，故特效1 texel＝2 HUD px，一律不旋轉、不任意縮放、座標對齊2px格，只用「小／大」兩套圖集切換強度（星爆64／128格、劍氣固定64×47、煙塵24格）；煙塵以消失代替縮放。風格目標：Jet Set Radio、Bomb Rush Cyberfunk、Lethal League Blaze（平色、粗墨線、強對比、命中閃白）。

## 2026-11-12：命中爆裂改為自製漫畫星爆，蓄力改墨線速度線

Alan回報新特效仍不融入（滿屏樹葉狀火花）。Sinestesia素材縮成像素後像葉片，已停用；`tools/build_vfx_sheets.py`程序化生成8格漫畫星爆（尖角、粗墨線、紙白核心、後四格碎裂成碎片），命中／釋放／格擋等沿用。蓄力／rally／抓取預告改為少量粗墨線速度線（無貼圖），數量減少。劍氣弧線（tbbk CC0）與Kenney煙塵保留。

## 2026-11-12：VFX風格校正為Jet Set Radio式像素cel，並改回原始黑衣人GLB

Alan指出首版發光火花不合風格（本作類Jet Set Radio）。素材改烘成低解析、1-bit alpha、平色＋烘焙墨線、nearest取樣，不做alpha淡出而是縮小消失；揮拳弧線改用tbbk的CC0像素劍氣（所有招式共用，依招式／角色調長度與厚度）；環境煙霧shader改三階平色；影子改三階平色。蓄力／rally／格擋／紅色演出等圈形線條全部改為火花。同回合：Alan提供的GLB與`black_suit/source/`原檔SHA-256相同，已把黑衣人runtime改回此原始GLB（不再用`derived/black_suit_repaired.glb`，該檔仍保留未刪），並放寬verify_black_suit／verify_squad_native對修補材質數量的斷言（>=4 → >=1）。原始模型的後頸／領帶問題未再修補，未經實機視覺驗收。

## 2026-11-12：正式戰鬥VFX實作完成

使用者授權全面實作；採原創可編輯硬邊mesh cels＋骨骼ribbon＋原有Neon／Rhythm，直接作用正式玩法。沿640×360及現有黑白／青粉palette，沒有引入生成噪聲圖集、素材採購或新角色模型。世界煙預留重要容量，Canvas按提示重要性淘汰；不為FX改傷害／能量／hitstop。腳步先距離備援＋較低鞋骨，不冒稱marker／IK。聲畫及shader globals均可逆；Web不更新。詳COMBAT_VFX_RUNTIME.zh-TW.md。

## 2026-11-12：SEPAK原片視覺分析補件

已取得13.792653s／1440p60原片，8fps全時間範圍取樣＋0.55／1.35／12.0起三段來源連續幀，觀察分段弧、雙色煙尾、小腳塵、背景退讓及近鏡，詳SEPAK_VFX_VIDEO_STUDY.zh-TW.md與references/vfx-quality-2026-11-12。未正常速度含聲播放／聆聽，未知引擎／素材／內部公式；LLB新附件超過32MiB工具上限，未取得，需較短或壓縮版補分析。修訂先做小白塵、分段弧、指定事件短雙色煙；runtime與Web未改。

## 2026-11-12：戰鬥VFX品質優化提案

依使用者要求詳細研究，新增COMBAT_VFX_QUALITY_PLAN.zh-TW.md。推薦作者化flipbook＋真世界錨點／socket＋既有Rhythm／Neon混合方案，先六項正式玩法品質切片再四角招牌技；採購僅候選、不重啟退役生成噪聲圖集。數值／排程／新FxRecipe架構均待實作比較，不改既有玩法權威。原X影片尚未取得，未把一般方法當影片實際做法。
## 2026-11-12：開場配樂採用使用者提供的〈Beat Keep Rockin〉

- 使用者指定使用其上傳的 Starjunk 95 音樂並允許自由剪輯；沿用既有 user-tracks 做法：記錄來源 SHA、不宣稱 CC0。
- 選〈Beat Keep Rockin〉是因為 140 BPM 時 3 秒＝7 拍，不必變速就能讓六個鏡頭全部切在拍上，而且它有兩個 drop 可分別對上進車房與標題。〈State Your Name〉（125 BPM）與 mix 先入庫未指派。
- 歌曲仍烘進 `score.wav`，主選單曲（Berlin）不變，17.6 秒起淡入。

## 2026-11-12：開場改用烘焙的原創節奏，主選單曲不再充當開場音樂

- 原因：主選單曲的拍點無法對上 3 秒一鏡的剪接，聽起來與畫面無關。現在配樂寫在 `tools/build_story_opening_audio.py`，160 BPM 半拍，一鏡兩小節。
- 主選單曲在 `MENU_MUSIC_AT`（17.0 秒）前靜音（只調音量，transport 不停），之後淡入。
- 外部素材只收 CC0：BigSoundBank（Joseph Sardin）。節選放 `references/story-opening-audio/`，不在 `godot/` 內，不會被匯入或匯出；`tools/fetch_story_opening_sources.py` 可重新下載與裁切。
- 使用者提供的參考 MV 只用來量測速度與頻段比例，沒有取樣、沒有重製旋律。
- 已知取捨：配樂與音效烘在同一個檔並走 SFX 音量，單獨關音樂不會關掉開場節奏；全靜音仍有效。

## 2026-11-11：開機劇情開場的掛接與存檔

- 依使用者最新鏡頭表，開場放在啟動後、主選單前（覆蓋同一對話較早的「第一次開始故事時播放」）。
- 預設只首次啟動自動播放並可在設定頁重播；旗標用獨立的story_opening.cfg，不改progression存檔格式。是否每次啟動都播留給使用者決定。
- 即時3D、沿用現有模型與資產，不用影片檔、不用參考影片音軌、不做付費生成。音樂沿用主選單曲並只調音量，不停transport。
- 新增唯一導演story_opening.gd；不改simulation。combat_motions僅加一個演出專用的clip指定鍵。

## 2026-11-11：正式抽獎後 3D 裝備（最新）

見 [ABILITY_EQUIP_RUNTIME.zh-TW.md](ABILITY_EQUIP_RUNTIME.zh-TW.md)。按EQUIP／Demo結果停3.5秒後，當局原選角演出副本接取→握緊→腰扣→鎖定→能量到鞋→踩地，4.10秒（F2開始1.15秒）。九核心真腰掛跟隨骨盆保留到下一局重置；不露臉，原街景／stage profile沿用，聲效／魚眼／短模糊／震動／漫畫線／煙塵同步。先演再一次套用，Space跳過不重抽；pause／cancel／R恢復。113新＋69流程＋75核心＋34戰鬥＋46角色／成長＋8嚴格編譯＝345項，證據evidence/ability-equip。原GLB／XP／Web保持，Mac／真人待驗；覆蓋舊腰側裝備僅規劃。

## 2026-11-11：九核心獎池與 Demo 延時自動抽領（最新）

見 [ABILITY_CORE_POOL.zh-TW.md](ABILITY_CORE_POOL.zh-TW.md)。Demo 代幣展示3秒後自動抽，獎品展示3.5秒後自動領取；覆蓋上一輪Demo必須手動的契約，正常模式仍手動。獎池3→9：新增FURY增傷15%、PLATE減傷15%、FLOW命中能量30%、ECO技能耗能-20%、BREACH盾損25%、SIPHON命中回2／整局最多12HP。九種等機率、下一局限定，實際simulation／AI節能門檻／HUD刻度及圖示／輪盤色彩皆接入。263項通過，證據evidence/ability-draw/expanded-pool；原GLB／音訊／XP／公開Web保持，Mac／真人平衡待驗。

## 2026-11-11：手動抽獎、節奏及共用字體（最新）

見 [ABILITY_DRAW_RHYTHM_UI.zh-TW.md](ABILITY_DRAW_RHYTHM_UI.zh-TW.md)。2.05 秒入場／2.20 秒抽獎，三輪鎖定後靜拍再揭曉；必須新按 DRAW，結果另按 CONTINUE，Demo 也等待玩家，覆蓋舊自動抽領。刪減口號與裝飾、統一黑白桃紅青綠 UI；修正獨立 Button 未繼承遊戲 bitmap Theme。63 流程／輸入／節奏＋22 原模型檢查通過，原生有聲證據在 evidence/ability-draw/rhythm-ui；原模型／音訊保留，Mac／真人待驗，Web 不更新。

# 重要決策

以下決策源於本聊天，於 2026-11-06（Asia/Taipei）整理。後續修改請保留原決策及取代原因。

| ID | 決策 | 依據與影響 |
|---|---|---|
| D001 | 使用 Godot 4；目前驗證版本為 4.6.3 | 使用者明確選擇 Godot。當前展示專案採 Compatibility renderer；未將切換 renderer 視為 toon 風格的必要條件 |
| D002 | AI 主導製作，使用者輔助 | AI 負責參考圖、規格、程序模組、整理、Godot 程式及技術檢查；使用者負責 Tripo 網頁生成／回傳與視覺／遊玩回饋 |
| D003 | Tripo 網頁 P1.0 為預設 | 使用者認為 P2.0 成本高，改用 P1.0。不為模型版本名稱要求重新生成；依實際品質判斷 |
| D004 | 簡單物件單張；複雜物件才多角度 | 細節少時可在一張圖內提供三視圖。網頁多視角欄位需要獨立視圖時，須提供獨立圖，不混用不同物件 |
| D005 | GLB、獨立原始來源與 Godot 包裝場景 | GLB 最終幾何為三角面；不能由 glTF version 2.0 推斷曾使用 P2，也不能倒推生成時是否選四邊面 |
| D006 | 小道具約 1,500 三角面／512 匯出是起點 | 依輪廓和觀看距離調整，不視為精確硬上限；1,513 面膠凳可接受。現有 1,582 面廂型車先作停放車驗證，不為符合原先 8K 建議而重生成 |
| D007 | 部件拆分依明確用途 | 使用者有拆分功能；貨箱獨立擺放、車輪／車門動畫、起落架動畫需要時再指定。當前六件均以靜態道具整合 |
| D008 | 現有六件先接受作原型 | 消防栓多一個背面出水口；垃圾桶缺黃色標牌；廂型車較圓順且新增車尾窗；這些先保留，待實際街景距離驗收 |
| D009 | 下一步優先街道白盒與局部風格樣片 | 六件道具已足以驗證尺度。近期不以額外付費道具生成作前置條件 |
| D010 | 共用來源為本 GitHub repo，例行同步直接進行 | 使用者授權將重要決策、進度及驗證提交推送到任務分支；保留其他對話內容，不自動合併或發佈 |
| D011 | S1 主場景切換至街道白盒，保留原資產展示 | 使用者要求繼續指定的白盒交付；新增 1–5／Tab 固定相機切換，S2 行走仍待實作 |
| D012 | 預覽採同幾何的 Blender CPU 渲染 | 本環境沒有 Xvfb 顯示服務；明確區分預覽與 Godot GPU 畫面。俯視圖隱藏飛機以查看布局 |
| D013 | S2 獨立組裝遊走場景，預設第三人稱，可切第一人稱 | 保留 S1 固定相機及六件來源，不將控制器寫進白盒生成器 |
| D014 | 游標釋放或視窗失焦時停止移動輸入，點擊恢復 | 將應用程式鎖定要求與作業系統實際游標鎖定分開；headless 證據只涵蓋前者 |
| D015 | 原型路緣用跳躍跨越 | 先驗證基本控制，不加入自動跨階、攀爬或滑行；玩法確定後再擴充 |
| D016 | S3 以 B 鍵比較原材質／兩段／三段，保留同一幾何與測試光照 | 局部樣片可隨時對照，來源 GLB 不改動；最終風格仍待使用者判斷 |
| D017 | S3 實際畫面採 Godot Compatibility 軟體 OpenGL 擷取 | Xorg dummy + Mesa llvmpipe 只證明該軟體路徑下 shader／投影可運行，不代表硬體 GPU 效能 |

| D018 | S4 在遊走組裝場景以直線航路及可重播觸發事件測試飛機 | S1 原白盒不變；合成音效可替換，人工視聽與風格驗收未完成 |

| D019 | 使用者提議以 GitHub Desktop 同步任務分支後在 Godot 查看 | 繼續推送 `codex/flight-street-handoff`；使用者自行 Fetch／Pull 並提供試玩回饋，不因同步而合併 |

| D020 | 先以程序天空實驗深藍與白／淺藍雲，C 切回原純色背景 | 依使用者聊天參考製作；原圖不在 repo，未作最終美術決定，無需付費生成 |

| D021 | 雲層先用可切換的程序樣片與實際天空渲染比對接縫 | 暫不需要 Tripo／原圖檔；軟體渲染結果不代表硬體效能或最終風格 |

| D022 | 額外 Tripo 候選先建議靜態轎車 | 原有三視圖但尚無模型，新增單車斜角圖方便單圖試產；費用與生成由使用者控制，不阻塞現有原型 |

| D023 | 接受轎車作靜態原型，原始 GLB 不改，於遊走場景另加包裝 | 1,524 三角面／1K，街道陰影偏暗待使用者驗收；箱式貨車為可選下一候選 |

| D024 | 程序天空維持預設，N 切換新生成的全景圖片作比較 | 依使用者新參考生成原創圖片；2:1 圖和特定軟體渲染已檢查，最終選擇及目標硬體仍待驗收 |
| D025 | 箱式貨車作靜態原型加入遊走場景 | 原始 GLB 不改，5.5 m 包裝含簡化碰撞；貨箱背面缺少門件，後續按視覺回饋處理 |

| D026 | 街景細節使用可重建程序分批繪製，保留 S1 白盒與原始 GLB | 靜態裝飾多數無碰撞，路燈使用簡化碰撞；在指定軟體渲染測試中降低繪製呼叫 |
| D027 | 遊走場景飛機微調航路並延長至 12 秒，加入可選描邊 | 保留 S1 靜態構圖；輪廓線預設關閉，Compatibility 與其他硬體仍需驗證 |

生成模型版本只在使用者提供時記錄；GLB 自身未提供可據以判定 Tripo P1／P2 的證據。

| D028 | 依使用者要求預設圖片天空，N 切換程序天空 | 取代 D024 預設；保留 C 比較程序雲與純色，圖片為本專案既有生成全景 |
| D029 | 使用原始角色 GLB 與程式步態作遊走原型 | 檔案含骨架但無動畫；縮放及步態只在包裝場景，並非最終滑行動畫 |
| D030 | 新增低清、低對比環境貼圖及原創街巷塗鴉 | 參考影片的平面色塊與材質節奏；S1 原白盒保留；飛機卡通材質不接收自身陰影以去除斑點，仍可投影 |

| D031 | 採用使用者 JSR／BRC 文件作美術製作參考並分階段對照 | 原始附件與其他對話已存入 main 的整理版均保留；具體數值是製作目標，未獨立證實為原遊戲規格 |
| D032 | 卡通建築的世界投射貼圖使用最近鄰取樣，暫保留 mipmaps | 對齊原場景標準材質且保護遠處畫面；不改角色與道具 UV 取樣，是否停用 mipmaps 待移動對比 |

| D033 | 環境三張貼圖啟用 Godot mipmap 匯入 | 修正 D032 材質設定和實際資源不一致；保留原 PNG，遠距離效果須實測 |

| D034 | 主玩法選擇角色近身格鬥，LLB 用作打擊節奏與視覺參考 | 2026-11-07 本聊天使用者明確指定「類 Lethal League Blaze 但不是擊球，而是打鬥」，更新先前未選定玩法狀態；不製作球速循環 |
| D035 | Godot 2.5D 單機對 AI，格鬥與遊走分開組裝 | 首個可玩里程碑，先取兩回合勝出；保留原街景與來源 GLB；F6 切換。未承諾多人連線或額外付費資產 |
| D036 | 戰鬥狀態用固定 60 Hz，頓幀保留輸入，展示時鐘獨立 | 輕／重招頓幀依招式力度；不把整個 SceneTree time_scale 設零。程序骨架、圖形與合成音只作待驗收原型 |
| D037 | 本任務分支預設進入格鬥主選單 | `codex/street-combat` 以 `f9cd82d` 為基礎，不修改其他聊天的工作分支；兩種模式皆保留 |

| D038 | 格鬥背景採使用者附圖的街口低角度透視 | 2026-11-07 本聊天提供照片、低多邊形和賽璐璐三張參考；左冷右暖、直立招牌、天空與客機機腹為構圖主體 |
| D039 | 背景獨立透視 world，前景保持正交格鬥平面 | 保護橫向距離與命中可讀性；角色追鏡不改變背景仰角。來源白盒不改，背景 render 寬度上限 1280；硬體效能待測 |

| D040 | 角色在街前 Z=3 斑馬線交手，統一透視世界 | 本聊天試玩回饋指附圖只是指引，背景與角色整合不自然；取代 D039 的分離 world／正交前景 |
| D041 | 相機跟隨雙方中點、距離及輕微左右環繞 | 使用者明確容許角度變化；移動控制維持世界 X 軸，最大環繞約 ±5.7° |
| D042 | 先移除場景生成文字，保留空白招牌等待使用者貼圖 | 格鬥與遊走皆隱藏 Label3D／舊幾何字，生成器不建字或塗鴉；遊戲 UI 保留 |
| D043 | 使用 CC0 Quaternius Standard 動畫並轉接現有角色骨架 | 使用者要求網上動作來源；14 段資料有固定提交、授權和雜湊。重踢／上勾拳為自製疊加，來源 GLB 不改 |

| D044 | 完整接回來源遊走場景、圖片天空及兩件額外車輛，取消全街 X 拉伸 | 依本聊天新回饋核對指定對話及 `f9cd82d`，只擴展斑馬線漆；原始模型保留 |
| D045 | 飛機路徑由模型 -Z 機鼻基底推導，提升航道避開屋頂 | 不再獨立手填與機鼻相反的方向；單一世界透視保留 |
| D046 | 角色黑邊保留、場景額外描邊預設關閉，O 比較 | 降低遠景線條密度；場景文字繼續留白等待貼圖 |
| D047 | 接入 Juhani Junkala 與 Kenney CC0 音訊 | 官方來源、授權、雜湊入庫，M 全靜音、F4 音樂；原遊戲素材不抽取 |
| D048 | 現階段加入局部可讀 VFX、精準防禦與起手反擊 | 原創幾何演出，F2 降低演出，AI 暫不使用精準防禦；規則與驗證見 SCENE_AUDIO_VFX.md |

| D049 | 匯出現有 Godot 遊戲為公開網址試玩，不另寫玩法 | 使用者要求朋友打開網址直接試玩；以桌面鍵盤單人對 AI 為範圍，使用 Sites 新 Site，無需登入或安裝 |
| D050 | Web 採 Compatibility、單執行緒和無損 gzip 引擎 | 避免 SharedArrayBuffer／隔離標頭需求及單檔大小上限；JSON 動畫明確打包，保留 F6；方法與限制見 WEB_PLAYTEST.md |

| D051 | 依使用者要求改用 GitHub Pages 作主要分享入口 | 同一份 Web 匯出放於獨立 gh-pages 分支及 .nojekyll；Pages 設定 API 403，等帳戶擁有人選分支啟用，不把待啟用網址當作已上線 |

| D052 | 無限練習、三種對手、重置和輸入／連段紀錄 | 支援朋友反覆試招，練習不結算 KO／倒數，與標準對戰分開 |
| D053 | 挑空確認可跳躍追擊，限制三次後續浮空命中 | 跳躍可頓幀緩衝，未命中不可取消；沿用現有 CC0 骨架動作，不新增來源不明素材 |
| D054 | 三段 AI 節奏及本機設定保存 | 不收集玩家資料；Web F5／F7 防止瀏覽器截走練習快捷鍵 |

| D055 | 日常原始碼同步與公開試玩發佈分開 | 2026-11-08 使用者明確要求：只在點名更新試玩版時更新 gh-pages／其他公開站；本機同步需實際存取能力，不把雲端驗證冒充已操作其電腦 |
| D056 | 以可逆、共用的批次模組補密兩側街角與六棟鄰樓 | 依新寬幅照片補窗籠／冷氣／陽台／店面／街邊物件與原創低清乘色貼圖；保留斑馬線活動範圍、無文字招牌及來源 GLB／白盒 |

| D057 | 新版 LLB 文件作為近身格鬥演出參考，非球類玩法指令 | 2026-11-09 保存原檔與雜湊；時間碼／幀數／原遊戲內部實作未獨立量測，不直接移植球速或技能 |
| D058 | 原圖片天空緩慢漂移，招牌改為單一沿街節奏及四個外側空白挑牌 | 共用天空控制器不改光源；暫停／減少演出停止漂移，移除重複遠牌、補實體支撐；現階段無需新增 Tripo 模型 |

| D059 | 格鬥命中改為接觸核心／頓幀保持／結束釋放三段演出 | 原創六畫格向量弧按招式區分；釋放音與有上限的方向反衝同步，F2 減少演出；不改 simulation 判定 |

| D060 | 使用者接受「借勢街鬥」方向，先落地三階壓力及一次三選對峙 | 共用 0–90 壓力，第三階地面重踢接觸開 24 tick 決策；J 頂進剋抽身、Shift 卸勢剋頂進、E 抽身剋卸勢。首次選擇鎖定，AI 預先承諾及明示提示，結算降壓／冷卻；投技與撞牆後續另做 |
| D061 | 專用壓力練習先不限時閱讀，K 才開始對峙 | 主選單及 F8 可進；等待時保壓並停陪練進攻，F5 退出，避免新手尚未讀完就失去第三階。公開 Web 仍需使用者另行點名更新 |
| D062 | 刪除藍樓佔窗列直牌，改成對應地舖的橫向留白招牌 | 使用者質疑位置合理性；補回住宅窗列與風化，保存 1.81 × 0.43 m 貼圖錨點，不臆造文字 |
| D063 | 原生 Godot UI 共用繁中／英文文案及授權字體 | 戰鬥與遊走共用視覺；固定返回、可見焦點、可點按對峙、練習資訊收起、音樂／音效獨立保存；不為 UI 另建網頁 |
| D064 | 投技有拆投／空中／閃避／普通拳腳對策，場邊受身支付能量 | 深化近身博弈而不引入球；一次撞邊反彈不附加傷害，E 花 20 能量受身，AI 同規則 |
| D065 | 標準／挑戰 AI 可預先選擇假姿勢，教室保持可信 | 真正意圖在玩家輸入前固定；不讀取後改答案，結算標示假動作，避免明示提示變成固定必勝按鍵 |
| D066 | 戰鬥靜態 BoxMesh 合批，保留原幾何／材質／碰撞及除錯開關 | 219 個 box 合成 16 組，同機位繪圖呼叫下降；飛機／骨架與遊走 B 材質比較不參與，不把雲端 FPS 當目標效能 |
| D067 | 結算演出時鐘每回合重設，反白在展示層短暫保留後清除 | KO 後模擬凍結，不能依賴模擬 flash 倒數繼續推進；維持凍結資料並讓視覺正常落地、退去反白，三種結果另有原生回歸 |

| D068 | 保存兩份爽感參考並建立可驗收的演出路線 | 2026-11-09 使用者要求吸收／記錄／詳細計劃；原文 SHA-256 保存，影片時間碼／FOV／速度未獨立核實。以 GAME_FEEL_ROADMAP.zh-TW.md 區分既有、提案、測試目標，不將參考內嵌程式當指令 |
| D069 | 推薦先在練習比較有限格擋連鎖與既有三選 | 僅規劃，未獲選為正式替換：60Hz、互斥模式、有限等級／時長、傷害有上限；先快反，再蓄力／投技，再選角／VS／KO，保留 D060 現行基線 |

| D070 | 使用者授權誇張爽感後，先落地練習限定有限快反換手 | F10 入口、60Hz、四級、第五次成功格擋散能、300 tick 上限、新按 Shift 與首次 J 鎖定；正式仍保留 D060 三選，持放蓄力／多分支後做 |
| D071 | 漫畫爆發由獨立展示時鐘與單一鏡頭控制，世界分色不染 HUD | 三層弧／骨架剪影／地面環／外緣速度線／原創短音；有界效果、F2 及重開清理；不改碰撞或原始貼圖 |
| D072 | KO 先結算，再播放可跳的短演出 | 0.82 秒決勝字樣／放射線／收近再退回，結果其後顯示；Enter 提前下一回合或新場，平手另顯示，不重複計勝場 |

| D073 | 新 R&D 與後續補充優先深化跳躍／空連／角色姿態 | 本輪只規劃；現有約 2m 跳高，參考約 5.7m 的 60Hz 值不直接套用；先做有限滯留、追擊／反彈額度及真反制出口，再擴充誇張展示 |
| D074 | wev 是指定音樂方向，尚未授權則先選曲／接入規劃 | 使用者允許全面更換後明確回答尚未取得授權；已查 SoundCloud／Bandcamp 的 All Rights Reserved，保留現有 CC0 音訊，不下載／打包／購買／聯絡藝術家 |
| D075 | 選曲候選與實聽／錄用分開 | 7 個公開頁面、15 首 OST／2 首 SoundCloud 的必要 metadata 留存；用途基於長度／公開資料的試聽假設，BPM／循環點未知，授權與母帶到位才可錄用 |

| D076 | F11 練習先落地有界空中戰，不直接替換正式模式 | 三幀預備、分段重力、12 tick 出招停留、十幀追擊花 20 能量、三拍／150 tick 浮空限制、暴扣一次反彈；免費手動追擊保留 |
| D077 | 原創程序姿態及 STEP 取樣補動作辨識，保留來源模型 | 蓄勢／升空／頂點／落地／受擊／追擊／四招空中姿態；短旋身只動模型，F2 停用強變形；不是新增十段 Blender 動作檔 |
| D078 | K 按下保存方向組合，空中鏡頭用兩人包圍盒 | 原生測試抓到快放 W／↓ 令下一 tick 丟修飾鍵及場邊腳貼提示板，已修；角色位置仍由純模擬決定，鏡頭不影響判定 |

| D079 | 空中終結反制先在 F11／專用教室驗證 | 新按 Shift 六幀、花 25 能量、每次離地一次；保留位置換主動權，18 tick 選反踢／抽身，不覆蓋正式三選 |
| D080 | 反踢保留十幀可躲起手，教室先讀再開始 | 十八傷害只命中一次、不反制反制；固定期限／無選擇抽身，原生按鍵和按鈕首選鎖定；AI 只讀公開起手並事先選擇 |

| D081 | 使用者確認 wev 音樂已可用，更新接入狀態 | 不再以前次尚未取得作阻塞；目前待音檔／直接下載素材，未抽串流或擅自公開母帶，素材到位後選曲、循環及混音；公開 Web 仍不更新 |

| D082 | 依使用者自行下載指示，錄用官方免費 family ties (wev edit) | Bandcamp 官方免費下載與伺服器 retry 成功取得 MP3 320；不購買 OST，不抽 SoundCloud；提交正規化遊戲 OGG 衍生與署名，原 MP3 不提交，不改標 CC0；現有打擊聲保留及 Web 不動 |
| D083 | 正規化 wev 主曲配合 context 增益，保留單播放頭與 CC0 fallback | 全曲首尾淡化循環，不宣稱無縫小節編輯；原生循環／暫停／duck／音量測試，修正退出時音效播放實例釋放，真人混音待驗收 |

| D084 | F12 加入雙 AI 全技巧展示，保留既有 F9 | 23 段預設情境的自主輸入決策器，真實命中／防禦／資源，不注入假事件；加入自由交戰及 KO 循環，下一輪換左右主攻 |
| D085 | Demo 有獨立播放控制並隔離玩家出招 | N 下一段／R 重播／Esc 暫停／F12 結束及原生按鈕，切段清理演出而音樂持續，退出恢復陪練偏好；正式玩法與公開 Web 不變 |

| D086 | 依使用者要求直接放寬預設格擋／反擊時機 | 地面／空中 12 tick，短按守備、14 tick 出招緩衝，空中選擇 30／起手 14，F10 12/10/9/8 與末八 tick 早按，三選 36；保留資源／投技／冷卻與上限 |
| D087 | 正回饋須來自成功防禦及實際命中 | 完美格擋能量最多 +18、對手硬直 30、36 tick J 提示，按住 Shift 能反擊、跳躍可取消短按保留；反擊無額外自動傷害，對手成功不錯認作玩家 |

| D088 | 使用者授權大改後把有限空戰帶進正式／自由練習 | 按住 J 真實連段與付費追擊、K 挑空／暴扣、開局可用 L；縮短開局／恢復，落地 18 tick 逃脫保護。三選／換手留在專用教室，覆蓋早前原型限定 |
| D089 | F12 改為無限即時雙 AI，不再輪播章節 | 只初始／手動重開設站位；按狀態選招，HP 底線與回復維持交戰。累積真傷害的 BREAK 代替 KO，不注入命中、重設位置或結束戰鬥 |
| D090 | 紅幕用 3D 角色與相機環境替換，技能／重擊／KO 分級 | 0.16／0.14／0.64 秒，無限 BREAK 0.32 秒；真 KO 才近鏡環繞與隱藏 HUD。展示偏移不改物理，F2／暫停／清理保持，參考為抽幀觀察而非抄入影片資產 |
| D091 | 爆發起手保留受傷但抵抗拳腳中斷，投技可破 | 讓首次 L 有回報，非無敵；標準／輕鬆 AI 不精準擋爆發，挑戰保留。手動招式不被按住 J 覆蓋 |

| D092 | 三個新 GLB 原樣保存並接入共用四角色 roster | 使用者提供 1／3／4；各 65 Mixamo 骨骼、約 1.5k tris，重定向現有動作與程序姿態。無動畫不冒稱自帶技能，來源／原角色保留，暫用檔案編號命名 |
| D093 | 基本配搭放在主選單獨立頁，兩方即時預覽及保存 | 對戰／練習／無限 Demo 共用，戰鬥中不更換；預設原角色對角色 1，可鏡像。共用判定與能力，完整角色專屬選角／VS 仍待後續；不部署 Web |

| D094 | 護目鏡角色 4 顯示高度減少三分之一 | 縮放 2.1→1.4，來源 GLB／共用判定不改，陰影／殘影粗細及接觸特效錨點配合 |
| D095 | 以共享遊戲時鐘做真正停慢快 | 真發招／命中觸發，六配置、0.22x 慢鏡與最多 2x 釋放，低階冷卻／優先級阻止每拳打斷；最多兩步、輸入保留，F2 回 1x、暫停／退出清理，音樂不變速 |
| D096 | 紅幕加長並分色／構圖 | 技能 1.0、命中 .65、BREAK 1.1、KO 1.2、結果 1.4 秒；原創收束／斜切遮幅／全屏速度線、約 11° 甩鏡與 FOV 對比。清理慢鏡殘影與重複字卡 |

| D097 | W＋L 新增固定長起手的 75 能量重砲，L 保持 | 30 tick 起手／基傷 38／3.8m／一次命中，空揮不退、連段減傷與受擊能量保持；抗拳腳中斷但受傷，投技能破。不是可變持鍵蓄力 |
| D098 | 招式姿態／鏡頭與 AI 高潮分層 | 雙手後拉／雙掌、獨立紫紅蓄力、光束從手部對接真實接觸點；重砲低視點、暴扣向下、反制反向。AI 依地空五連記住重砲機會，能量／距離／600 tick 間隔，不用預設章節 |

| D099 | JSR UI 先交付可追溯研究與原創圖像 | 實看官方 PC HUD／原版手冊，選單張揚、交戰儀表精簡；主線港式地下電台，不混充 JSRF 或假稱原作字體／動態已量測。原作圖／手冊不入交付包 |
| D100 | 靜態素材與動態介面分層，研究不冒充已接入 | 3 方向圖＋透明 Logo／8框架／16圖示，原生數字／繁中／填色／焦點保留；能量裝飾框不是50／75門檻。現行 runtime Theme／行為不改，接入時沿既有擁有者同步 Tokens／驗證 |

- D101（2026-11-09）：依使用者最新授權將 JSR 提案接入原生 UI；圖片僅裝飾，數字、繁中、按鈕及50/75刻度仍即時。新四人 profile 擁有真實 move data，覆蓋共用能力；scale1.98覆蓋護目鏡1.4。
- D102（2026-11-09）：使用者兩首音樂換掉預設wev；Berlin選單、Groove District交戰，暫停保留播放頭。低解像只作用世界層並可關閉，不模糊UI。特效圖由真事件驅動，不改獨立傷害判定。

- D103（2026-11-09）：使用者要求直接復刻三張參考圖及只留重點選項，授權裁剪。主選單原圖＋真原生Button；選角4卡／P1P2與真資料，動態值不烘焙。English覆蓋前輪雙語設計；Barlow黑斜體OFL接入。
- D104（2026-11-09）：音樂非必要不暫停，Esc／設定改duck；兩個專用串流deck交叉淡化及反轉，舊曲只在無聲後停。撤下生成戰鬥貼圖及骨架棒殘影，用作者化向量cels，地面震波只接真落地。

- D105（2026-11-09，計劃）：最新美術目標統一世界／UI／VFX／字體的像素格，保留JSR色塊／電台構圖；右側3D選角與四人不同非遮臉pose為明確方向。詳細分批規格見 UNIFIED_PIXEL_ART_PLAN.zh-TW.md。建議640×360與單一合成路線／具體尺寸仍須切片驗收後採用，本輪未修改runtime。

## 2026-11-10 統一像素及無聲恢復

採用640×360整個viewport合成；字體為授權來源的bitmap衍生；真3D選角取代靜態大圖，活街景為展示層；保留使用者靜音偏好並提供顯式恢復。 詳見 [實作及證據](UNIFIED_PIXEL_RUNTIME.zh-TW.md)。Web不變。

## 2026-11-10 UI文字可讀性及4.7.2覆核

保留640×360合成，將正文／按鈕加大並擴闊頁面，使用14／16px新衍生bitmap；大標題仍24px來源。修正作用域／三元警告，確保surface替換完成後才釋放override，原始資產不改。 詳見 [本輪紀錄](UI_READABILITY.zh-TW.md)，Web不變。

補充重現結果：4.7.2首幀換模會過早釋放舊材質RID；FighterVisual以單一frame_post_draw回呼清空共用短暫保留佇列，預覽hero延遲初始化。3次場景／24次選角後pending=0且無engine error。新增runner對ERROR／SCRIPT ERROR的失敗判斷，避免state-only假陽性。

## 2026-11-10 無臉半身封面

採用黑白城市／桃紅天與雙人青綠純色半身插袋剪影；Logo沿用，五個原生按鈕與新標題畫面共用logical rect，原圖保留。 詳見 [封面紀錄](FACELESS_COVER.zh-TW.md)。未更新公開Web。

## 2026-11-10 全套Ink UI

重新生成無項鍊兜帽／帽沿封面，換成乾淨白字Logo；所有頁面共用黑白城市header與palette。拆分logo atlas／城市帶／斜切紋，原生frame及控件保留真互動。3D預覽專用shader旗標隱藏五官及描邊，實際戰鬥保持正常貼圖。 詳見 [實作與證據](INK_UI.zh-TW.md)。原始素材及公開Web不變。

## 2026-11-10 Neon Facets分支規劃

另開codex/neon-street-lab／885f1c1，原版保持。參考同時有彩色建築／服裝細節及黑白／剪影段落，採常態Neon Facets＋事件式剪影的雙層方向。數值屬起始提案，六片抽樣不當成作者shader／動畫幀率證據。以M1小切片與A/B驗收擴至M6，見 [計劃](NEON_FACETS_PLAN.zh-TW.md)。本輪無runtime變更。

## Neon Facets M1實作決策（2026-11-10）

使用者「開始做」授權執行既定分支計劃。材質在合批前套用；局部圖形沿既有renderer、全屏只由Lab director仲裁，持續音樂與simulation不複製。最高6°鏡頭／0.10s剪影／0.8s恢復為M1起始值；獨立user://neon_lab/options.cfg。全套拓撲／pose／專屬圖形留後續，現況與驗證見NEON_FACETS_RUNTIME.zh-TW.md。

## 大招、RPG及參考歸檔（2026-11-10）

使用者要求更多／更長動作與慢鏡／zoom／旋轉：Lab大招已延長，14°roll＋36°FOV按兩人body bounds限制；護甲未中斷不能取消鏡頭。RPG為詢問與設計提案，未擅自引入升級數值。所有可讀取參考素材上傳：6原始短片、2完整時長壓縮長片及圖片／原稿／文字總索引；inline原圖缺件明示。gh Release二進制上傳401後移除空draft，改Git內研究副本；保留原Drive／SHA，Web不變。

## LAST SERVICE角色替換與成長落地（2026-11-10）

使用者新4GLB為當前roster，ZIP99c7／RIVETeba8／HUSH966f／LOOP0a7a；原bytes不變，骨名適配及CC0庫重定向。角色特性／資源／技能／UI／FX同步替換，放點不造成假命中，揮擊與真active frames綁定，脈衝使用共同接觸快照。角色專屬3節點共12、裝2、免費重置，僅Street Run生效；勝40／敗15＋本人技巧bonus，標準FIGHT不成長，Demo無XP。詳見LAST_SERVICE_RUNTIME.zh-TW.md。原提案未實作子招式與完整RPG保留待辦。使用者「收尾」後停止加功能，完成驗證與推送，不更新Web。

- 2026-11-10：依最新封面參考，標題背景改為ImageGen原創黑白街城＋青粉無臉半身人物，固定靜態海報，不新增GIF／額外渲染循環。背景圖與原生選單分離；原Godot角色封面保留。只推Lab分支，Web不更新。見COVER_NEON_CITY.zh-TW.md。

- 2026-11-10：參考TR3B動畫改用原生隔離3D標題場景，真骨架剪影及鏡頭視差，避免將整張海報晃動當成人物動畫。固定8秒／自訂120BPM視覺拍點，不冒稱跟音樂自動同步。12Hz更新，離頁與減少特效停渲；既有靜態圖作fallback，生成GIF僅為實機預覽。見TITLE_MOTION.zh-TW.md。

- 2026-11-10：依Layout／角度回饋，改全幅16:9相機與五人前後景，前景兩位／後景三位；固定軸線取代頻繁換角度，五頭部投影避開選單並互相分離。減少特效採同一群像的原生靜態渲染，原兩版封面保留。這是標題群像，不增加多人戰鬥。

- 2026-11-10：吸收LLB補充分析，下一輪升溫沿用pressure_exchange的唯一共用pressure，UI對外稱SURGE；先三級回饋／可靠預輸入，再有界高壓窗口，維持角色meter與專屬資源。原作精確幀數／相剋未獨立核實；本輪只規格，不宣稱實裝或Web發佈。見COMBAT_ESCALATION_PLAN.zh-TW.md。

- 2026-11-10：使用者已明確要求更新公開Web，本輪授權以codex/neon-street-lab現有可玩版匯出至gh-pages；SURGE新規格仍未實裝。使用匹配Godot4.7.2官方單執行緒Web模板；瀏覽器選角壓測記憶體上升後，Web長BGM改用STREAM播放，桌面播放方式保持。之後例行來源更新仍不可自動發佈。

## 2026-11-10：SURGE第一可玩切片

依使用者本輪繼續優化授權，A＋B基礎已接入，覆蓋前輪planning-only。pressure仍是唯一升溫owner，HUD公開名SURGE；同一Rhythm／Neon／Audio調強度，不改真實傷害／能量／成長模式。預輸入由Simulation擁有的continuation_buffer逐邊鎖首個J／K／E，36個非hitstop固定步進期限；僅阻止同一事件的覆寫，消費後普通Rush接招繼續。K按地空解析，E有追擊窗走付費追擊，否則後撤；已有硬直不被清除。暫停保存狀態，下一輪接觸／中斷清理。高壓公平雙方窗口未加入；舊F8教室維持隔離。只推codex/combat-escalation-next來源，不部署Web。

## 2026-11-10：獨立高壓比較窗口與來源同步

本輪「繼續優化」落實規格B有界原型，保留正常對戰及F8舊教室隔離。新增decision狀態在既有pressure owner內，共用90步冷卻；21個Simulation決策步不受Rhythm倍率影響。只在地面雙方idle及合法近身的起手提議前開，並非對已成立招式新增免費取消。到期只交回原生輸入；有限24步普通格擋／一次普通dash，原傷害、能量及判定不改。超時保存雙方原始提議，AI在開窗時依公開狀態預承諾；同幀提議輪替serial優先。B在相同明示fixture重設切換，真人比較後才考慮正式採用。

使用者明示合作流程：完成後commit／push GitHub，使用者在Desktop更新該branch，再本機Godot測試。本輪繼續codex/combat-escalation-next，不再開另一條branch，沿既有草稿PR更新。公開Web未獲本輪更新指示。

## 2026-11-10：FIRST MINUTE教學目標與判定

依「繼續優化」授權補規格E首分鐘及C實際起手提示。四課在明示訓練fixture中進行，教學director只觀察事件及送陪練正常commands，不碰傷害／判定。連段先採共通兩擊，避免LOOP長擊退讓首課要靠場邊才湊三段；不為教學改正常招式數值。parry、起手counter hit、counter_success明確區別，過關需真正接觸，不能按鍵或時間到就完成。讀招提示也檢查玩家合法防禦狀態；機會過期不繼續承諾可反擊。課堂沒有60秒硬期限，也不把自動student速度當真人驗收。沒有XP／裝備或存檔進度變更；每關／F5重建明示fixture，進度只在這次課程記憶體中保留。標準FIGHT／Street Run／自由AI／SURGE原型維持隔離。繼續同branch推送，不部署Web。

## 2026-11-10：正式玩法優先與可操作的攻防

使用者明確指出教學不等於優化遊戲；本輪改正式Rush policy與接觸節奏。保持原傷害、付費資源及動作權威，讓已有G／跳躍／後撤／格擋／揮空恢復在正常CPU交鋒中有實際用途；不以新三選UI取代招式判定。CPU逐次承諾中立意圖與空中選擇，避免讀隱藏輸入或全局節拍相位鎖死。Easy保留單鍵新手路徑，Normal／Hard增加讀公開狀態的反制，不承諾單鍵必勝。

LOOP輕拳連段的原5／6擊退使第三段無法銜接，正式改2.8／3.4；不增加range或傷害，節點、終結擊退保留。Rhythm原生contact tick與演出重疊消耗，最少一、最多兩個原生步進，保留既有release加速與大招長pose；不改native hitstop計數或跳判定。可重現的接觸停頓較短不等於硬件input latency或真人爽感驗收。來源同branch推送，Web不更新。

## 2026-11-10：有界二段跳

使用者要求二段跳及整體優化；直接作用於現行正式街鬥共用simulation，不新增獨立原型。空中一次10.5m/s上推、不取消非idle動作、不刷新追擊／反制／滯空／急降資源，僅實際落地恢復；落地恢復保留跳躍預輸入。沿現有Rhythm／鏡頭／聲音池／F2，不新增全局時鐘或聲稱FPS提升。來源同codex/combat-escalation-next／PR #6；公開Web保持，詳見DOUBLE_JUMP.zh-TW.md。

## 2026-11-11：以main交付最新完整遊戲

使用者明確授權推送最新遊戲至main。將codex/combat-escalation-next的4177ef9完整合併，保留main54a520d及來源歷史，正常push，不使用force。此次授權為來源整合，沒有更新gh-pages或另行公開部署。


## 2026-11-11：黑衣人角色接入

使用者要求新GLB作敵人及其他用途。保留原檔，四名主角ID／成長不變；索引4專供P2黑衣人。敵人使用共用近身simulation與合法AI，獨立50／75能量招式，不附加主角資源或XP。非戰鬥用途由獨立black_suit_actor.tscn提供三種姿態，scene/director擁有根transform；不把演出動畫當命中權威。不自動替換Street Run三站或新增槍械／劇情／Web部署。


## 2026-11-11：群戰與黑衣人修補

按使用者要求加入成群黑衣人，採獨立血量／受擊與單進攻名額，普通近身招可多目標真命中；不用多份simulation重推玩家。群戰由FIGHTERS→SQUAD啟動，不替換既有對戰／Street Run。難度先3／4／5人配35／45／55HP與45／55／65%招式傷害，真人再調。原始GLB不變，修97頸部權重與封閉幾何接合，領帶改乾淨紫色材質補片；只抑制黑衣人凹入頸部的過厚outline。derived資產同時供戰鬥與演出角色。


## 2026-11-11：共用資產的正式 KO 3D 過場

按使用者原片復建八鏡10秒，直接接正式零生命結算而非新增獨立玩法；唯一 CityBreaker 演出owner在Simulation已決勝後掌鏡，不改命中／勝者／資源。沿用當局FighterVisual與retarget，原背景／飛機可逆分件，僅遠景重用本場建築；不烘焙人物或播放原片。先以24fps切點對齊時序，清楚保留與原片幾何／煙霧／人物差異；不宣稱完美復刻。F2原短版、Enter／Space跳過和Esc暫停／所有出口共用clear。來源同branch推送，Web不更新。


## 2026-11-11：KO聲畫單一owner

使用者授權創意加入聲效／震動／模糊／漫畫線，沿既有正式KO CityBreaker擴充，避免第二套全屏director。原創程序score打包為10秒OGG，專用player路由到既有SFX bus與limiter，pause保位置／clear停止；BGM owner只收duck值，不停／重置transport。7-tap邊緣放射模糊與中心保清、短撞擊色差／對比、速度線及FOV反衝都讀同一演出秒數。模糊是風格化放射採樣，並非運動向量motion blur；F2退出長演出及後製。


## 2026-11-11：五秒KO非線性節奏

最新加快一倍指示按本聊天KO上下文落實為10→5秒過場，不改正式simulation／招式速度。保留原10秒作者座標，新增5秒playback_elapsed與共享timing.json正反映射，移動段加速、接觸／空爆留短重拍、KO留0.92秒。程序聲效用同profile重排／重合成、保持音高，避免播放器2×把低頻與金屬聲一起升調。JSON明確打包但不更新Web。


## 2026-11-11：勝者後段與單一演出owner

新要求是在K.O.之後接近鏡／專屬離場，因此保留5秒破壞節奏、追加3.2秒，總長8.2秒，不把已有爆破再壓縮。四角色直接用現有骨架做獨立姿態／離場方向及原創exit音軌；module無獨立時鐘，由CityBreaker掌鏡與音軌切換。依rig頭部位置近鏡，124°FOV結合螢幕桶形畸變；真出框後出結果，避免只淡出模型。near／fisheye／音軌全部走同一clear；原GLB與simulation不變。


## 2026-11-11：完整回合演出、AI Demo循環與煙霧

正式FIGHT／Street Run加入2.8秒同場3D開場：街景、P1／P2角色近鏡、ROUND，再交回原倒數及對戰。Enter／Space跳過，Esc暫停，練習保持即玩。AI Demo改正常有限生命、不回血，真KO後播完整5秒破壞＋3.2秒勝者魚眼與離場，之後自動下一回合；兩勝完場也繼續loop，沿用選角、不發XP。覆蓋舊Demo endless／無KO契約，正常FIGHT結果仍由玩家確認。

場景加入有界屋頂／街邊煙、命中揚塵及64團KO殘煙；重擊後可短暫魚眼近鏡，避讓Neon大招與KO，保持雙人及HUD留白。新增原創2.8秒開場音軌，沿原SFX／mute／pause及BGM duck。詳見evidence/round-flow/README.md。來源同codex/combat-escalation-next／PR #6，公開Web不更新；Mac／硬件效能與真人強度仍待驗收。

開場是獨立presentation owner，在ready時凍結simulation但不改其資料；KO仍由CityBreaker唯一掌鏡。戰鬥accent只在其他鏡頭空檔、真重擊後觸發，0.28秒／至少1.6秒冷卻，不改遊戲時間或傷害。Demo只在正式結算及演出完成後呼叫next_round／restart_match；不在live fight重設生命、注入命中或替AI補傷害。煙霧用世界座標billboard及量化噪聲，18環境＋12命中池＋64KO固定上限。


## 2026-11-11：結果頁修復、決勝KO與四面反彈

修正RESULT空白：先前在CityBreaker仍active時提前設finish_menu_open，rebuild把controls隱藏；之後director清場但沒有再建選單。本輪在演出釋放後才建立結果操作，並對空白狀態自我恢復。原生測試驗真visible buttons、視窗內位置及pressed callbacks，涵蓋自動播完／暫停／F2／跳過、下一回合與重賽。

依最新指示完整KO只在兩勝制決勝回合；之前回合短結算。Street Run只在最後一站或本次Run敗退結束播完整KO；超時不偽造零生命KO。Demo仍沿真勝負loop，每場只有決勝KO，之後接下一場開場。

正式Rush／Demo／Street Run加入四面盒狀反彈：x±8.2、腳部y0–5.6（8m頂框），重擊／挑空／終結擊／符合推力的技能真命中才發射，普通輕拳不觸發。法線反射耗能、無額外碰牆傷害；每次飛行最多6個接觸／180物理tick，耗盡自動恢復＋18tick保護，不被新命中刷新預算，落地後才重置。接觸後18tick內可E花20能量受身；AI有有界反應延遲。暫停／hitstop不消耗飛行時間；F2保持物理，只減演出。

真3D透明線框圍場、每面重用一個撞擊格、既有SFX／揚塵／速度尾跡／軀幹中心翻滾。高速飛行鏡頭以雙人body bounds即時退開，避開HUD，反彈字卡移到底部。詳見[evidence/arena-box](evidence/arena-box/README.md)。同codex/combat-escalation-next／PR #6推來源，不發佈Web；Mac／真人平衡、鏡頭和混音待驗收。

反彈是Simulation的有界運動，ArenaBox不改生命，camera／mesh僅讀真接觸事件；不用畫面邊界或假命中控制物理。舊單次wall bounce保留給獨立教室／非Rush路徑，正常跳躍也會受天花限制，但不自動進入受擊反彈。

## 2026-11-11：THE DEALER回合間抽能力

依本聊天最新「開始製作」授權，正式接入第二回合尚未完場／Street Run第二站勝出的3D抽獎。共用當局世界與局部stage資源，NPC／機器獨立、玩家／影子不入鏡；一次隨機結果／一次領取，僅下一局modifier，不新增貨幣或永久扣XP。保持既有KO與先取兩勝、音樂transport、Compatibility及Web規則。細節與差異見ABILITY_DRAW.zh-TW.md；不宣稱逐像素復刻。

## 2026-11-11：入場不可退回無遮擋原地生成；裝備段另規劃

主街採真碰撞驗證過的±6m／z0入口及空場起鏡；兩路全堵compact需先遮幕再揭開，不關閉物理碰撞來繞過。使用者本次新增裝備需求允許只拍玩家手／腰／鞋，不露臉；1.8秒腰側夾具分鏡為提案，未當成已實作。未來Tripo模型原檔保留，另建衍生綁骨與分件。

## 2026-11-11：機器Tripo採外殼／活動件分離

使用者詢問整機生成與中間抽獎動畫難度：首選手工硬表面；若使用Tripo，只生成靜態機殼，輪盤／輪子／拉桿／出貨蓋另建，整機父節點動作與零件動作分開。三視圖與prompt在references/ability-draw/tripo；生成稿非CAD投影，背面補完，不冒稱已取得可動畫的Tripo資產。

## 2026-11-11：原Tripo骨架與機殼包裝，窗口及短音效可控

以使用者原65骨／skin NPC製作runtime動作，不覆寫GLB或替換四戰鬥角色；機殼原貼圖保留，以衍生材質按局部座標移除窗口多層封面，活動件獨立。重用既有CC0 gait、原手腕二骨接觸／代幣跟手，不宣稱來源已有動畫或已烘焙回GLB。快速重開Ogg短cue退出滯留改用解碼PCM，原OGG及長BGM保持。詳見ABILITY_DRAW_TRIPO_MODELS.zh-TW.md；腰側裝備仍僅規劃。

## 2026-11-11：來源集中整合至 main

使用者要求「把所有的更新都推到最常用的branch」。以 main738c740 為基礎，整合黑衣人分支987d4d2與正式戰鬥／過場／抽能力分支3389fa9，保留雙方提交及來源資產；往後 GitHub Desktop 選 main Fetch／Pull。此節覆蓋下方歷史的「main未更新」狀態；公開Web不更新。

同時處理整合相容性：黑衣人索引4支援進場名稱／顏色、通用步行勝者離場及既有HUSH離場音軌；群戰保留多人跟鏡與短結算，不套雙人進場／決勝KO／回合抽能力。四英雄正式回合演出、有限生命Demo及抽能力保持；合併空連預算helper與ArenaBox排除，保留3位數群戰倒數。

合併來源已跑477項最終檢查：146無視窗規則、177原生UI／結果／回合／勝者／材質、154群戰／黑衣人／Tripo抽能力。最終無ERROR／SCRIPT ERROR；Linux Godot4.6.3 Compatibility／llvmpipe／Dummy，非使用者Mac或真人手感驗收。最初round-flow 19/23的測試器在單一引擎影格內跑完整Demo，抽能力防重複確認阻止第二次動作；改為定期讓出真引擎影格後24/24。初次失敗與最終結果均保留在 [整合證據](evidence/main-integration/README.md)。

## 2026-11-11：main 收入最後一筆遠端更新

推送前再次核對遠端，combat-escalation-next已從3389fa9前進至3ea0691，故再合併該提交。包含手動DRAW／CONTINUE、2.05秒入場／2.20秒逐輪抽獎、新音訊及共用bitmap UI；Demo也等待玩家確認，覆蓋下方自動抽領的歷史描述。群戰／黑衣人相容處理保留。更新回合測試以明示Enter確認抽獎，不移除最新手動要求。

最新合併來源再跑109項原生檢查：回合24、模型22、抽獎流程／輸入／節奏63，全部通過，無ERROR／SCRIPT ERROR；證據見evidence/main-integration/latest-final。前一整合477項與初次測試器失敗保留，非宣稱使用者本機／真人驗收。兩次合併保留987d4d2、3389fa9、3ea0691完整歷史；日常取main，Web未更新。

## 2026-11-11：修正Godot4.7.2腳本警告

依使用者截圖，以實際同版本重現四類共15項warning後修正根因，不以warning_ignore或關閉warnings處理。數值保持、局部名稱明確，static由型別呼叫。嚴格測試須在Godot程序啟動前設定warning等級（parser會快取）；新runner使用臨時project override.cfg而不改使用者project偏好。沿集中main交付，公開Web不更新。

## 2026-11-11：死者落地展示

死亡clip優先並保留完整垂直軌跡，按髖高校準，不再受站立bob／活人空中層影響。只在物理位置已落地後按實際skin最低點校正展示，落地死者停旋轉／伸縮，動畫完成後快取；不改原GLB／生命／傷害／位置判定。群戰凍結結算對非focus死者也套同一result clock落地，保持simulation快照。集中main交付，Web不動。

## 2026-11-11：同步 main 至 codex/combat-escalation-next

使用者明確要求也推到codex/combat-escalation-next。以遠端最新91db1f1合併main的ffffd15，保留九核心與Demo定時自動抽領，以及main的黑衣人群戰／頸部領帶修補／過場相容處理，不強推、不改Web。此輪只推指定開發分支；main維持ffffd15。最新Demo自動節奏以ABILITY_CORE_POOL.zh-TW.md為準，覆蓋較早手動Demo契約，一般FIGHT／Street Run仍手動。

合併後144項通過：九核心75、群戰規則35、原生群戰10、原生回合24；無ERROR／SCRIPT ERROR。Godot4.6.3 Linux Compatibility／llvmpipe／Dummy，非使用者本機或真人平衡驗收。證據docs/evidence/branch-sync-combat-escalation。

## 2026-11-11：反彈限指定強化技能／大招

使用者澄清球狀連續反彈只屬特殊攻擊／大招，覆蓋前輪普通重擊／挑空／投技也發射的範圍。一般jab／cross／heavy／finisher／launcher／meteor／air_finisher／air_counter／grab及未強化special不啟動ArenaBox，保留原擊退／既有單次牆彈。四角色大招最後重擊（ZIP連打末段）及RIVET滿蓄、HUSH強化special由move metadata明確opt-in；傷害／消耗不改。

圍場只在反彈效果期間可見，平常不加臨時天花限制。仍有6接觸／180tick／E20受身、衰減、跟鏡與F2。65反彈規則＋25原生結果／鏡頭＋62二段跳＋10重砲＋7Demo＋34戰鬥＋75能力核心共278項通過；原結果頁修復、決勝KO及能力抽取功能保留。[新證據與大招預覽](evidence/ricochet-scope/README.md)。同branch／PR #6來源更新，不發佈Web，真人／本機驗收待辦。

## 2026-11-11：降低戰鬥HUD閱讀負擔

使用者要求分析簡化資訊，其後要求將全部更新推GitHub；把建議實作到正式HUD。常駐只留血量／能量／時間／勝場、短名字與資源格、SURGE細條，常規成功動作由局部聲畫交代；重要決策／錯誤仍有回饋，教學保留詳細說明。二段跳不再產生文字字卡；不調輸入延遲、招式或音樂transport，沿main同步來源，Web不更新。

## 2026-11-12：故事波次方向（提案，非實作）

使用者要求詳細關卡規劃。建議六關有限波次、敵型分工／進攻名額、真敵碰敵有界連鎖與大型中Boss／最終巨獸；以投影可讀性限制遠鏡頭，維持原2.5D操作。新故事核心以兩關區段定義作用期，原FIGHT／Demo下一局與指定技才開四面盒規則不變。詳細數值待M1／白盒／真人與目標機器驗證；本輪不改runtime／存檔，不把文件當已完成功能。

## 2026-11-12：故事M1獨立分支實作

使用者要求開新分支開始製作，故在codex/story-waves-m1先完成三波切片，覆蓋上輪M1僅規劃狀態。StorySimulation繼承Squad，Story關閉完全委派；獨立有限波序／角色行為／掃掠撞體，普通攻擊不自動開四面盒。checkpoint僅同場，無XP／永久核心，Boss／六關／存檔後續；原GLB保留，新增程序道具。此次明確要求獨立分支優先於先前main集中交付慣例，不自動合併或更新Web。

## 2026-11-12：城市ARPG下一階段設計提案

使用者要求故事主選單、能力漸解鎖、類POE2天賦樹、城市刷圖與抽裝，詳細方案見 [CITY_ARPG_PROGRESSION_PLAN.zh-TW.md](CITY_ARPG_PROGRESSION_PLAN.zh-TW.md)。新故事進度擬採保證能力里程碑，覆蓋故事永遠全招式可用的舊方向；標準模式／訓練／Demo及舊存檔既有能力保留。原創48節點與25點、三裝備槽、兩貨幣及機率／保底均為待驗證提案。永久裝備與九臨時核心分層；故事核心下一整張圖持續，替代早期兩關區段提案，標準下一局契約維持。先一區完整循環，後六區／Boss／高階合約；本輪不改runtime或save schema，只推獨立任務分支。

## 2026-11-12：Hades式城市循環首版

使用者要求開始用簡單assets製作Hades式回城升值與故事。已接主選單STORY／45°正交可行走小城，採永久金錢裝備技能天賦＋本次出擊臨時強化分層。城市與戰鬥視角分離；六區共用戰鬥基底、隊長暫沿盾衛AI。先12節點8點／三槽單詞條品質／短對話／18遭遇及獨立存檔，不將完整POE式樹或巨型Boss冒稱完成。舊M1與標準模式保持，規劃與實作差異見CITY_ROGUELITE_RUNTIME.zh-TW.md；只推任務分支及更新草稿PR，不合併／不發佈。

## 2026-11-12：提高解像度與補完城市主要成長系統

使用者要求整體稍高清仍保持JSR／BRC／LLB復古風，並實作前述尚缺成長。最新960×540覆蓋640統一解像度舊規範；保留nearest、無AA、toon輪廓、logical UI與音樂。48節點／25點與T1–T5、詞綴、掉落／倉庫／比較／角色配裝現已接runtime，取代僅12節點／數值裝／無合約狀態。舊技能與資產保留，v1城市樹退點、schema2／.v1.bak。詳CITY_PROGRESSION_EXPANSION.zh-TW.md；未做巨型Boss、完整故事與新場景美術，不因主要系統落地就冒稱整份大計劃全完成。只推原任務分支／草稿PR，main／Web不改。
使用者明確授權推送最新遊戲至main。將codex/combat-escalation-next的4177ef9完整合併，保留main54a520d及來源歷史，正常push，不使用force。此次授權為來源整合，沒有更新gh-pages或另行公開部署。

## 2026-11-11：故事解鎖與本機雙人輸入（Claude 對話）

| ID | 決策 | 依據與影響 |
|---|---|---|
| D-LV1 | 「故事模式」＝現有 Street Run 三站；「自由對戰」＝標準 FIGHT（1P VS CPU）與新的 2P LOCAL VERSUS。通關前只鎖自由對戰；訓練、教學、AI DEMO、設定保持開放 | 使用者要求「一開始只有故事模式，完成故事後解鎖自由對戰」。教學類不是對戰模式，新玩家在故事前需要練習入口。使用者 2026-11-11 確認「只鎖對戰」，並說明 AI DEMO 是測試用、正式不推出 |
| D-LV2 | 通關條件為第三站勝出；旗標 `story_cleared` 存在既有 progression.cfg，版本號不變，舊存檔視為未通關 | 沿用已有的 tmp／bak 換檔流程，不另開存檔；不追溯以 XP 推斷通關，避免誤判 |
| D-LV3 | 主選單由 5 項改 6 項，覆蓋 REFERENCE_UI「僅 5 主選項」 | 新模式結構需要 STORY 與 VERSUS 兩個入口；版面在原左欄內重新分配，文字仍原生繪製 |
| D-LV4 | 新增 `fight_controls.gd` 作唯一裝置擁有者；單人鍵盤原有輪詢與按鍵處理不動，手柄以 OR 併入；`fight_simulation.gd` 不改 | 模擬本來接受兩方指令。保留原路徑使既有輸入測試結果不變，降低回歸風險 |
| D-LV5 | 雙人 AUTO：兩支手柄各一；一支給 P2；沒有則分鍵盤。已持有手柄的玩家在熱插拔時不被換走 | P1 在故事已學會完整鍵盤配置；避免拔一支手柄令另一人的手柄易主 |
| D-LV6 | 分鍵盤 P1：WASD＋F G R T、左 Shift、E、Space；P2：方向鍵＋K L O P、右 Shift、I、;，另有數字鍵盤替代 | 兩組鍵互不重疊，避開 H／M 等全域快捷鍵；筆電無數字鍵盤亦可用。位置未經真人及鬼鍵實測，可按回饋調整 |
| D-LV8 | 雙人對戰停用回合間能力抽取 | Codex 分支的抽取只把強化給 P1；兩名真人對打需對等。其他模式不變 |
| D-LV9 | PR 由指向 main 改為指向 `codex/combat-escalation-next`，並以其最新提交為基線 | 使用者確認的協作流程：Claude 分支由最新 Codex 分支開出，草稿 PR 回 Codex 分支 |
| D-LV7 | 實體手柄、鬼鍵、雙人手感一律標為未驗證 | 雲端只有注入事件；依 AGENTS.md 不把 headless／注入輸入當成實機驗收 |

## D-merge-2026-11-12：全部草稿 PR 合入 main（Alan 要求）

- 合入 #12（城市故事）→ #13（VFX）→ #7（含 #8 本機對戰）→ #9（UI 計劃）→ #10（開場）→ #11（音訊）。#12 PR 內「不合 main」已由 Alan 的最新指示覆蓋。
- 主選單整合：STORY＝#12 城市；VERSUS＝#8 的 FREE BATTLE（1P VS CPU／2P LOCAL／裝置），仍由 Street Run 第三站通關鎖住（`growth.story_cleared`），Street Run 入口在 FIGHTERS 頁；FREE PLAY（原 #12 的 FIGHT／SQUAD／Demo 頁）改為 SQUAD＋AI DEMO，FIGHT 併入 VERSUS 以免繞過鎖。尚未決定：鎖是否該改綁城市故事通關。
- 音訊：#11 的 CC0／程序音效與合輯音樂取代 #13 前的程序 tone；保留 #13 新增的 ink_snap／ink_scrape。
- #1／#2／#5 是更舊的堆疊 PR，與 main 大量衝突且內容已被取代，未合併。

## 2026-11-12：夜班維修場回城場景

使用者要求將確認的黑白工廈／桃紅背景／低模角色概念落成可互動遊戲地圖。基於最新main6fdd3a6，在codex/nightshift-hub改造既有STORY城市，保留CityProfile／CityCampaign／schema3與六區戰役。實際3D剖面場景、可走DJ閣樓、六設施、靠近E／點設施或1–6實走、點地尋路、三位正式英雄同伴（換角無重複）、原Tripo黑白wrapper、章節戰利品／短環境動作已接入。新場景使用程序幾何，原GLB保持；另交F6預覽與可導入Blender的衍生nightshift_workshop.glb，無需新增Tripo。詳[NIGHTSHIFT_HUB.zh-TW.md](NIGHTSHIFT_HUB.zh-TW.md)。

[實際引擎畫面與驗證](evidence/nightshift-hub/README.md)：211行為／原生／城市戰役回歸＋14嚴格編譯，共225項通過，accepted無ERROR／SCRIPT ERROR。樓梯轉角／延遲焦點／舊fixture STORY鍵與排版等待已修，初次失敗保留。Linux4.6.3 llvmpipe／Dummy，非Mac／真人／FPS驗收。這是概念的可玩3D重建，非逐像素完稿；後續角色關係／黑箱劇情回城演出仍屬規劃。只推任務分支／draft PR，未發Web。

## 2026-11-12：按原圖重做據點＋15秒動態（覆蓋粗模）

使用者回報上一版差距大，要求照指定圖、移除無關物件，並給15.083秒動畫。正式入口改用reference_workshop.gd：固定鏡頭投影空場貼圖／3D深度片與可走地面、既有四英雄／Dealer骨架、活動橙色臂、掃燈／光斑／煙／電光／閘門開口與門內剪影；Loop移向機器後回位。移除接線大機／戰利品牆／站位框，天賦綁LOOP區，Tab展開HUD。這是**2.5D／3D混合固定視角方案，不是全角度實體建築**；人物外形／姿態仍有差異，不稱逐像素或逐來源幀完美。詳[NIGHTSHIFT_REFERENCE_REBUILD.zh-TW.md](NIGHTSHIFT_REFERENCE_REBUILD.zh-TW.md)。

[15秒原生預覽與對照](evidence/nightshift-reference/README.md)：450幀／30fps，15.000秒；輸出配既有menu.ogg低音量，未用附件音軌。211回歸＋15strict通過，accepted無ERROR／SCRIPT ERROR；另有時間線採樣與六站／F2檢查。原Tripo不改、schema3／戰役經濟保持。Tripo必需0件，若做全角度／人物輪廓精修，優先Dealer與指定英雄，再DJ台／音箱／機器殼；具體規格見references/nightshift-hub/TRIPO_REQUIREMENTS.zh-TW.md。只更新codex/nightshift-hub／草稿PR #19，未發Web；Mac／真人仍待驗。


## 2026-11-13 全分支整合來源

- 完整來源紀錄：docs/integration-history/story-waves-m1/docs/DECISIONS.md
- 完整來源紀錄：docs/integration-history/four-fighter-motion-plan/docs/DECISIONS.md

## 2026-11-13：免費限制覆蓋較早付費候選建議

使用者指定「用免費的資源做」並追問Mixamo，優先核實Shoulder Throw攻守配對。Adobe免費商用FAQ與第三方目錄名稱分開記錄；未有官方FBX／實測，不冒稱已取得／已配對，不採購付費包。詳[FULL_JUDO_THROW_RESOURCES.zh-TW.md](FULL_JUDO_THROW_RESOURCES.zh-TW.md)最新節。
