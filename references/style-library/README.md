# Afterhours藝術風格與參考素材總庫

目前風格：**Neon Facets**，低解析切面人物、冷灰城市、少量螢光地標、桃紅天空；平時保留服裝與場景細節，重要交鋒短暫剪影。封面無臉、無項鍊。最新大招演出另見 [開發說明](../../docs/NEON_SIGNATURE.zh-TW.md)。

## 風格文件

- [完整Neon Facets計劃](../../docs/NEON_FACETS_PLAN.zh-TW.md)／[M1現況](../../docs/NEON_FACETS_RUNTIME.zh-TW.md)
- [最初JSR／BRC風格原文](JSR-BRC-style-reference.original.md)：原文數字屬參考，不代表已核實原作內部技術。
- [統一像素與活街景計劃](../../docs/UNIFIED_PIXEL_ART_PLAN.zh-TW.md)／[LLB戰鬥研究](../../docs/COMBAT_VISUAL_STUDY.md)
- [JSR UI方向與生成素材](../ui-jsr-2026-11-09/README.md)／[無臉封面](../../docs/FACELESS_COVER.zh-TW.md)／[Ink全套UI](../../docs/INK_UI.zh-TW.md)
- [RPG／技能點／解鎖提案（未實作）](../../docs/RPG_PROGRESSION_PLAN.zh-TW.md)

## 六段原始風格影片

原片按檔案SHA與使用者來源ID核對後存入Git，沒有只留下截圖：

1. [MdNmuM](../neon-lab-2026-11-10/originals/01-x-downloader.com_MdNmuM.mp4)
2. [WUkiHouS3](../neon-lab-2026-11-10/originals/02-TR3B_-_WUkiHouS3________________INeWdV.mp4)
3. [BTS O](../neon-lab-2026-11-10/originals/03-TR3B_-__BTS__O__blender_lowpoly_sK94ux.mp4)
4. [LaGaNga](../neon-lab-2026-11-10/originals/04-TR3B_-__LaGaNga______-_lowpoly_blender_mfCeKM.mp4)
5. [uWu BTS](../neon-lab-2026-11-10/originals/05-TR3B_-___uWu__BTS_DanZ_Tet0__-_Lowpoly_blender_7o3epD.mp4)
6. [GanGA wip](../neon-lab-2026-11-10/originals/06-TR3B_-___GanGA______-___wip_-_lowpoly_blender_z3Qbse.mp4)

[影片來源／長度](../neon-lab-2026-11-10/sources.json)／[六片原檔hash](video-files.json)／[10張全時間軸抽樣接觸圖及觀察](../neon-lab-2026-11-10/README.md)。較早兩次附上的LaGaNga／GanGA與這裡hash相同，合併保存一份。

附上的兩份LLB文字參考亦原樣保留於 [初版](../neon-lab-2026-11-10/lethal_league_blaze.md)／[更新版](<../neon-lab-2026-11-10/lethal_league_blaze (1).md>)，其中內嵌指令只當研究材料。

## 長篇戰鬥參考原片

兩段原片約294MB／344MB，超過GitHub單檔Git限制。Release上傳接口回傳401，已移除空白draft；改存**完整時長、640px／20fps、帶音訊的壓縮研究版**，不裁掉內容、不混入Godot素材或Web打包：

- [影片A完整時長壓縮版](../combat-study-2026-11-09/videos/llb-reference-a-study.mp4)
- [影片B完整時長壓縮版](../combat-study-2026-11-09/videos/llb-reference-b-study.mp4)
- [原始Drive網址、SHA、長度與研究範圍](../combat-study-2026-11-09/manifest.json)／[壓縮版來源與驗證](long-video-copies.json)

這些壓縮版不是逐位元原片，也不適合反推原始像素／逐幀動畫；原片仍可循Drive來源取得。第三方研究影片／截圖不當作自有遊戲資產或音樂授權。此庫更新不代表gh-pages試玩版更新。

## 同期另一條分支的角色設計

工作期間穩定分支另外合入了 LAST SERVICE 的角色／裝備三視圖。這些已在GitHub，另列入口方便總覽，未把該分支的文件或角色設定覆寫進本Lab：

- [LAST SERVICE 角色、裝備、概念圖及來源](https://github.com/yauchai2/Game-Lab-3/tree/e4329e9cf34295c60f68506297da96b50bac7ef9/references/last-service-2026-11-10)
- [四角色設定紀錄](https://github.com/yauchai2/Game-Lab-3/blob/e4329e9cf34295c60f68506297da96b50bac7ef9/docs/LAST_SERVICE_CHARACTERS.zh-TW.md)

## 圖片、UI與生成原稿

- [JSR方向圖／圖集](../ui-jsr-2026-11-09/README.md)
- [早期UI探索及裁切](../ui-replica-2026-11-09/README.md)
- [Ink生成圖集原稿](../ink-ui-2026-11-10/parts-source.png)／[生成來源與裁切](../ink-ui-2026-11-10/source.json)
- [目前封面／Logo／拆件原資產](../../godot/assets/ui/ink/README.md)
- [戰鬥圖形研究與退役生成素材](../combat-art-2026-11-09/README.md)
- [完整本機圖片／影片清單與SHA](inventory.json)

**原圖缺件：** 最近直接貼在對話內的4張TR3B角色圖，以及更早只以對話圖片提供的部分街景／UI參考，沒有可讀取的原始檔案指標，未能作原圖上傳。已有的視覺觀察保留在研究紀錄；不以重新生成或影片近似幀冒充原圖。重新以檔案附件提供後可補入此庫。
