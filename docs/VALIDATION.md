# 驗證紀錄與證據範圍

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
