# SURGE：升溫可見、停頓收鍵可靠

2026-11-10。根據 [規格](COMBAT_ESCALATION_PLAN.zh-TW.md) 完成A＋B基礎切片；本輪開發來源在 `codex/combat-escalation-next`，從Lab `891489b` 接續。

## 試用

Godot開啟專案，FIGHT／T練習／F12正常自由AI皆可看計時器下的SURGE。0–29 FLOW青、30–59 HEAT螢光綠、60–90 SURGE桃紅，數值及三段條直接讀取既有exchange。資源仍在左右角色側，並保留P1／P2。

成功擋住、完美格擋或挑空後，按一次J續攻／反擊、K地面挑空或空中砸地、E有追擊窗時付費追擊、否則後撤。收到時角色資源下顯示P1／P2＋按鍵＋LOCK。首個有效J／K／E鎖定；其後按鍵不覆寫，兩邊各有自己的slot。單純按住J保持原Rush自動接招，不視為新決策；已交付後可繼續普通輸入。

記下意圖不保證出招或命中。Simulation仍檢查硬直、距離、追擊次數及原20能量；沒有免費回復行動權。鎖定優先於同一步新的招式，之後交回原生招式buffer。每事件36個非hitstop固定步進有界，原生hitstop及演出hold不扣期；Esc停整個時鐘、保存有效狀態。受擊、被招架、KO、重開及退出會取消；舊air_counter／F8窗口維持自己的隔離規則。

## 回饋與owner

- pressure取值、衰減、封頂、接觸connected／pulse serial及全部傷害不變；沒有第二條熱量或新倍率。
- 升階一次聲音與短數字跳動；背景反應1.5秒冷卻。F2保留數值，移除跳動／停慢快演出。
- 接觸局部強度為既有強度×0.65／0.85／1，接觸音降低5／3／1dB；高強度重音多一層低頻但降低音量。
- 同一Rhythm的parry／launch／impact之hold及slow時長乘0.45／0.72／1；release保留。原生hitstop tick不改，因此不是總停頓縮短同一比例。付費大招起手長pose保持；不另加時鐘或全屏owner。
- 同一Neon director的PARRY／RELEASE時長跟三階收斂，既有優先權及回氣仍生效。SFX bus只裝一個-6dB limiter，單voice不允許正增益；BGM雙deck／duck及transport維持原路徑。最終混音峰值尚未實錄驗收。
- STREET RUN BUILD ON改在ready／暫停／結算顯示；一般接觸notice下移，讓中央表有位置。

## 驗證與後續

[原生畫面、兩組30秒AI、真鍵盤與log](evidence/combat-escalation/README.md)。30新增＋250規則＋37原生UI／音樂共317項檢查通過，另有實際桌面K／Esc／Esc結果。Linux Godot4.6.3／llvmpipe／Dummy audio，不是目標Mac、真人手感或實聽驗收。

高壓公平雙方決策窗、假動作、AI習慣教讀、完整首分鐘教學及三站敘事仍待後續；先比較這輪可靠預輸入是否已足夠，再決定是否加新窗口。公開Web沒有更新。前對話讀取失敗，實作依指定規格及本分支紀錄接續。
