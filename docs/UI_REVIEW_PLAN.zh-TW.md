> 2026-11-13 最新：P0–P3程式實作與整合驗證完成，原方案640×360已由使用者後續720p要求覆蓋。見[整合紀錄](REMAINING_WORK_INTEGRATION.zh-TW.md)與851項證據；本機／真人驗收仍待。以下是原始計劃與歷史進度。

# 全遊戲 UI 檢視與精簡計劃（2026-11-11）

狀態：**只有檢視與計劃，runtime 沒有改動**。等使用者審閱後才實作。

使用者要求：「review 所有遊戲 UI，計劃優化（保留現有藝術風格）」，並補充「整體簡潔，可優化掉重複的東西」。所以本計劃的主軸是**刪減與合併**，不是加新東西。Ink 風格（黑白城市、桃紅／青／螢光綠、斜切牌、640×360 統一像素、24／28／32 字級、原生控件）全部保留。

## 檢視範圍與方法

- 基準：`codex/combat-escalation-next` @ 3389fa9。另外檢視 PR #7（`claude/project-thread-oo92do`）與 PR #8（`claude/project-thread-xmgtx2`）帶來的 UI 變化。
- 方法：Godot 4.6.3 Linux，xvfb＋opengl3（llvmpipe），真場景即時運行，用 session 的公開函式切換畫面後截圖，共約 75 張。腳本是 `godot/tools/capture_ui_audit.gd`、`capture_ui_audit2.gd`，可用 `-- --out=<資料夾>` 重跑做前後對照。
- 結算、抽能力、Street Run 通關等畫面用**明示 fixture**（直接把生命設為 0、指定回合數）進入，不是自然對局。
- 截圖合成圖在 [evidence/ui-review-2026-11-11](evidence/ui-review-2026-11-11/)，下文用編號引用。

### 沒有驗證到的東西

- 動態觀感：選單焦點動畫、HUD 動態、過場節奏，只看了靜態幀。
- 聲音、真手柄、鍵盤鬼鍵、Mac、目標 GPU、全螢幕與非 16:9 的整數縮放。
- 雲端沒有音訊裝置，所以標題一直出現「SOUND OFF / RESTORE」；這在使用者電腦上應該不會出現，但我無法確認。
- 繁中介面：現行頁面以英文為主，沒有逐頁檢視中文版。
- PR #7 的基底較舊（4177ef9），它的截圖沒有新版回合開場，只用來看結算頁新增行與開場台詞。

## 一、重複的東西（主要刪減對象）

