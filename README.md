# Afterhours / Game-Lab-3

最新：[完整開場→KO→勝者離場與AI Demo循環](docs/evidence/round-flow/README.md)。正式回合3D開場、真KO完整演出後自動接下一round的雙AI Demo、更強煙霧及戰鬥魚眼重音。來源同branch，Web不更新。

最新：[勝者魚眼特寫與四種離場](docs/evidence/victory-exits/README.md)。保留5秒KO爆破，追加3.2秒超近廣角／魚眼與四角專屬動作、慢步出框和角色聲效；結果等離場後出現。來源同branch，Web不更新。

最新：[五秒快節奏KO](docs/evidence/city-breaker-fast/README.md)。整段10→5秒，穿街／追天加快，保留撞擊／空爆重拍與約0.9秒KO收尾；聲效重新合成、不倍速變調。來源同branch，Web不更新。

最新：[有聲 KO 演出與漫畫鏡頭](docs/evidence/city-breaker-fx/README.md)。真正KO後自動播放原創立體聲爆破／風壓／碎片／引擎／KO重音，配合速度線、短模糊、震動及FOV反衝。可跳過／暫停、F2短版，來源同branch，Web不更新。

最新：[CITY BREAKER 3D KO 回合過場](docs/CITY_BREAKER.zh-TW.md)／[10 秒原生錄像及八鏡畫面](docs/evidence/city-breaker/README.md)。真正 KO 後沿用當局四角色、戰鬥街景與客機，拋飛／爆街／空爆／KO；Enter或Space跳過、Esc暫停、F2短版。來源同分支，公開Web未更新。

最新：[二段跳與落地操作改善](docs/DOUBLE_JUMP.zh-TW.md)。正式 FIGHT／Street Run：Space 起跳，空中放開再按二段跳；每次離地一次，加入姿態／局部聲畫回饋，修正硬落地預輸入。來源同一開發分支，公開 Web 未更新。

最新：[正式街鬥玩法改善](docs/LIVE_COMBAT_IMPROVEMENTS.zh-TW.md)／[正式FIGHT真按鍵及30秒前後錄像](docs/evidence/live-combat/README.md)。CPU加入投守勢／揮空恢復／低guard後撤及角色資源決策，LOOP J連段能接第三段，接觸後更快回到動作。直接選FIGHT／STREET RUN體驗；同一來源branch，公開Web不變。

最新：[FIRST MINUTE四步主動教學](docs/FIRST_MINUTE_COACH.zh-TW.md)／[實機與四關示範](docs/evidence/first-minute/README.md)。主選單C進入，真正完成連段、格擋反擊、付費空中追擊及爆發；Enter接下一關、F5重試。396項檢查通過，公開Web未更新。

最新：[SURGE LAB高壓窗口比較原型](docs/SURGE_WINDOW_PROTOTYPE.zh-TW.md)／[畫面、對照片與驗證](docs/evidence/surge-window/README.md)。主選單B進入；21步固定決策、J／Shift／E逐邊鎖定，B切原流程比較。僅練習原型，正式FIGHT及公開Web保持。

最新實作：[SURGE 三階回饋與可靠預輸入](docs/COMBAT_ESCALATION_RUNTIME.zh-TW.md)／[畫面與兩組30秒AI錄像](docs/evidence/combat-escalation/README.md)。沿既有pressure，正式Rush可見升溫；格擋／挑空後J／K／E鎖一次意圖。高壓雙方窗口仍未採入；公開Web未更新。

最新：[五人群像與構圖修正](docs/TITLE_ENSEMBLE.zh-TW.md)／[循環GIF](docs/evidence/title-ensemble/title-loop.gif)。完整16:9鏡頭、前後景站位、同構圖靜態封面。

最新：[原生3D動態標題](docs/TITLE_MOTION.zh-TW.md)／[8秒循環GIF](docs/evidence/title-motion/title-loop.gif)。抽幀剪影、街城視差、近鏡與斜鏡；F2可回靜態海報。

最新：[黑白街城／青粉無臉新封面](docs/COVER_NEON_CITY.zh-TW.md)／[640×360實機畫面](docs/evidence/cover-neon-city/title.png)。標題選單保持原生操作，公開Web未更新。

最新：[LAST SERVICE四角色＋專屬技能＋街區成長](docs/LAST_SERVICE_RUNTIME.zh-TW.md)／[畫面、兩組AI影片及295項檢查](docs/evidence/last-service-runtime/README.md)。試玩：FIGHTERS → STREET RUN／SKILLS；標準FIGHT不套用成長。公開Web不更新。

