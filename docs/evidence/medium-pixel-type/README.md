# 中等像素強度文字

依使用者「像素風格可以強返一點」，將上一版28px內文／32px標題字圖調至24px，邊緣透明度由四階改為三階（0、128、255）。比上一版有較明顯像素階梯；保留比最初14／16px粗粒字圖更多的筆畫資訊與字母間隙。1280×720、字級／布局／toon場景、nearest及繁中fallback保持。

同一tools/build_subtle_pixel_fonts.py可重建，manifest已更新。字圖PNG由Godot bitmap-font importer管理（skip獨立texture匯入），字型資料會包含所需atlas。

最終32項原生檢查通過：Ink介面10、城市流程22；[總表](summary.json)。功能斷言沒有改動，Ink額外擷取Free Play。最終log無ERROR／SCRIPT ERROR。Linux Godot4.7.2 Compatibility／Mesa llvmpipe／Dummy audio；非真人可讀性評分／Mac／硬件FPS證明。

[Free Play](verify_ink_ui/free-play.png) · [暫停選單](verify_ink_ui/pause.png) · [天賦文字](verify_city_expansion_native/talent-tree.png) · [設定](verify_ink_ui/settings.png)

全部是原生1280×720擷取，未後製。上一版輕像素證據保留在../clear-type。
