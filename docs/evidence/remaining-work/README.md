# main收尾驗證

[851項逐套結果](summary.json)／[完整實作與仍未完成項](../../REMAINING_WORK_INTEGRATION.zh-TW.md)。最終accepted logs無ERROR／SCRIPT ERROR；gameplay.json為額外1,800tick呈現與規則等價檢查，不重複計入851。

- 新UI與接地測試：`DISPLAY=<可用X顯示器> godot --path godot --rendering-method gl_compatibility --audio-driver Dummy --script res://tools/verify_remaining_integration.gd -- /tmp/remaining-integration`
- strict：`python tools/verify_godot_warnings.py --output /tmp/remaining-strict`
- 其餘suite對應godot/tools/verify_*.gd；將證據輸出指向臨時目錄，避免覆寫歷史截圖。

Linux軟體GPU／Dummy，不是真人、實體手柄／Mac／實聽或FPS驗收。initial保留首次失敗，包括暫存輸出路徑、舊入口／舊音樂等待、裝備取景及接地reach問題；以summary與非initial的最終log為準。Mixamo官方攻守原檔仍未取得，沒有完整配對柔道投技驗收。