最新：[大招長動作／近鏡旋轉](docs/NEON_SIGNATURE.zh-TW.md)／[藝術風格與全部可取得參考素材總庫](references/style-library/README.md)／[RPG與技能解鎖提案（未實作）](docs/RPG_PROGRESSION_PLAN.zh-TW.md)。

**本分支已接入Neon Facets M1可玩風格切片。** [功能／試玩方式](docs/NEON_FACETS_RUNTIME.zh-TW.md)／[30秒自由AI影片及畫面](docs/evidence/neon-facets/README.md)／[完整計劃](docs/NEON_FACETS_PLAN.zh-TW.md)。M2–M6待續；穩定分支及公開Web不變。

最新：[新封面／Logo與全套Ink UI](docs/INK_UI.zh-TW.md)／[各頁實機](docs/evidence/ink-ui/README.md)／[拆件素材](godot/assets/ui/ink/README.md)。

最新：[無臉半身剪影封面](docs/FACELESS_COVER.zh-TW.md)／[主選單實機畫面](docs/evidence/faceless-cover/README.md)。

最新：[UI文字加大與Godot4.7.2覆核](docs/UI_READABILITY.zh-TW.md)／[前後實機畫面](docs/evidence/readable-ui/README.md)。只更新原始碼，Web保持不變。

最新：已接入統一像素、3D選角、活街景及音訊恢復。詳見 [本輪實作與試用方法](docs/UNIFIED_PIXEL_RUNTIME.zh-TW.md)，[實機畫面](docs/evidence/unified-pixel/README.md)。只更新原始碼分支，公開Web版本不變。

最新[統一像素美術、活街景與3D選角詳細計劃](docs/UNIFIED_PIXEL_ART_PLAN.zh-TW.md)：本輪僅規劃，未變更遊戲或Web。

## Approved reference UI

[Reference UI update](docs/REFERENCE_UI.md): original title composition, five actions, native four-card fighters and matching HUD. Music ducks through Esc/settings and crossfades songs; all attacks reviewed, noisy raster stamps removed. [Native images / Demo / VFX review](docs/evidence/ui-replica/README.md). Source branch only; public Web unchanged.


## JSR 遊戲內 UI 已替換

[本輪更新](docs/JSR_RUNTIME.md)：JSR 原生介面、四人不同招式／特性、護目鏡94%身高、生成攻擊／爆發圖、新音樂及可關閉低解像畫面。只更新來源分支；公開 Web 保持舊版。


最新 [Jet Set Radio UI 研究與圖片](docs/JSR_UI_ART_DIRECTION.zh-TW.md)：已研究原版手冊／官方 PC 截圖，生成主選單、精簡 HUD、四角色頁，以及透明 Logo／8 框架／16 圖示。[圖片總覽](references/ui-jsr-2026-11-09/README.md)／[素材 ZIP](references/ui-jsr-2026-11-09/afterhours-jsr-ui-v001.zip)。本輪為設計與素材，尚未替換遊戲 UI，公開 Web 不更新。


最新[蓄力重砲與分招式演出](docs/CHARGED_CANNON.md)：**W＋L／↑＋L** 花 75 能量，雙手蓄力 → 雙掌光束；L 普通爆發保持。AI 完成空連後會等待合適機會施放，重砲／暴扣／反制採不同鏡頭。[30 秒新 Demo](docs/evidence/charged-cannon/demo.mp4)／[重砲片段](docs/evidence/charged-cannon/cannon.mp4)。只推來源，Web 不更新。


最新[停慢快節奏與加長紅幕](docs/COMBAT_RHYTHM.md)：挑空／反制／爆發加入**全停 → 0.22 倍慢鏡 → 加速釋放**，全屏速度線、繞行甩鏡；技能紅幕 1 秒、KO 1.2 秒。護目鏡角色 4 身高縮為原來 **2/3**。[30 秒連續 Demo](docs/evidence/combat-rhythm/rhythm-demo.mp4)。F2 比較減少演出，公開 Web 不更新。


最新[四角色配搭](docs/CHARACTER_ROSTER.md)：已加入你提供的 **1、3、4** 三個 GLB，主選單「**角色配搭**」可選自己及對手，即時預覽並保存；對戰／練習／F12 Demo 沿用。四位目前共用招式與能力，公開 Web 未更新。


最新[**Rush 街鬥大改**](docs/RUSH_REWORK.md)：正式對戰 **按住 J 連段＋空中追擊、K 挑空／暴扣、L 爆發**；**F12** 看不會完結的雙 AI 自由交戰，R 重開、Esc 暫停。新增紅幕技能、BREAK 及近鏡環繞 KO。[15 秒無剪接 Demo](docs/evidence/rush-rework/endless-demo.mp4)／[紅幕 KO](docs/evidence/rush-rework/red-ko.mp4)。只更新原始碼，公開 Web 維持舊版。

