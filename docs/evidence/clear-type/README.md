# 可讀的輕像素文字

使用者指出720p仍有粗大／黏連文字，並澄清要保留像素風、減輕強度。原因是原RadioPixelBodyReadable／DisplayReadable只用14／16px字圖、二值alpha，放大後資訊不足。提高viewport沒有解決這項字形限制。

本輪改用新的RadioSubtleBody28px／Display32px字圖，以四階alpha（0、85、170、255）保留小空隙；nearest仍在，粗斜Barlow display／DejaVu粗體內文的風格保持，並非全面改成平滑字。1280×720、原布局／字級／按鈕區域、場景toon／輪廓保持。大標題也使用新display，不再暗中用舊24px字圖。

RadioBody／RadioDisplay.tres包裝字體與打包的AfterhoursUIHK繁中fallback；fallback使用MSDF避免再放大細小中文字圖。舊bitmap、TTF與字體授權原檔保持，字圖由tools/build_subtle_pixel_fonts.py重建；新manifest在godot/assets/fonts/subtle-pixel-manifest.json。未重畫遊戲Logo／舊貼圖。

## 最終證據

[70項原生檢查全部通過](summary.json)：Ink10、整體15、城市22、完整故事原生23。現有runner的功能斷言全部保持；Ink額外擷取Free Play頁面供對照。最終log無ERROR／SCRIPT ERROR。原歷史證據未覆蓋。

- [Free Play：FIGHT／SQUAD／AI DEMO](verify_ink_ui/free-play.png)
- [暫停：Resume fight／Settings／How to play](verify_ink_ui/pause.png)
- [主選單](verify_ink_ui/title.png)
- [設定與內文](verify_ink_ui/settings.png)
- [天賦詳情](verify_city_expansion_native/talent-tree.png)
- [戰鬥HUD](verify_ink_ui/hud.png)
- [城市工坊](verify_campaign_complete_native/workshop.png)

全部是原生1280×720實際渲染、無後製。Godot4.7.2／Linux Compatibility／Mesa llvmpipe／Dummy audio。未宣稱真人可讀性評分、Mac／硬件FPS驗收。像素感的強弱仍有主觀差異，這版保留較細緻像素邊而非舊粗大顆粒。
