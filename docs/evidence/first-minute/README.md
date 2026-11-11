# FIRST MINUTE教學證據

Godot4.6.3 Linux Compatibility／Mesa llvmpipe／640×360 framebuffer／Dummy audio。教學fixture明示100能量、近身站位、SURGE0，不代表標準對局配置。

- [待開始](ready.png)／[連段過關](combo-passed.png)／[反擊過關](counter-passed.png)／[空戰過關](air-passed.png)／[四關完成](complete.png)／[實際起手提示](windup-cue.png)。
- [四關示範MP4](four-lessons.mp4)／[事件報告](demo.json)：自動student只送普通輸入，含真parry、counter_success、homing_chase及hit。約10.35個虛擬wall秒、156幀15fps、無聲；不是自由AI、真人操作或真人首分鐘時間驗收。
- [實際桌面鍵盤結果](real-keys.json)／[真鍵盤過關畫面](real-key-combo.png)：C→Enter→按住J，普通物理時鐘與真正兩擊連段，非凍結時間fixture。只驗收鍵路徑及第一關，不冒稱真人學懂全部四課。
- [63項新檢查](checks.json)：四角×四課完成及真hit、揮空／普通block／起手counter hit／只有parry／只有launcher／只有付費startup／能量不足的反例、機會過期、guard狀態提示、F2／Esc／F5／模式隔離、XP／裝備不變與音樂transport。
- [46項窗口回歸](window-regression.json)／[250項戰鬥回歸](regressions/summary.json)／[37項原生UI及音樂](native-regressions/summary.json)，共396項通過。歷史UI截圖已復原，新畫面另存native-regressions/screens。

最終native.log／window-regression.log／real-keys.log／capture.log及回歸各log無ERROR／SCRIPT ERROR，原生VSync不支援警告保留。最初三連擊課題發現LOOP長推離導致不適合作為首課，已改共通兩擊目標；最初連續空揮未回idle而漏提示，已補新起手前檢查並重跑。最終結果為準。

重現：`godot --headless --path godot --script res://tools/verify_first_minute.gd`。原生移除headless，使用`--rendering-method gl_compatibility --audio-driver Dummy`。`capture_first_minute.gd`是明示自動student；`verify_first_minute_keys.gd`等待真桌面C／Enter／按住J。最終Mac、喇叭混音及真人教學手感仍待驗收。
