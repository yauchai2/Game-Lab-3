# CITY BREAKER：正式 KO 的可替換 3D 過場

## 最新：五秒快節奏（2026-11-11）

使用者要求整體加快一倍並保留爽感，現正式KO播放長度為 **5秒**，覆蓋下文原10秒播放時長。共用timing.json把原作者時間非線性壓縮：穿街／追天較快、撞樓與空爆保留短重拍，主要空爆約3.61秒、KO字卡4.08秒入場後保留0.92秒。聲效重排重合成，播放音高維持1×，不把低頻爆破一起倍速變調；正式戰鬥simulation時鐘不變。原八鏡與全部FX、角色替換及清理仍適用。

[五秒有聲預覽與驗證](evidence/city-breaker-fast/README.md)：20FX／PCM／節奏、165KO、17結果檢查通過。Godot真正錄製5秒聲畫，沒有後製倍速；Mac／真人實聽與目標GPU仍待驗收。原10秒片段及下文切點是來源作者時間／歷史版本，現播放時間應透過director.playback_time映射。


## 最新：聲音、漫畫 FX 與鏡頭（2026-11-11）

已按使用者最新要求加強，正式零生命KO後自動使用；四角、雙方及原場景接法不變。[有聲預覽與驗證](evidence/city-breaker-fx/README.md)覆蓋初版無聲證據：原創10秒立體聲聲軌、風壓／吸氣／混凝土脆裂／低頻爆破／金屬碎片／引擎轟鳴／KO電子重音，獨立score player服從SFX設定，暫停保留播放位置，全部clear出口停止。BGM原transport持續，重擊暫時4–8dB duck。

畫面新增7-tap邊緣放射模糊、短促色差／高對比撞擊、擴散透鏡壓力環、30條邊緣漫畫速度線、KRAK／DOOM／SKY BREAK原生字卡、3D衝擊環；相機加入震動反衝、FOV壓縮後反彈和最高14°roll。中心保留清晰、末鏡收穩；HUD字卡在後製之後畫，不被模糊。沿CityBreaker唯一演出owner，不用Engine.time_scale，不改傷害／回合。

15新FX／PCM＋164KO＋17結果＋37UI／音樂＋6既有混音檢查通過，最終原生log無ERROR／SCRIPT ERROR。影片是Godot Movie Writer實際聲畫、30fps固定匯出，並非Mac效能／真人實聽驗收。保留F2短版及跳過／暫停／重開清理。下文原初版時序及3D資產界線仍適用；其中「重用原音效cue／無聲15fps」為初版歷史，已由本節覆蓋。


2026-11-11（香港時間）；來源 `codex/combat-escalation-next`，沿用草稿 PR #6。使用者要求按所附 Kling 影片重建 3D，放在戰鬥回合之間，使用當局人物、現有戰鬥背景與飛機。

## 現在可以使用

正式 FIGHT／Street Run 在 Simulation 確定一方生命歸零後，播放約 10 秒的實時 3D KO 過場，然後回到既有回合／賽事結果。不是播放影片或分鏡圖片。超時判勝和平手不拋飛仍有生命的角色；練習恢復生命的規則保持。

- 受擊者直接使用當局 `FighterVisual` 及 roster 選擇，四個角色、P1／P2 都適用；原有 retarget owner 疊加受擊姿態，整個模型沿時間軸拋飛。遠鏡使用黑色／青色邊光，末鏡顯示當局勝者。沒有把參考影片裡的人物當成固定角色。
- 同一個 `StreetBackdrop.street` 的建築、街道、材質及車輛；建築由現有 BoxMesh 分塊，立面細節與 static batches 對應 instance 可逆隱藏。遠景補景只重用現有建築／窗戶的 mesh 與材質，不複製控制器、燈光或碰撞。
- 飛機沿用同一個 `StreetBackdrop.plane`。主翼、機鼻、引擎、起落架與尾翼實際分離；機身及翼面按三角形位置分組，保留法線與 UV。未改動原始 GLB／白盒場景。
- 八鏡：街口拋飛 → 撞牆 → 貼地穿街 → 街區連爆俯視 → 仰拍拋至高空 → 客機受擊 → 空爆 → 回街口 K.O.。包含青色壓力錐、路面光帶、幾何煙雲與三角錐星爆。
- Enter 或 Space：只跳過本次演出並顯示結果，再按 Enter 才進下一回合。Esc：暫停，恢復仍在結算演出，不重新進入戰鬥。F2：立即退出長過場，之後使用原本較短結算。
- BGM 保持原本的雙 deck transport；過場 cue 重用既有音效池，服從靜音／音量／暫停規則。

