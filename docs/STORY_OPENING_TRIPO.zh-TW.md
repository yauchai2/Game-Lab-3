# 開場動畫：Tripo3D 資產清單（對照參考影片 03e5fa13）

最後更新：2026-11-12。狀態：**清單與提示詞已備；尚未有 Tripo 新資產，runtime 仍用程序低模。**

## 先說清楚

- 我（Claude）這邊沒有圖片生成工具，**無法替你用 ChatGPT Image 出圖**。
- 替代做法：我已從你的參考影片裁出每件物件的原圖，放在 `/mnt/project-files/story-opening/tripo-refs/`（檔名見下表）。你可以：
  1. 直接把裁圖丟進 Tripo（Image to 3D）；或
  2. 把裁圖和下面的「ChatGPT Image 提示詞」一起給 ChatGPT，叫它生成「單物件、純色背景、三視圖」再丟 Tripo（較乾淨，推薦用於 B 級以上）。
- 所有招牌、海報、紙張、箱蓋一律**無文字**（AGENTS 規範）。箱蓋上的 AFTERHOURS 字樣由我在 Godot 用貼圖疊上，不要烘進模型。
- 原始 GLB 不會被改動；新模型一律放 `godot/assets/story_opening/`，用包裝場景接入。

## 優先級

- **A（強烈建議，影片很顯眼）**：A1 手提箱（含泡棉槍位）、A2 沙發、A3 工作台。
- **B（有就明顯提升）**：B1 層架＋瓶罐、B2 洞洞板＋工具、B3 收音機/Boombox、B4 抽屜櫃。
- **C（可選，我可先用程序做）**：C1 紅綠燈、C2 街邊霓虹/遮陽篷、C3 紅色小車、C4 牆上風扇。

我已**不需要** Tripo 的項目（程序處理）：光管、貼紙牆（程序貼圖）、粉紅星芒海報（貼圖）、紙張/電線/雜物、鐵捲門、路面、行人、路障柱、斑馬線。

## 清單

統一規格：單一物件、置中、純灰色背景、低多邊形風格（與現有角色相近的 flat/toon 造型）、不要文字或商標、不要地面。匯出 GLB、Y-up、單位約為真實公尺。

| # | 物件 | 參考裁圖 | 建議尺寸 | 優先 |
|---|---|---|---|---|
| A1 | 黑色航空手提箱（蓋合上，含鎖扣、角件） | `flight_case_closed.png`、`case_lid_afterhours.png` | 1.5×0.2×0.78 m | A |
| A1b | 同箱打開：內襯泡棉挖槽，放兩把槍（消音衝鋒槍＋小型衝鋒槍）、橙色彈匣、文件夾板 | `flight_case_open_top.png`、`flight_case_opening.png` | 同上 | A |
| A2 | 棕色格紋皮沙發（扶手有補丁），旁邊小桌 | `sofa_cup_bowl.png` | 2.3×0.9×1.1 m | A |
| A2b | 紙杯（插著筷子）＋煙灰缸/小碗 | `sofa_cup_bowl.png` | 杯 0.1×0.15 m | A |
| A3 | 生鏽金屬工作台（桌面斑駁鐵鏽） | `table_and_street.png` | 2.6×0.9×1.25 m | A |
| B1 | 鐵層架（左牆），放玻璃瓶、罐子、工具盒 | `left_shelf_bottles.png` | 1.0×3.5×0.5 m | B |
| B2 | 洞洞板＋掛鉤＋彩色工具（扳手、鉗、鑽） | `pegboard_shelf_boombox.png` | 4.6×2.2×0.1 m | B |
| B3 | Boombox 收音機 | `pegboard_shelf_boombox.png` | 0.6×0.3×0.25 m | B |
| B4 | 金屬抽屜櫃 | `garage_interior_wide.png` | 0.9×1.2×0.5 m | B |
| C1 | 路口紅綠燈（含燈桿） | `street_view_from_garage.png` | 高 5 m | C |
| C2 | 街邊洋紅遮陽篷小店門面 | `street_view_from_garage.png` | 8×4×2 m | C |
| C3 | 紅色小轎車（低模） | `street_view_from_garage.png` | 4×1.5×1.4 m | C |
| C4 | 工業抽風扇（牆掛） | `garage_interior_wide.png` | 直徑 1.2 m | C |

## ChatGPT Image 提示詞（每項一條，附上對應裁圖作風格參考）

通用前綴（風格見 `docs/LOWPOLY_STYLE.zh-TW.md`，背景一律純白）：「chunky Blender low-poly game prop in PS1/Y2K indie style, very few large flat faceted polygons, hard angular silhouette, pixelated 16-bit texture details, soft vertex-colour gradient shading, single object centered on pure solid white (#FFFFFF) background, no floor, no cast shadow, front/side/top three-view orthographic turnaround, no text, no logos, no ground」

- **A1**：`…, black aluminium flight case with silver corner guards and two metal latches on the front, closed, slightly scuffed, rectangular 1.5 x 0.78 m`
- **A1b**：`…, same black flight case opened, lid up, interior filled with black cut-out foam holding one suppressed submachine gun, one compact submachine gun, three orange magazines and a blank clipboard sheet`
- **A2**：`…, worn brown checkered leather two-seat sofa with patched armrest, low-poly pixel quilt pattern, a small side table holding a paper cup with chopsticks and a small dark bowl`
- **A3**：`…, heavy rusty steel workbench, mottled orange-brown rust top, black steel legs and lower shelf`
- **B1**：`…, four-level grey metal shelving unit with glass bottles, jars and small toolboxes in muted green, amber and red`
- **B2**：`…, black pegboard panel with hooks holding colourful hand tools (wrenches, pliers, cordless drill) in cyan, magenta, orange and silver`
- **B3**：`…, chunky retro boombox with twin speaker cones and a cassette deck, dark grey with one cyan accent`
- **B4**：`…, grey metal workshop drawer cabinet, six drawers, scuffed paint`
- **C1**：`…, city traffic light pole with two signal heads, one showing red, dark grey metal`
- **C2**：`…, small street shop front with a magenta awning and a blank illuminated sign box, shutter half open`
- **C3**：`…, boxy small red hatchback, simplified low-poly, tinted windows`
- **C4**：`…, industrial wall exhaust fan with round grille, dark steel`

## Tripo 設定建議

- Image to 3D、**不要**選 PBR 貼圖過重的高模；面數 3k–15k 足夠。
- A1b 若 Tripo 把泡棉與槍黏成一體也可以：我會用包裝場景＋獨立蓋子（蓋子請另生一個「箱蓋」模型，鉸鍊在後緣）。最省事做法：**箱身（含泡棉槍位）與箱蓋分兩次生成**。
- 生成後把 GLB 放到 repo 的 `godot/assets/story_opening/` 並 Push，或直接上傳給我，我來接入、縮放、換材質、保留原檔。

## 現況與對照

詳細逐鏡差異與已改動項目見 `docs/STORY_OPENING.zh-TW.md` 的「對照參考影片 v4」節。
