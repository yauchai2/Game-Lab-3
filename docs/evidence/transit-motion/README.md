# 四角空地交接證據

[實作與限制](../../FOUR_FIGHTER_TRANSIT_MOTION.zh-TW.md)。Linux Godot4.6.3 Compatibility／llvmpipe／Dummy，非Mac／真人／人耳／GPU效能驗收。

- `checks.json`／`checks.log`：216新項；source／contact owner與原sim字典FX socket、兩朝向、hitstop／F2矩陣凍結、無lunge／身體拉伸／自轉、sim快照不改、八空地phase、受擊重啟、導演排除、真正常輸入launcher/chase/air與grab結算。LOOP pulse姿態測例有一個明示種子node；其他真流程不注入damage。
- `counter`122、`street`90、`rivet`19、`style`51、`rules`46、`death`104、`fx`26共458既有回歸，全通過；合計674。舊motion測試空中／stun／landing從legacy移交到新profile的斷言已明確改名／改預期，未刪減其他檢查。歷史固定輸出已還原，這裡保存本輪副本。
- `strict.log`：12腳本七類fatal warnings通過；`full-strict/`：16/19，同三處story_opening／world_ink_fx／reference_workshop相依警告。
- `trajectory*.json`及log：ec81ad9隔離scripts與新版1800固定simulation tick，同輸入／狀態SHA022cef61…、21命中、0差異／骨架呈現改寫。不是以視窗焦點敏感的Demo wall-loop作等價證明。
- `ground-comparison.json`、`ground-*.json.gz`及log：14個人工狀態fixture×4角×90tick＝5,040筆clip／LeftFoot／RightFoot／RightHand一致。排除本輪有意變動的grab、stun、jump及空擊。不是鞋底／地形IK量測；非LOOP的node_pulse人工狀態不代表合法招式。
- `poses/`：四角八類新姿態、0/8/14/24/55等抽樣PNG與`samples.json.gz`。固定根、人工狀態fixture；不是實戰／逐來源幀藝術驗收，也沒有對手配對摔投。
- `air-combat.mp4`／`air-movie.json`／`air-movie.log`：14秒420幀連續PLAY，四段正常launcher＋按住J＋Space指令；各段一次付費chase與真air_jab／air_kick／meteor，落地後繼續真連段。
- `throws.mp4`／`throw-movie.json`／`throw-movie.log`：8秒240幀連續PLAY，四段正常grab指令、各一次命中。顯示手勢與一次投技結算，不能當完整攻守配對動捕。
- 兩影片每段100能量／固定近身站位練習fixture，無注入傷害、空中位置、sample或node。`*-contact-sheet.png`為2fps全長覆核；`media-summary.json`含duration／hash／非靜音量測，非人耳品質證明。

重跑：先建輸出目錄，以原生Godot執行`res://tools/verify_transit_motion.gd -- OUTPUT/checks.json`。動作抽樣用`capture_fighter_motion.gd -- OUTPUT/poses air_jab,air_kick,air_finisher,meteor,air_counter,grab,jump,stun`。錄影用`capture_transit_combat.gd -- OUTPUT/air-movie.json`，多加末參數`throw`切8秒投技；加`--fixed-fps 30 --write-movie OUTPUT.avi`，再轉H264/AAC。原生UI測試／錄影須逐個跑，保留正常失焦暫停防護。
