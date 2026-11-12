# 全遊戲720p：包括UI與文字

整個主viewport由960×540提高至1280×720，視窗預設仍1280×720；logical UI同為1280×720，因此文字／原生按鈕／手繪HUD在預設視窗直接1:1渲染，無需先縮成960再放大。保留viewport統一合成、fractional適應其他視窗、nearest、無AA、toon輪廓及既有bitmap字體；字級與操作面積保持。這是提高實際framebuffer，並非只放大視窗或改3D render scale。

主選單動畫及城市SubViewport同步1280×720。選角小卡144×192→192×256，主預覽336×384→448×512。大視窗仍按相同比例放大720p；未宣稱原生4K或重畫bitmap字形／原貼圖。

[總表](summary.json)：70項原生檢查通過，0失敗。整體15、Ink10、城市22及完整故事原生23。只更新舊960解像度斷言，功能斷言保持；歷史證據未覆寫。涵蓋選單／設定popup／四英雄預覽、真mouse點擊／scroll／天賦縮放拖曳、城市解鎖／抽裝保底／合約、核心裝備演出、Boss讀招／死亡貼地／破箱及模式隔離。

Linux Godot4.7.2 Compatibility／Mesa llvmpipe／Dummy audio。最終log無ERROR／SCRIPT ERROR；整體UI runner退出仍有8個ObjectDB leaked警告，未作為本輪已解決問題。未驗Mac／目標硬體FPS；720p像素量比960×540增加約78%，效能需實機覆核。

## 真實遊戲畫面

- [主選單](verify_ink_ui/title.png)
- [四角預覽例](verify_ink_ui/roster0.png)
- [設定](verify_ink_ui/settings.png)
- [城市](verify_city_expansion_native/city.png)
- [天賦／文字](verify_city_expansion_native/talent-tree.png)
- [戰鬥HUD](verify_city_expansion_native/battle-720p.png)
- [巨型Boss](verify_campaign_complete_native/gantry-warning.png)
- [核心裝備演出](verify_campaign_complete_native/core-equip.png)

PNG全部是實際1280×720 viewport擷取，沒有後製放大。測試入口：godot/tools/verify_unified_presentation.gd、verify_ink_ui.gd、verify_city_expansion_native.gd、verify_campaign_complete_native.gd；本輪輸出另放此目錄，保留舊版fixture證據。