| # | 位置 | 現況 | 建議 |
| --- | --- | --- | --- |
| A1 | 模式入口 | 同一個 Street Run 有 4 個入口：主選單 STORY（PR #8）、選角頁右側 STREET RUN、選角頁大按鈕（鎖定時變 STORY）、LOADOUT 頁底「START 3-STOP STREET RUN」。同一模式有 3 個名字：STORY／STREET RUN／3-STOP STREET RUN。對戰也有 FIGHT／VERSUS／FREE BATTLE 三個名字。AI DEMO 在主選單、FREE BATTLE 頁、F12 各一次。（圖 01、10、11） | 每個模式一個名字、一個入口：STORY、VERSUS、TRAINING。選角頁只負責選人和 LOADOUT。AI DEMO 依使用者先前決定不上線，先從選單拿走，只留 F12 開發鍵。主選單由 6 項回到 5 項。 |
| A2 | 暫停入口 | 對戰中右上角常駐「II PAUSE」按鈕，壓在 P2 血條下方擋住場景；開場、KO、抽能力的底部提示又寫一次「ESC PAUSE」。（圖 03、05） | 對戰中改成只有圖示的小按鈕（保留滑鼠可點），過場期間隱藏按鈕，只留底部提示。 |
| A3 | 操作提示 | 底部「J RUSH／K LAUNCH／L SKILL／W+L SUPER」整場常駐；HOW TO PLAY、FIRST MINUTE 教學、舊練習的「J Light K Heavy」又各講一次。（圖 03、07） | 提示條只在每場第 1 回合開頭與訓練模式顯示，之後自動收起；設定加一個「操作提示：自動／常開／關閉」。 |
| A4 | HUD 文字 | 「ZIP / ROUTE 0/2」重複角色名（開場已介紹）；SURGE 一格用兩行「SURGE 00／FLOW」加一條色帶講同一件事；左上「NEON FACETS LAB」是開發標籤卻出現在正式對戰；模式標籤（FREE TRAINING、AI DEMO / ROUND 01、FIRST MINUTE…）與它疊在同一角。（圖 03、08、13） | 拿掉開發標籤。角色資源改成能量條旁的小格，不寫名字。SURGE 收成一行。左上只留一個「模式牌」位置。常駐文字元素約 12 個降到 5 個左右。 |
| A5 | 結算頁 | 頁首寫「RESULT」，真正的結果「You win!／Rival wins」卻是小字；下面還有「Run it back.」「FIRST TO TWO」。PR #7 再加 3 到 6 行（勝利台詞、電台、NEW TAG ×N、STYLE／TAGS），把結果擠出可視範圍，這是已知問題。（圖 04、12） | 頁首直接寫結果（YOU WIN／RIVAL WINS／P2 WINS），拿掉「RESULT」與「FIRST TO TWO」。比數放大。風味文字只留一行；多個 NEW TAG 合成「3 NEW TAGS」一行；按鈕固定在捲動區外。這樣順便解決 PR #7 的問題。 |
| A6 | 音訊設定 | 8 個控件講聲音：Mute all、Play music、Music 滑桿、Sound effects 滑桿、狀態文字、TEST SOUND、RESTORE SOUND，加上標題的 SOUND OFF / RESTORE。（圖 02） | 留 Mute all 與兩條滑桿（拉到 0 就是關）。測試、恢復、狀態只在偵測到沒聲時才出現，收成一列。拿掉「Settings are saved on this device」。 |
| A7 | HOW TO PLAY | 約 20 段文字、三種字級和顏色；四個角色說明全列；部分內容已過時（clash 三選、F11 Air lab、Specialist labs）；頂部和底部各有練習入口。PR #8 再加 4 行鍵位，而 FREE BATTLE 頁已經寫過同一份。（圖 02、11） | 改成三塊：一頁看完的按鍵表、只顯示目前所選角色的一段、LESSONS 入口。鍵位說明只留一處。舊練習（F8／F10／F11／SURGE LAB）收進一個 LABS 清單。 |
| A8 | 抽能力 | 「ONE TOKEN. ONE CHANCE.」＋「A RANDOM CORE FOR THE NEXT FIGHT」＋「NEXT ROUND ONLY」＋「NO XP COST / ONE DRAW」四句講同一件事；按鈕寫 SPIN、底部又寫 ENTER / SPACE SPIN。（圖 06） | 每個階段只留一句說明，按鈕與底部提示擇一。 |
| A9 | 標題雜項 | 主選單有「ESC BACK」但無處可返回；「FIGHTERS: XP / SKILLS」小字；選角頁的大字母「Z」純裝飾。（圖 01） | 主選單拿掉 ESC BACK 與小字；大字母位置改放角色名與特性（現在那行被底部提示條切掉）。 |
| A10 | LOADOUT | 按鈕文字用斜線串成一長句「LONG ROUTE / UNLOCK / 1 POINT / LV 1」；頂部三行說明；FREE RESPEC 在結算按鈕與頁內各一次。（圖 01、09） | 技能名在按鈕上，狀態放右側小牌；說明縮成一行。 |

## 二、一致性（不改風格，只收齊）

1. **數字難辨**：display 字體的 0 看起來像 8、6 也像 8。比數「0 — 1」讀成「8 — 1」，血量 63 讀成 83（圖 13、14）。這是最該先修的可讀性問題，建議修 `RadioPixelDisplayReadable` 的數字字形，或數字改用 body 字體。
2. **調色盤外的顏色**：回合開場的角色名用橘色等四色（`round_theatre.gd` 內寫死），HUD 的 P2 資源字也是橘色；抽能力面板是紫／橘／米／薄荷綠，按鈕樣式也不是共用的斜切牌（圖 03、06）。建議 HUD 一律用「邊色」（P1 青、P2 桃紅），角色代表色只留在開場名牌；抽能力保留 3D 場景本身的顏色，只把文字面板和按鈕換回共用 token 與共用按鈕。
3. **按鈕文字寫法**：暫停與結算用「Resume fight」「Next round」，其他頁用全大寫；有些按鈕顯示快捷鍵有些沒有（圖 04、09）。統一為全大寫，快捷鍵只標主要動作。
4. **面板位置**：暫停靠左、結算靠右、設定置中偏右，結算面板下半空白（圖 04）。共用一個面板框與位置。
5. **雙人 HUD（PR #8）**：底部鍵位用最小字塞成一行，很難讀（圖 11）。配合 A3，改為開場短暫顯示。

## 三、檢視時發現的問題

