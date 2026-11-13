# 城內頁面圖像化（技能／故事／出發）

2026-11-13，依 Alan 要求：「技能頁面、故事選單頁面一堆文字很複雜難明，請優化UI圖像化」。只改城內 Nightshift 的三個頁面與頂部資源列，沒有改任何規則、存檔或戰鬥。

## 改了什麼

| 頁面 | 以前 | 現在 |
|---|---|---|
| SKILLS（RIVET／ZIP…的技能站） | 約 20 行英文段落＋十幾個長按鈕（`LEARN  DOUBLE JUMP / CLEAR 1`） | 一行 L 技能（等級三格＋價錢圖示＋UP）、5 張基本技能卡（圖示＋名字＋LEARN／TRY／STAGE n）、3 張職業技巧卡（EQUIP／ON／FULL／STAGE n） |
| RADIO（故事） | 長對白＋三個角色按鈕＋六個 REVIEW 按鈕＋五行技巧說明＋兩個 PRACTICE | 六章進度條（✓／旗／鎖）、章名、三個說話者頭像、一個對白框、一行任務、五個技巧圖示（打勾＝完成）、兩個 Boss 練習卡 |
| DEPART（出發／地圖） | 文字清單＋小地圖按鈕＋CHANGE HERO 循環鈕＋說明段落 | 六區域卡（✓／鎖／圖釘＋三格進度）、四個英雄卡、一個大 GO；遠征中顯示 HP／能量條、18 格路程、強化／路線選擇卡 |
| 頂部資源列 | 兩行文字 `0 CREDITS 0 PARTS LV1 0 POINTS` | 圖示＋數字：金幣、零件、等級、可用天賦點、HP、第幾關 |

長說明不再佔版面：滑鼠移到（或鍵盤選到）任何卡片，面板底部的一行說明才顯示那張卡的解釋；操作結果（例如 Skill learned）也顯示在同一行。

## 實作

- `scripts/combat/city/ui_icons.gd`：40 個 12×12 像素圖示，全部是程式內的字串點陣圖（無圖片檔、無外部生成），`k` 墨黑邊、`a`／`b` 為可換色。風格沿用粗像素＋硬邊平色。
- `scripts/combat/city/hub_widgets.gd`：卡片、圖示標題、三格進度、能量條、價錢標籤、大按鈕。
- `scripts/combat/city/hub_pages.gd`：三個頁面的版面。`city_hub.gd` 仍然擁有狀態與存檔呼叫，`act()` 不變。
- 每個按鈕帶 `meta "act"`（例如 `learn:double_jump`、`tech:zip_route`、`sector:3`、`contract:12`），舊的原生測試改用它找按鈕，不再靠英文字。
- 面板由 536×464 放大到 620×548（左移），讓三個頁面不用捲動就看到主要動作。
- 沒有動：CIRCUIT 天賦樹、DEALER／SHOP 頁（仍然是舊文字版，下一步可用同一套卡片重做）。

## 驗證

截圖腳本：`xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --path godot --script res://tools/capture_hub_ui.gd -- --out=/tmp/hub/ --rich`（`--rich` 給測試用的金幣／進度）。畫面在 `docs/evidence/hub-picture-ui/`。

通過（Godot 4.6.3，xvfb／llvmpipe）：`verify_campaign_complete_native` 23/23、`verify_city_expansion_native` 22/22、`verify_city_campaign` 50/50、`verify_nightshift_hub` 全部 true。兩個原生測試原本用英文按鈕字或地圖按鈕位置找控制項，已改用 `meta act`。

未驗證：滑鼠／手柄實手感、Mac 與目標 GPU、真人讀起來是否順；圖示由我自己用文字點陣畫，是否符合 Alan 想像待他看過再改。沒有使用 ChatGPT 圖像生成（雲端環境沒有可用的圖像生成工具），改以程式內像素圖示處理。