本節為最新操作；以下先前的「23 段技巧／N 下一段、空戰只限 F11、正式模式不改」均已由這輪取代，保留歷史可追溯。wev 音樂仍已接入。


最新[格擋／反擊容錯與正回饋](docs/FRIENDLY_DEFENSE.md)：**Shift** 接招更容易，成功後 **J 反擊**（不用放開 Shift），空中選擇與高壓決策時間加長。命中才顯示「反擊成功」，普通擋格也有提示；公開 Web 未更新。

最新[雙 AI 技巧 Demo](docs/AI_DEMO.md)：**F12** 自動展示 23 段技巧、自由交戰及 KO 循環。**N 下一段、R 重播、Esc 暫停、F12 結束**；保留 wev 音樂及 F2。只更新開發分支，公開 Web 不更新。

最新[空中借勢逆轉](docs/AIR_REVERSAL.md)：**F11 → F8 → K**，接觸前 **Shift** 反制 → **J 反踢／E 抽身**。花 25 能量、每次離地一次；反踢有起手，可閃避。新增反制教室、踩踏姿態、雙語提示及音效同步。只更新原始碼，**公開 Web 不更新**。

最新[空中街鬥原型](docs/AERIAL_STREET.md)：主選單 **F11 空中訓練**，Space 蓄勢起跳、S 急降、W＋K 挑空 → E 追擊 → J 空中三連、↓＋K 暴扣及一次反彈。新增程序姿態、空中構圖及快速組合鍵修正；F2 減少演出。正式模式保留原玩法，**公開 Web 不更新**。

前輪規劃：[空中戰、誇張動作及聲畫整合](docs/AERIAL_ACTION_AUDIO_PLAN.zh-TW.md)／[wev 選曲與接入](docs/WEV_MUSIC_PLAN.md)。吸收新 R&D 參考並核對跳躍尺度，下一輪優先起跳、有限滯空與空連；**本輪未改遊戲**。wev 其後已由使用者確認可用，並指示自行下載；現已從官方免費下載接入 **family ties (wev edit)**，保留 CC0 缺檔 fallback，公開 Web 未更新。

最新[動能換手與漫畫爆發演出](docs/KINETIC_OVERDRIVE.md)：**F10** 進有限格擋換手練習，Shift 接拳 → J 反擊 → 再格擋升級。正式對戰新增月牙衝擊弧、骨架殘影、三色階爆發、鏡頭反衝及可跳過的 KO 演出。F2 減少演出。只更新開發分支，**公開 Web 不更新**。

前輪[爽感與完整演出優化計劃](docs/GAME_FEEL_ROADMAP.zh-TW.md)：已吸收並保存兩份使用者參考，規劃有限格擋換手、蓄力、分層演出、選角／VS／KO 及驗收次序。**本輪只有文件更新，新系統尚未實作；現行三選對峙保留。公開試玩版不更新。**

