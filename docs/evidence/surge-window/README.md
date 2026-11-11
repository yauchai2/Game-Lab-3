# SURGE WINDOW 原型證據

Linux Godot4.6.3 Compatibility／Mesa llvmpipe／640×360 framebuffer／Dummy audio。自動化與fixture不代表真人手感或目標Mac驗收。

- [待交付按鍵](window-pending.png)／[已鎖定E](window-locked.png)／[原流程](baseline.png)：明示60能量／60 SURGE fixture，預定按鍵測試與暫停／F2／模式切換。
- [真桌面按鍵結果](real-keys.json)／[真收鍵期間畫面](real-key-window.png)：實際B→K→E，普通物理時鐘未凍結；選擇evade，21個決策步到期。這次不是上一輪凍結時間fixture。
- [原流程／窗口並排片段](baseline-vs-window.mp4)：左BASELINE、右WINDOW，各3秒／45幀15fps；明示相同K於第0步、E於第8步的意圖，經普通規則交付。固定虛擬wall步進擷取，非硬件FPS、自由AI或真人輸入。[事件報告](comparison.json)。上一輪的兩組正常AI各30秒仍見 [SURGE基礎證據](../combat-escalation/README.md)。
- [46項原型檢查](checks.json)：21步期限、同幀首選、超時保留雙方原輸入、無硬直偷跑、範圍／KO／模式隔離、普通格擋及dash冷卻、AI預承諾、3,000步重播一致、Esc／F2／F5／B與輸入路徑。
- [30項基礎回歸](base-checks.json)／[250項戰鬥規則](regressions/summary.json)／[37項原生UI及音樂](native-regressions/summary.json)，總363項通過。

最終native.log／headless.log／real-keys.log／capture.log／base-checks.log及回歸各log無ERROR／SCRIPT ERROR。原生VSync不支援警告可見；原始歷史證據已還原，新UI截圖另存native-regressions/screens。

重現：`godot --headless --path godot --script res://tools/verify_surge_window.gd`；原生移除headless，改用`--rendering-method gl_compatibility --audio-driver Dummy`。`verify_surge_window_keys.gd`等待桌面B/K/E；`capture_surge_window.gd`產出明示比較fixture幀。最終混音實錄／聆聽、目標Mac和真人比較仍待驗收。
