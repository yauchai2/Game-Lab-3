# 夜班場資產與Tripo策略

目前可玩版本不需要新增Tripo，已有程序幾何、正式英雄與原Tripo NPC／機器。approved-concept.png為本聊天ImageGen概念，非已完成3D。來源人物／場景風格依使用者貼出的角色與城市靜態圖；本輪沒有重新下載或逐幀分析六部影片。

| 組件 | 約尺寸（米） | 製法／可替換範圍 |
|---|---|---|
| 地基／後牆／剖面牆 | 20×13、牆4.6高 | 保持Godot幾何；主要通道及鏡頭不可交給單次生成決定。 |
| DJ閣樓／樓梯 | 高2.1、樓梯長4寬1.65 | 保持可走坡面與獨立踏板，音箱／唱盤可另換外殼。 |
| 工作台／虎鉗 | 台寬4.1、高1 | 程序模型已可用；扳手、抽屜等可逐件替換。 |
| 技能接線台 | 約1.1×0.8×2.2 | 機殼可選配Tripo，按鈕、插槽、亮燈需獨立。 |
| 販售窗口 | 寬2.8、高2.8 | 幾何窗口已可用；未來可獨立生成原創店員。 |
| 抽能力機／蒙面人 | 沿原Tripo模型 | 保留原檔；hub instance使用黑白色階wrapper，不改來源。 |
| 貨梯 | 寬3、高3.4 | 幾何框架／左右活動門已可用，不建議生成整機。 |
| 冷氣／喉管／杯凳 | 少量幾何 | 現成程序模型，無需付費。 |

選配Tripo的通用英文規格：

“Single isolated game prop, front three-quarter view, pure neutral background, low-poly angular Y2K street-game geometry, oversized chunky silhouette, ink-black and off-white flat materials with one cyan OR hot-pink accent, nearest-neighbor pixel decals only, no realistic grunge, no baked lighting, no floating parts, no text, no character, no environment. Real-world dimensions [SPECIFY]. Separate movable components; origin at floor center, Y-up, front +Z. Preserve silhouette at 960x540 isometric game camera.”

先單件、確認正背面／尺寸後再生成。新模型放source/，包裝與shader放derived/，保留雜湊；不用生成圖充當嚴格CAD正投影。整張場景已有nightshift_workshop.glb，可直接導入Blender，不需要再用Tripo重建。
