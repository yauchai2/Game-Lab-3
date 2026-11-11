# 故事解鎖、同鍵盤雙人與雙手柄

2026-11-11。回應使用者四項要求中的前三項：遊戲一開始只有故事模式、完成後解鎖自由對戰；同一電腦鍵盤雙打；雙手柄控制。第四項（豐富遊戲的點子）見 [GAME_ENRICHMENT_IDEAS.zh-TW.md](GAME_ENRICHMENT_IDEAS.zh-TW.md)，屬規劃，未實作。

基線 main 738c740，分支 `claude/project-thread-xmgtx2`。驗證與證據見 [evidence/local-versus/README.md](evidence/local-versus/README.md)。

## 已實作

### 1. 故事模式解鎖自由對戰

- 「故事模式」沿用現有 **STREET RUN 三站**（未新增劇情文本或關卡）。主選單第一項改為 **STORY**，直接以目前 P1 角色開始三站。
- 新增第二項 **VERSUS**（自由對戰）。未通關時顯示灰色及 `CLEAR STORY` 標籤，按下只閃標籤和播一聲，不進任何模式。
- **通關條件**：在第三站勝出。前兩站勝出、或第三站落敗都不解鎖。
- **存檔**：旗標 `story_cleared` 寫入既有成長存檔 `user://neon_lab/progression.cfg` 的 `[save]` 區（沿用其 `.tmp`／`.bak` 換檔流程，版本號仍為 1）。舊存檔沒有此鍵即視為未通關，XP／技能不受影響。
- 通關結算畫面顯示 `STORY CLEAR / FREE BATTLE UNLOCKED`，並多一個 **FREE BATTLE** 按鈕直達自由對戰頁。
- 未解鎖時：標題按 Enter（沒有焦點時）開始故事；FIGHTERS 頁的大按鈕由 `FIGHT` 改為 `STORY`。
- 設定頁（僅解鎖後、在標題）有 **RELOCK FREE BATTLE**，只清除旗標、保留 XP，方便重看解鎖流程。

**仍然開放的項目（決策，見 DECISIONS D-LV1）**：TRAINING、首分鐘教學（C）、SURGE LAB（B）、F8／F10／F11 教室、AI DEMO（F12）、設定。理由是它們是教學／觀賞，不是對戰模式；新玩家在故事前仍需要練習入口。若使用者希望連這些也鎖，只需在 `fight_hud.gd` 的主選單回呼與 `fight_session.gd` 的快捷鍵加同一個 `free_battle_unlocked()` 判斷。

### 2. 自由對戰頁（FREE BATTLE）

解鎖後 VERSUS 進入此頁：

- **1P VS CPU**：原本的標準 FIGHT，規則不變。
- **2P LOCAL VERSUS**：兩名真人，同一套正式 Rush 規則、三局兩勝、計時；沒有 CPU、沒有成長加成。角色用 FIGHTERS 頁原有的 P1／P2 選角。
- 顯示已連接手柄數，P1／P2 各一個 **DEVICE** 選項（AUTO／KEYBOARD／GAMEPAD）及當前裝置和按鍵說明。選項存入 `options.cfg`（`p1_device`、`p2_device`）。
- AI DEMO 入口亦放在此頁（主選單與 F12 仍可用）。

### 3. 同一鍵盤雙人

沒有手柄（或兩人都選 KEYBOARD）時鍵盤分左右兩半：

| 動作 | P1（左） | P2（右） | P2 數字鍵盤替代 |
|---|---|---|---|
| 移動／上／下 | A D／W／S | ← →／↑／↓ | — |
| 輕攻擊（按住連段） | F | K | 1 |
| 重攻擊（地面挑空／空中暴扣） | G | L | 2 |
| 爆發技（上＋此鍵＝大招） | R | O | 3 |
| 投技 | T | P | 4 |
| 防禦／精準格擋 | 左 Shift | 右 Shift | 5 |
| 閃避 | E | I | 6 |
| 跳（空中再按二段跳） | Space | ; | 0 |

- 左右 Shift 以 `InputEventKey.location` 區分（Godot 4.3+）。
- 對戰進行中，已綁定的鍵不再觸發全域快捷鍵（例如 O 不會切換場景描邊）。Esc 暫停、F2 等未綁定的系統鍵照常。
- 只有一人用鍵盤時（另一人用手柄），鍵盤玩家使用**完整的單人配置**（WASD／方向鍵、J K L、G、Shift、E、Space）。

### 4. 手柄

