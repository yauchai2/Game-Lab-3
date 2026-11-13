# 強像素與清楚階梯鋸齒

使用者要求進一步加強像素及清晰鋸齒。字圖24px→20px，alpha三階→只0／255，移除灰色柔邊。128閾值避免最初96閾值的筆畫膨脹；display額外1來源像素字距，保留粗斜字間隙。1280×720、原字級／布局／nearest及場景無AA保持，繁中fallback未改。

[32項原生檢查通過](summary.json)：Ink10、城市22，無功能斷言修改；最終log無ERROR／SCRIPT ERROR。[字圖alpha檢查](atlas-alpha.json)確定兩張atlas只含0與255。生成器tools/build_subtle_pixel_fonts.py及subtle-pixel-manifest.json同步。舊版證據保持。

[Free Play](verify_ink_ui/free-play.png) · [暫停](verify_ink_ui/pause.png) · [天賦](verify_city_expansion_native/talent-tree.png) · [HUD](verify_ink_ui/hud.png)

PNG是實際1280×720擷取，未後製。Linux Godot4.7.2 Compatibility／Mesa llvmpipe／Dummy audio；非Mac／硬件FPS或真人可讀性評分。此調整作用於共用拉丁字體；未重畫Logo或更改繁中fallback。字圖無柔邊，其他視窗比例仍依既有viewport縮放。
