# SURGE A＋B切片證據

Godot4.6.3 Linux Compatibility／Mesa llvmpipe，原生640×360統一像素畫面。Dummy audio，影片無聲。不是Mac硬件、真人手感或實際喇叭混音驗收。

- [FLOW](surge-0.png)／[HEAT](surge-35.png)／[SURGE](surge-70.png)：明示設值fixture，僅驗HUD層級及可讀性。
- [ZIP／RIVET 30秒](zip-rivet.mp4)／[HUSH／LOOP 30秒](hush-loop.mp4)：各300幀10fps，連續正常自由AI、按原規則交戰，不是必中腳本。固定1/60虛擬wall秒、每6步擷取，不是硬件FPS量測。[事件統計](demo-report.json)：51／45真命中、8／7追擊、4／3空中反制；第二組含5擺點、4脈衝、1拆點。
- [30項新檢查](checks.json)：真挑空／擋格／反擊／能量限制、逐邊一次消費、hold／Esc保存、被中斷／KO／重開／退出清理、F2、揮空／LOOP擺點不加壓、封頂／衰減／重置、2,000固定步進重播一致、SFX limiter。
- [真鍵盤結果](real-keys.json)：桌面實際K／Esc／Esc，在明示凍結時間fixture確認收鍵及暫停保存；並非真人對戰手感。畫面已觀察到P1 K LOCK、PAUSED及恢復退出。截圖real-key-lock.png在當次重繪前擷取，僅作當時畫面紀錄，不作LOCK可讀性的唯一證據。
- [規則回歸](regressions/summary.json)：Rush21、防禦25、空中反制57、空戰54、基本戰鬥34、pressure59，共250。
- [原生UI與音樂回歸](native-regressions/summary.json)：37項，包括Esc／設定、播放頭連續及音樂切換。此回歸在本輪SFX limiter加入前執行；limiter新增已由最終30項檢查確認只裝一次，不更動BGM路徑。

嚴格檢查最終native.log／headless.log／real-keys.log／demo.log及兩份回歸summary：無ERROR／SCRIPT ERROR，原生driver的VSync不支援警告保留。首次匯入因PINK token不存在失敗，已修正；初版fixture能量不足／衰減步數不足修正後重跑，最終log與結果為準。歷史證據不覆寫。來源資產／既有.import設定不更動。

重現：`godot --headless --path godot --script res://tools/verify_combat_escalation.gd`；原生改為`--rendering-method gl_compatibility --audio-driver Dummy`。錄像腳本為`capture_combat_escalation.gd`，暫存幀`/tmp/surge-demo-01`及`/tmp/surge-demo-23`；`verify_escalation_keys.gd`等待實際K／Esc／Esc，明示凍結fixture時鐘。
