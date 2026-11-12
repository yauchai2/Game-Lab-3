# 夜班場實際引擎驗證

final.json：211項行為／原生／既有回歸全數通過；city-strict.log另14項fatal-warning編譯通過，共225項。accepted logs無ERROR／SCRIPT ERROR。

- 01-in-game.png：正式STORY回城UI，非概念圖。
- 02-map.png：相同SubViewport的乾淨場景擷取。
- 03-shop.png：靠近商店按E後的實際頁面。
- regression/：新據點30、既有完整戰役原生23、城市原生22、完整戰役規則50、城市成長規則86的JSON／log。
- city-strict.log：原有12腳本加workshop／preview兩個新腳本；四類警告視為錯誤。

Linux Godot4.6.3 Compatibility／Mesa llvmpipe／Dummy；保留VSync不支援警告。不是使用者Mac、真人操作／平衡、硬體FPS或音效裝置驗收。

initial-attempts保留失敗：初版路徑在轉彎時過早跳下一導航點，卡在樓梯邊；已改為到達精確節點並給欄杆留身位。快速關面板有deferred grab_focus，改為WeakRef與inside-tree檢查。舊戰役fixture仍點fight（最新主選單已改為鎖定VERSUS），更正為story；站點增加實際行走後，原生測試需等待抵達及完成排版再點擊。指標事件改用root viewport局部座標，避免依賴OS視窗位置。初次錯誤與中止不計入通過，最終已重跑。後續未更改戰鬥數值、交易或存檔schema來迎合fixture。

重跑：設定可用DISPLAY／XAUTHORITY後，`python tools/verify_nightshift.py`；編譯`python tools/verify_city_compile.py --output docs/evidence/nightshift-hub/city-strict.log`。runner保留既有歷史報告、畫面與存檔路徑隔離，且報告必須本次寫入、引擎無ERROR才算成功。自動對話／購物funding fixture並非自然遊玩證明。