GitHub Desktop Fetch／Pull 此分支，以 Godot 開啟 `godot/project.godot`，F5 → FIGHT。真 KO 時自動觸發。來源已同步不等於已操作使用者電腦；公開 Web 沒有更新。

## 原片對照與製作界線

原片原樣保存於 [reference.mp4](../references/city-breaker/reference.mp4)，1280×720、24fps、約 10.0417 秒，SHA-256 `8c6bb030c5d99e88867fcea2c5dfb12f2f2d93565b30de329de4256a2fbef187`。以完整時長抽樣、轉場附近密集抽樣與 FFmpeg scene-change 輔助檢視，主剪接起點對齊 24fps 第 13、43、83、125、149、172、189 幀。這不是宣稱每個來源幀均由人手檢查。

| 秒 | 鏡頭 |
|---|---|
| 0–0.5417 | 街口拋飛 |
| 0.5417–1.7917 | 撞牆 |
| 1.7917–3.4583 | 貼地穿街 |
| 3.4583–5.2083 | 街區連爆俯視 |
| 5.2083–6.2083 | 仰拍高空人影 |
| 6.2083–7.1667 | 客機受擊與開始分離 |
| 7.1667–7.875 | 空爆 |
| 7.875–10 | 回街口、勝者及 K.O. |

這是依原片鏡頭次序、剪接時序及事件重建的可玩版本，**不是逐像素完美復刻**：保留原遊戲的建築尺度、角色外形、四引擎客機及天空，與參考片的無名人影／雙引擎飛機有差異；破碎採程序分件及封閉式軌跡，沒有逐幀匹配原片所有變形、煙霧、模糊或音軌。遊戲仍為共用 640×360 像素輸出；不把影片解析度提升當作引擎畫質驗證。

## 所有權與清理

`cinematic/city_breaker.gd` 是 KO 段唯一的相機／場景演出 owner，接在 session 正常 present 後；開場清除原 Neon／theatre／rhythm 演出，避免多套全屏效果同時疊加。不用 Engine.time_scale，不改 health、meter、round、勝者或已成立傷害，不呼叫額外命中判定。Street Run 獎勵仍只由原本規則結算。

保存及還原：飛機 transform／visible、背景 frozen、角色 transform／visible／材質模式、相機 transform／FOV／far／environment、每個原立面 visible、每個修改過的 MultiMesh instance transform。跳過、下一回合、重賽、F2、返回標題和場景退出走同一 clear；源 geometry 不釋放。碎片與補景只在 director container 活動時顯示，首次 KO 建立，之後重用；首次建立成本及目標 Mac/GPU 幀時間尚未量測。

## 驗證

[原生畫面、10 秒錄像、檢查與限制](evidence/city-breaker/README.md)。164 項新過場檢查、17 項更新的結果演出回歸、37 項原生 UI／音樂、62 二段跳、45 正式玩法、30 SURGE 檢查通過。原生 Godot 4.6.3 Compatibility／Mesa llvmpipe／Dummy audio；最後過場及 UI log 無 ERROR／SCRIPT ERROR。

舊 `verify_combat_rhythm` 為 23/29，同樣六個失敗已在未修改 `4177ef9` 隔離 worktree 重現：舊護目鏡身高、舊紅幕／停慢快／輸入／旋轉預期；沒有為通過舊規格而改正式規則。完整 suite 並非零失敗。早期 headless 多次換模曾觸發 Dummy renderer 的 null material 訊息；最終多次換模改以真原生 renderer 驗證，無該錯誤。測試結束的音樂播放清理已加入等待混音 drain，最終過場 log 無 ObjectDB 洩漏警告。

影片為引擎取樣重播的 150 幀／15fps 無聲證據，遊戲時間 10 秒；不是此雲端機器即時達到 60fps 的測量。未驗證使用者 Mac、實際喇叭／耳機、真人接受度或目標 GPU 效能。