- 從結算頁進 LOADOUT，頁首仍寫「RESULT」（圖 09）。
- 舊練習 F8／F10／F11 的 HUD 文字互相重疊，也壓到底部提示條（圖 07）。
- Street Run 第 1、2 站勝出後的結算頁只有 NEXT STOP 和 SKILLS，沒有離開的選項；對戰 HUD 也沒有顯示目前第幾站（圖 09）。
- 選角頁底部的「ZIP / ROUTE KICKS」被提示條蓋住，BACK 的焦點框壓到按鈕（圖 01）。

## 四、建議做法與次序

每一階段都可以單獨交付、單獨退回；都不需要新美術素材。

| 階段 | 內容 | 主要檔案 |
| --- | --- | --- |
| P0 清理 | 拿掉開發標籤、主選單 ESC BACK 與小字；修 RESULT 頁首錯誤；修數字字形；結算頁重排（含 PR #7 的行數問題） | `fight_hud.gd`、`ui/reference_art.gd`、字體衍生檔 |
| P1 HUD | 暫停改圖示、提示條自動收起、資源小格、SURGE 一行、單一模式牌、舊練習不重疊 | `fight_hud.gd`、`ui/reference_art.gd` |
| P2 選單 | 模式命名與入口合併、主選單 5 項、音訊設定收攏、HOW TO PLAY 重整、FREE BATTLE 頁精簡 | `fight_hud.gd`、`ui/ui_text.gd`、`ui/reference_art.gd` |
| P3 收齊 | 過場文字改用共用色、抽能力面板與按鈕、按鈕寫法、共用面板框 | `cinematic/round_theatre.gd`、`cinematic/ability_draw.gd`、`ui/ui_theme.gd` |

驗證：每階段重跑 `capture_ui_audit*.gd` 做前後對照，並跑既有的 `verify_ink_ui`、`verify_reference_ui`、`verify_readable_ui`、`verify_game_ui`、`verify_focus_flow`；涉及結算與抽能力時加跑 `verify_arena_results`、`verify_ability_draw`。部分舊套件在未改動的基準上本來就有失敗，會先在乾淨 worktree 對照。

與其他 PR 的關係：PR #7、#8 和本計劃都會改 `fight_hud.gd` 與 `reference_art.gd`。建議先等這兩個 PR 定案再開始 P1 之後的階段；P0 的結算頁重排可以直接疊在 PR #7 上。

## 五、需要使用者決定的事

1. 底部操作提示：自動收起（建議），還是保持常駐？
2. 暫停按鈕：縮成圖示（建議），還是完全拿掉只靠 Esc？
3. HUD 顏色：一律用 P1 青／P2 桃紅（建議），還是保留角色代表色？
4. 抽能力：只收齊文字面板和按鈕（建議），還是整段維持現在的獨立配色？
5. 舊練習（F8／F10／F11／SURGE LAB）：收進 LABS 清單（建議），還是直接從正式選單移除？
6. 次序：先做 P0（建議），還是等 PR #7、#8 合併後一次做？

## 六、決定與 P0 進度（2026-11-12）

使用者回覆「全部按建議做」，所以第五節六項都採用建議（提示自動收起、PAUSE 縮圖示、HUD 用 P1 青／P2 桃紅、抽能力只收齊面板與按鈕、舊練習收進 LABS、先做 P0）。

P0 已實作，基準為合併後的 main（ee9e7c0）。合併後 main 已先處理掉開發標籤、PAUSE 縮成圖示與部分 HUD，所以本輪只做仍存在的項目：

- 主選單拿掉無處可返回的 ESC BACK，只留 ENTER SELECT。
- 結算頁頁首直接寫結果（YOU WIN／RIVAL WINS／DRAW／P2 WINS），從結算進 LOADOUT 時頁首寫 LOADOUT；面板內不再重複結果、「Run it back.」與「FIRST TO TWO」。
- 結算風味文字收成兩行：一行台詞，一行「+N NEW TAGS / STYLE … TAGS x / 8」，解決 PR #7 行數多時勝負被擠出的問題。
- display 字體數字改用較高的二值化門檻（只影響 0 至 9），0 不再塞成 8；字體由 `tools/build_radio_pixel_font.py --readable` 重生，只有 `RadioPixelDisplayReadable.png` 變動。
- `verify_local_versus` 改為檢查頁首標題，68/68。

前後對照截圖在 [evidence/ui-p0-2026-11-12](evidence/ui-p0-2026-11-12/)。未做：結算按鈕固定在捲動區外（現在行數少，暫不需要）、P1 之後各階段。已知與本次無關的既有失敗（乾淨 main 上同樣失敗）：verify_reference_ui 37/38、verify_focus_flow 6/7、verify_result_presentation 12/15、verify_readable_ui 的 640x360 檢查、verify_game_ui 在乾淨 main 上逾時。
