# SURGE LAB：0.35秒高壓窗口原型

2026-11-10。接續 [SURGE A＋B基礎](COMBAT_ESCALATION_RUNTIME.zh-TW.md)，按 [戰鬥優化規格](COMBAT_ESCALATION_PLAN.zh-TW.md) 做獨立比較原型。開發來源仍用 `codex/combat-escalation-next`，不新增使用者要切換的分支。

## 怎樣試

主選單按 **B**，或 HOW TO PLAY 頁面頂部選 **SURGE LAB**。這是明示練習fixture：兩方60能量、SURGE60、近身站位；陪練每120個正常戰鬥步進於第90步提議重踢，距離遠則走近，不讀玩家pending，也不改傷害。

- **K**：雙方地面可行動、近身時提議挑空。若壓力已降到60以下，按 **F5** 重設fixture。
- 窗口內 **J** 確認攻擊、**Shift** 格擋、**E** 後撤。自己的首個有效選擇顯示P1＋LOCK；對方只顯示READY／LOCKED。
- **B**：重設到相同60能量／60壓力，切換BASELINE原流程與WINDOW。此鍵會重設練習，並非中途無代價換招。
- **F5**：保留目前比較模式重試。**Esc** 暫停／恢復，**F2** 減少演出。標準FIGHT與自由AI Demo不繼承原型。

請用同一角色配搭比較兩種流程：你是否更容易讀懂起手？0.35秒是否有足夠時間選擇？停頓有沒有打斷連續交戰？是否比上一輪單純可靠預輸入更有趣？本輪自動測試不回答這些真人問題。

## 實際規則

沿唯一 `pressure_exchange.gd` owner，使用同一0–90 pressure及共用90正常戰鬥步進冷卻。新decision狀態與F8舊clash分開，不套用舊PRESS／TURN／SLIP的直接勝負或傷害。

只有明確啟用的地面練習、pressure≥60、冷卻歸零、雙方idle／無硬直／無已緩衝招式及跳躍、距離在原招式範圍且≤1.8時，對heavy／launcher的起手提議開窗。窗口在招式尚未正式起手前開啟；已進入attack或active frame的動作不會取消，因此沒有新增假動作、active後改判或免費解除受擊硬直。付費技能不會開此窗口。

開啟後的21個固定60Hz決策步進（名義0.35秒）由Simulation處理，不套Rhythm的hold／slow／release倍率。角色狀態、回合時間與既有能量在決策期間凍結，21步到期才交付選擇；雙方提早選好也不提早結算，任何按鍵不重置期限。Esc停止決策步進並保留pending；F2不改期限。窗口內真按鍵走原生輸入handler，UI僅畫出收到的意圖。

兩邊各鎖首選，AI意圖在開窗時按公開時鐘／資源預先決定，第9步提交，不讀任何玩家選擇。雙方同幀提議起手，按共用serial輪替優先歸屬，原始兩方輸入都保留。超時未選者沿用開窗前的原始輸入，包含同一步的防守方攻擊／防禦／移動，不會吞掉另一邊原有提議。

到期僅交回普通commands：起手方J沿用原先heavy／launcher，另一方J是light；Shift是24個非hitstop正常戰鬥步進的有限普通格擋，第一步有guard_pressed；E是一次原生後撤dash。已選格擋不自動刷新完美格擋時機，dash仍受原冷卻及角色資源限制。後續命中、格擋、投技、傷害及反擊成功皆由既有Simulation裁決；沒有新UI勝負表或傷害倍率。到期交付的一步優先於同一步新普通輸入，之後恢復一般操作。

被外部狀態中斷、KO、離開合法距離、關閉原型、重開或退出均取消，沒有補發意圖。pressure不因開窗／選擇增加或歸零，冷卻只在普通戰鬥推進。

## 驗證範圍

[畫面、並排對照片、真按鍵與嚴格log](evidence/surge-window/README.md)。46項新增原型檢查＋30項上一輪SURGE基礎＋250項戰鬥規則回歸＋37項原生UI／音樂回歸，共363項通過；另有桌面實按B/K/E，鎖定evade並在第21步結束。

Linux Godot4.6.3 Compatibility／Mesa llvmpipe／Dummy audio。無ERROR／SCRIPT ERROR；driver的VSync不支援警告保留。對照片是明示fixture及預定按鍵時刻，不是自由AI或真人好玩程度證據。BGM連續性有回歸，實際喇叭／混音峰值、Mac硬件、真人可讀性與手感仍待驗收。

新原型尚未採入正式對戰或Street Run。首分鐘完整教學、一般招式教讀、角色逐招演出及三站敘事仍是後續；先由真人比較可靠預輸入和額外窗口。公開Web未更新。