**[在 GitHub 直接試玩](https://yauchai2.github.io/Game-Lab-3/)** · 電腦鍵盤、單人對 AI／無限練習、首次約 19 MB。GitHub Pages 已啟用。[操作與更新方法](docs/WEB_PLAYTEST.md)。

前輪[原生 UI 與近身交鋒完善](docs/EXTENDED_POLISH.md)：移除藍樓遮窗大牌，繁中／英文選單、可點按對峙、獨立音量、G 投技／拆投、E 場邊受身、較近的交手追鏡及靜態批次繪圖。只更新 `codex/street-combat` 原始碼，**公開試玩網址仍是舊版**。

[借勢街鬥核心原型](docs/PRESSURE_EXCHANGE.md)：三階壓力、高壓重踢 0.4 秒對峙、J 頂進／Shift 卸勢／E 抽身。主選單選「交鋒教室」，或 T → F8 → K 直接試。

前輪[分段打擊演出](docs/IMPACT_STAGING.md)：六種攻擊弧、頓幀接觸核心、釋放氣浪／碎片及方向反衝；只更新開發分支。

前輪[招牌整理、動態天空與新版 LLB 參考](docs/SCENE_COMPOSITION.md)：保留圖片天空並加入緩慢雲圖漂移，重整空白招牌及支架；只更新開發分支。

前輪[街角立面與兩側街區加密](docs/CORNER_DENSITY.md)只更新 Godot 原始碼，**公開試玩版未同步此輪場景**。在 GitHub Desktop 選 `codex/street-combat` 拉取後 F5 查看。

本分支在既有風格化街區上加入 **2.5D 近身格鬥**：玩家對 AI、連擊、挑空、防禦、能量技、動態頓幀和回合勝負。[操作與完整開發狀態](docs/COMBAT.md)。最新已按試玩回饋修正朝向、接入 14 段 CC0 動畫，改用[斑馬線上的統一透視與追鏡](docs/PLAYTEST_FIXES.md)，場景招牌先留白。[最新戰鬥完善](docs/COMBAT_POLISH.md)：無限練習、對手切換、快速重置、挑空跳躍追擊、AI 難度及設定保存。最新已[接回原圖片天空、車輛與街景細節](docs/SCENE_AUDIO_VFX.md)，修正倒飛與街道拉伸，加入 CC0 音樂／音效、精準防禦及更多局部 VFX。

以 Godot 4 製作風格化低空航道街區。AI 主導製作，使用者透過 Tripo 網頁生成與回傳模型，並提供美術及遊玩回饋。

目前包含六件資產的原型展示庫、已加入遊走場景的轎車及箱式貨車，以及 S1 街道白盒、四個固定視角與俯視布局。S2 基本遊走已實作並完成無視窗邏輯／物理檢查，入口附近的 S3 風格樣片已提供原始材質／兩段／三段比較；S4 飛機掠過、重播及合成測試音已實作；已預設使用原創圖片天空並可切換程序分層雲；已擴充港式店面、街道與飛機細節，已加入使用者提供的角色與暫用步態、低清環境貼圖；人工手感、收聽、最終美術及效能仍待驗收。

## 接續前先讀

- [協作規範](AGENTS.md)
- [交接與目前狀態](docs/HANDOFF.md)
- [待辦](docs/TODO.md)
- [白盒操作、預覽與重建](docs/WHITEBOX.md)
- [遊走原型操作與驗證](docs/WALK.md)
- [風格樣片、比較圖與驗證](docs/STYLE_SAMPLE.md)
- [JSR／BRC 製作規範](docs/JSR-BRC-style-reference.md)與[專案對照](docs/JSR-BRC-project-application.zh-TW.md)
- [飛機掠過原型與新截圖](docs/FLYBY.md)
- [天空樣片與比較圖](docs/SKY_SAMPLE.zh-TW.md)
- [角色與低清街景貼圖](docs/CHARACTER_TEXTURES.zh-TW.md)
- [街景優化、飛機影片與效能檢查](docs/STREET_POLISH.zh-TW.md)
- [GitHub Desktop 同步及 Godot 查看](docs/GITHUB_DESKTOP.zh-TW.md)
- [Tripo 轎車候選圖片及設定](docs/TRIPO_CAR.zh-TW.md)
- [下一個 Tripo 候選：箱式貨車](docs/TRIPO_TRUCK.zh-TW.md)
- [設計基準](docs/DESIGN.md) 與 [下一階段規格](docs/design/next-phase.zh-TW.md)
- [重要決策](docs/DECISIONS.md)
- [驗證結果與限制](docs/VALIDATION.md)
- [資產索引與來源雜湊](assets-manifest.json)

開始修改前確認目前分支、遠端最新提交及工作區變動；不要假設知道其他對話進度。保留現有內容，將重要決策與驗證同步到任務分支。

## 開啟專案

驗證版本為 Godot 4.6.3，以編輯器開啟 `godot/project.godot`，匯入後按 F5 進入格鬥主選單 `scenes/combat/street_fight.tscn`。按住 J 地空連段、K 挑空／空中暴扣、↓+K 地面重踢、L 能量技、Shift 防禦／抓準時機反制、E 翻滾閃避、Space 跳躍；M 靜音、F4 音樂、F2 減少演出、O 場景描邊；遊戲內 F6 返回原街景 `scenes/street_walk.tscn`，再按 F6 回格鬥。

原街景操作：WASD 移動、滑鼠轉向、Space 跳躍、V 切換第一／第三人稱；按 `1–5`／`Tab` 查看固定視角，`0` 回到角色，`R` 重設，`B` 比較樣片材質，`P` 重播飛機，`C` 切換程序雲朵／純色天空，`N` 比較生成的天空圖片，`O` 開關實驗性描邊。原資產展示仍保留於 `scenes/review.tscn`。

```sh
godot --headless --editor --path godot --import --quit
godot --headless --path godot --script res://verify.gd
```

上述命令驗證匯入和場景載入，不能代替 GPU 畫面、實際遊玩或效能測試。細節見 [Godot 專案說明](godot/README.md)。