以 Xbox 配置命名（Godot 標準映射，PlayStation／Switch 手柄對應同位置按鍵）：

| 動作 | 手柄 |
|---|---|
| 移動／上／下 | 左搖桿或十字鍵 |
| 輕攻擊（按住連段） | X |
| 重攻擊 | Y |
| 爆發技（上＋B＝大招） | B |
| 投技 | LB |
| 防禦／精準格擋 | LT 或 RT |
| 閃避 | RB |
| 跳 | A |
| 暫停／繼續 | Start |
| 選單 | 十字鍵／搖桿移動焦點，A 確認，B 返回 |

- **單人模式**（故事、1P VS CPU、訓練、教學）：鍵盤與**所有**已連接手柄同時控制 P1，隨時可換手，不需設定。
- **雙人 AUTO 分配**：兩支手柄→P1、P2 各一支；一支手柄→給 P2，P1 留在已熟悉的完整鍵盤；沒有手柄→分鍵盤。可用 DEVICE 選項改成 P1 用手柄等。指定 GAMEPAD 但沒有可用手柄時退回鍵盤，頁面顯示 `NO GAMEPAD FOUND`。
- **熱插拔**：對戰中拔走正在使用的手柄會自動暫停，該玩家即時退回鍵盤；另一名玩家的手柄不會被重新分配。插回後自動取回手柄，不需重開。暫停／選單畫面會顯示 `GAMEPAD CONNECTED／DISCONNECTED`。
- 搖桿死區 0.35；上／下修飾（大招、暴扣）門檻 0.55；扳機門檻 0.5。對戰中手柄按鍵不會誤觸有焦點的 UI 按鈕。

## 架構

- `godot/scripts/combat/fight_controls.gd`（新）：唯一的裝置擁有者。只讀輸入事件，維護按住狀態、裝置分配與熱插拔，輸出「哪一方按了哪個動作」。不改任何戰鬥狀態。
- `fight_session.gd`：`_input` 把事件交給 controls；`_press(side, action)` 把動作轉成與原鍵盤完全相同的指令欄位（含 SURGE 窗口、空中反制、對峙三選及預輸入 continuation）；`_device_command` 為裝置玩家組合每步指令。**單人鍵盤的原有輪詢與按鍵處理保持不變**，手柄以 OR 方式併入。
- `fight_simulation.gd` **沒有改動**：它本來就接受兩方指令，雙人對戰只是 `ai_enabled=false` 並傳入 P2 指令。傷害、能量、判定、AI 全部不變。
- `last_service/progression.gd`：多一個 `story_cleared` 旗標。`fight_preferences.gd`：多 `p1_device`／`p2_device`。
- `fight_hud.gd`／`ui/reference_art.gd`：主選單由 5 項變 6 項（STORY、VERSUS、FIGHTERS、TRAINING、SETTINGS、AI DEMO），新增 FREE BATTLE 頁，雙人時底部顯示兩方各自的按鍵列、結算顯示 `P1 WINS／P2 WINS`。文字全部原生繪製，鎖定狀態直接讀存檔旗標。

此輪覆蓋 REFERENCE_UI「僅 5 主選項」：現為 6 項，原因是使用者新要求的模式結構。

## 尚未驗證／已知限制

- **沒有用真實手柄測試**。驗證以注入的 `InputEventJoypadButton／Motion` 和注入的手柄清單進行；實體手柄的按鍵映射、搖桿漂移、扳機行程、藍牙延遲都要在使用者電腦確認。
- **鍵盤鬼鍵（ghosting）**：多數薄膜鍵盤同時按 3–6 鍵會漏鍵，雙人同鍵盤激烈對打時可能出現按了沒反應。這是硬體限制，程式無法修正；建議至少一人用手柄，或使用支援 N-key rollover 的鍵盤。按鍵位置已盡量分散到不同鍵盤矩陣區，但未實測。
- **手感與平衡未驗證**：雙人對戰沿用為人對 CPU 調校的數值；真人互打的節奏、投技／格擋強度、角色平衡都未經真人測試。
- 雙人對戰中，原本只給 P1 的提示（反擊就緒、牆受身 E）暫時隱藏，未為 P2 另做一套；教學與 SURGE LAB 仍為單人。
- macOS 上左右 Shift 的 `location` 及手柄驅動未驗證。公開 Web 試玩版**未更新**；瀏覽器的手柄 API 行為亦未測。
- 故事模式仍是三站連戰，沒有劇情演出；敘事內容見點子文件。
