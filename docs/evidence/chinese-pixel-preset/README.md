# 中文也使用像素5／硬度8／大小100%

之前中文經RadioBody／RadioDisplay的向量字體fallback渲染，所以只有拉丁字體有像素效果。本輪新增RadioPixelChinese bitmap，RadioChinese.tres同時供正文、標題、開場字幕及3D中文字牌使用；3D Label亦指定nearest取樣，避免材質再次柔化。

字圖與拉丁字體讀同一pixel-type-preset.json：強度5→24px格，硬度8→80%二值輪廓＋20%原coverage；不更改任何UI字級／全域縮放，繁中字元進位寬度亦保持。字圖含918個非ASCII字形，涵蓋目前繁中catalog；原向量字體保留為有授權的建置來源，不再充當產品中文的平滑fallback。兩張拉丁字圖與兩個.fnt位元組保持相同。

tools/subset_ui_font.py現在自動接續tools/build_subtle_pixel_fonts.py，新增翻譯後須執行此完整流程以補字，避免點陣字圖落後於catalog。原Noto CJK OFL授權／來源與hash保持，未新增外部字體來源。

## 驗證

[72項通過](summary.json)：語言／實際中文bitmap／字寬／3D取樣21、原生10、strict23、英文Ink10、atlas4、匯出PCK4。字圖證明見[atlas.json](atlas.json)：三款字體同5／8／100、中文字格24px、透明度只在0–25或230–255、拉丁四檔SHA不變。原生涵蓋繁中切換／保存、城市六站／天賦／故事／暫停；後期頁面使用明示進度／資金fixture，PopupMenu採語意啟動。

PCK從/tmp獨立載入，確認繁中文字形為bitmap且非MSDF，翻譯／格式數值正常。沒有部署Web。最終accepted log無ERROR／SCRIPT ERROR；舊traditional-chinese證據保留。

[主選單](title-zh.png) · [故事](story-zh.png) · [設定](settings-zh.png) · [天賦](talent-zh.png) · [切回英文](title-en.png)

PNG為原生1280×720，未後製。Godot4.7.2 Linux Compatibility／Mesa llvmpipe／Dummy音訊；非Mac／實機FPS／真人可讀性評分。像素尺度仍是本專案相對美術設定。
