# FIRST MINUTE：四步主動教學與真接觸回饋

2026-11-10。接續 [戰鬥優化規格](COMBAT_ESCALATION_PLAN.zh-TW.md) 的E首分鐘目標，補上C中的起手讀取教學切片。來源仍為 `codex/combat-escalation-next`；標準FIGHT、Street Run、自由AI和獨立SURGE LAB維持各自流程。

## 怎樣試

主選單按 **C**，或按H開HOW TO PLAY，選頂部 **FIRST MINUTE / C - START LESSONS**。按 **Enter／BEGIN** 開始，真正完成後才有 **Enter／NEXT LESSON**。四關是：

1. **小連段**：A／D靠近，按住J，完成同一段中的兩次真命中。四角共通，不要求把LOOP的長擊退硬湊成三連擊；正常傷害、距離、擊退及連段規則不改。
2. **格擋反擊**：看P2正常重踢的實際起手，提示SHIFT NOW時按Shift，真完美格擋後按J。普通擋住或截斷對手起手造成的counter hit，都不能代替這個目標；必須有實際parry和後續counter_success＋hit。
3. **空中追擊**：K挑空真命中 → E付費追擊 → J空中真命中。追擊仍花原20能量；只有挑空／按E／起跳均不過關，需有真homing_chase後的空中接觸。正常Rush本來可按住J自動追擊，該合法路徑也保留。
4. **付費爆發**：W＋L花原75能量，直到overdrive真命中才完成；只有蓄力、起手或揮空均不算。

**F5** 重試本關，保留已完成的前面關卡；重新按C會重新開始四關。**Esc** 暫停保留進度、pending及時鐘，**F2** 減少演出仍可完成全部目標。最後一關完成後Enter回主選單。

FIRST MINUTE是首次體驗目標，不是60秒失敗倒數。可反覆重試，沒有時間上限；結算秒數只統計正在挑戰的wall步進，不含等待下一關及暫停。沒有XP、解鎖、裝備或存檔獎勵，離開教學不保存課程進度。

## Fixture與規則界線

每關開始／明確重試會重設雙方站位X±0.6、健康及能量100、SURGE0、空白戰鬥perks，HUD標明FIXTURE／100 ENERGY／NO XP。選角沿用目前四角色。這是教學配置，不是標準對戰平衡；嘗試中不傳送人物、不自動命中，也不替玩家送出任何攻擊。

`first_minute_coach.gd`只提供陪練普通commands及觀察Simulation事件，不寫fighters、pressure、傷害或成長。連段／追擊／爆發關的對手站立，格擋關的陪練靠近後按150個非hitstop戰鬥步進的節奏，第90步提議一次heavy；不讀玩家pending。命中、格擋、距離、硬直和角色資源全部走既有Simulation。

提示讀對手實際招式startup／frame及玩家合法狀態；只有正面、範圍內、玩家地面idle、無parry冷卻且guard≥25才提示SHIFT NOW。長按防禦超過窗口會提醒放開Shift再抓起手。反擊／追擊機會過期就取消準備提示，避免教玩家追一個已失效的窗口。

揮空、擋住、被招架、被命中、能量不足、追擊距離及落地各有提示；起手與成功分開。過關後可等動作自然收尾，不自動切關或修改勝負；下一關／重試才重建明示fixture。

## 驗證及接續

[實機畫面、四關示範、真鍵盤及log](evidence/first-minute/README.md)：63項新檢查（包括四角×四課普通輸入完成、反例及原生整合）、46項SURGE窗口、250項戰鬥、37項原生UI／音樂，共396項通過；另有桌面真C／Enter／按住J，完成真正兩擊連段。

Linux Godot4.6.3 Compatibility／Mesa llvmpipe／Dummy audio，640×360；最終log無ERROR／SCRIPT ERROR，VSync不支援警告保留。自動student示範不是自由AI或真人學習／爽感證據；Mac硬件、真人首次操作時間及實際混音仍待驗收。

完整C的投技／退步／跳躍情境教讀、D逐角色視聽統一、E三站敘事仍待後續。高壓窗口仍只是B練習原型，未因本輪自動採入正式流程。公開Web未更新。
