# 全角色技能：長定格改成連續慢動作

2026-11-14（香港）。使用者回報所有角色技能命中時像當機，要求保留重量但畫面繼續緩慢移動。接續 `c1b3101`，同分支 `codex/zip-express-reference`／草稿PR #36。

## 調整內容

原來有兩層停頓：正式技能／大招命中分別設20／26個simulation hitstop ticks；共用Rhythm又有零速度hold，Neon還覆寫成較長的起手／大招時序。大招反彈再加4–6 tick停頓。這些會讓整個交戰畫面停住，並非只能靠目標GPU效能解決的問題。

現在正式 `arcade_enabled` 路徑（FIGHT、一般練習、Demo、Street Run、STORY／SQUAD）使用：

- 技能／必殺、節點脈衝、空中終結／反制及指定反彈：不再設定長hitstop。
- 普通近戰、格擋／招架、拆投與黑衣人槍擊：最多保留1 tick的接觸緩衝，不再疊3–8 tick停頓。
- 共用時鐘：**35%速度重音 → 漸變到60% → 平順回100%**。所有Rhythm種類的速度嚴格大於零；不再突然以1.8–2倍速度追回。
- Neon共用相同profile來源，避免一份已改、另一份仍用長零速度hold。畫面階段改名`accent / slow / release / flow`。
- 鏡頭、背景動作與效果在重音中繼續更新；撞地／撞牆沿同一慢動作owner給重音，不另外全局定格。
- `motion_interpolation.gd`只在兩個已提交的模擬狀態之間插值人物位置與招式幀；慢時鐘少推進模擬步時，畫面仍連續取樣。按攻擊serial／角色／狀態檢查，避免跨招式、重開、傳送或死亡混姿態；群戰以固定敵人ID分開追蹤。ZIP的兩招特效也沿同一呈現pose取樣。

固定60Hz判定、傷害、技能成本、招架窗口的simulation tick數、角色來源模型與BGM owner保留。**原生hitstop的牆鐘等待已縮短，這不是所有時序與舊版等價的宣稱。** 慢動作仍會改變招式的牆鐘時長，需真人驗收手感。

真正的暫停、KO／回合／抽能力導演、反制／對峙需要玩家選擇的等待，以及舊F8/F10/F11教室的等待輸入機制保持；Legacy非arcade規則測例保留原時序。F2回正常速度，暫停凍結插值進度，退出／重開清掉插值歷史。沒有設定`Engine.time_scale`，也沒有預測未發生的命中或用呈現層改生命值。

## 前後對照

[12秒前後比較](evidence/continuous-slow-motion/comparison.mp4)／[新版完整畫面](evidence/continuous-slow-motion/after.mp4)。依序ZIP、RIVET、HUSH、LOOP，各3秒；兩版使用相同正常session指令、100初始能量、站樁對手。LOOP先正常放點再必殺，沒有預塞節點／命中／傷害。基線為乾淨`c1b3101`，保留前後事件／呈現速率／逐畫面pose計數。

四角必殺的實際命中紀錄均由26 tick原生停頓改為0。這個30fps錄像樣本中，舊版攻擊pose幀計數最長連續不變約0.30秒，新版每個錄製畫面的攻擊pose計數都繼續前進。此為**演出時序與取樣證據，不是GPU幀時間／效能提升測量**。影像為Movie Writer、Linux Godot4.6.3 Compatibility／llvmpipe／Dummy混音；未驗使用者Mac、人手操作或喇叭混音品質。

## 驗證

[本輪證據](evidence/continuous-slow-motion/README.md)：新連續動作79、基本戰鬥34、四角資源46、反彈65、群戰規則35／原生10、友善防守25、槍擊21、ZIP必殺44、急件簽收23、既有動作90、編譯13，共485項通過，另19個嚴格警告編譯全過。accepted原生影片／測試log無ERROR／SCRIPT ERROR。

新測試涵蓋七種時鐘在30／60／120Hz取樣不進入零速、平順回流、插值不寫模擬／不跨serial／群戰ID，四角L與必殺正常輸入真命中、技能零原生停頓、命中後pose繼續變動、明確暫停、F2與退出清理。公開`verify_combat_rhythm.gd`現轉接新驗證，總回歸runner亦已更新報告路徑並端到端通過79/79，淘汰舊護目鏡與零速度hold測例；舊內容保留在Git歷史。反彈測試的ZIP最終段fixture補上已存在的`delivery_stage=2`，不再只設定舊`flurry_left`欄位；沒有放寬「只有最後段能反彈」斷言。

待使用者確認慢動作強弱與對戰節奏。未自動合main、未更新公開Web。
