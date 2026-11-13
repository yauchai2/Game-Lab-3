# 字體設定：像素5／硬度8／大小100%

使用者已接受這組數值。實際設定在godot/assets/fonts/pixel-type-preset.json，tools/build_subtle_pixel_fonts.py直接讀取，manifest記錄同一組參數。

- 像素強度5：字圖24px，比之前強度約7的20px字圖細緻。相對尺度固定為字圖尺寸round(34−2×強度)，例如3→28、5→24、7→20。
- 邊緣硬度8：alpha為80%二值輪廓＋20%原字形coverage；二值閾值128。10為完全二值，0保留原coverage。8仍偏硬邊，但比完全二值多少量邊緣過渡。
- 文字大小100%：原UI字級及布局完全保持。數值保存在設定檔；其他文字百分比仍需配合UI布局審核，生成器目前會拒絕非100值，避免默默改字而破壞排版。

這是本專案方便溝通的相對美術尺度，不是標準畫質測量或已加入遊戲內的滑桿。作用於共用拉丁字體；原繁中fallback、Logo及場景無AA保持，整體1280×720／nearest保持。

[32項原生檢查通過](summary.json)：Ink10、城市22，功能斷言未改，最終log無ERROR／SCRIPT ERROR。舊證據保持。

[暫停選單](verify_ink_ui/pause.png) · [Free Play](verify_ink_ui/free-play.png) · [天賦](verify_city_expansion_native/talent-tree.png) · [HUD](verify_ink_ui/hud.png)

全部是原生1280×720擷取、未後製。Linux Godot4.7.2 Compatibility／Mesa llvmpipe／Dummy audio；未宣稱真人可讀性評分、Mac／硬件FPS驗證。
