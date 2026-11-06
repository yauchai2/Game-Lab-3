# JSR / BRC 千禧年低多邊形賽璐璐製作規範

記錄日期：2026-11-06。來源：使用者在本聊天提供的完整風格規範。
用途：後續涉及此風格的建模、貼圖、Shader、動畫與 VFX 工作之參考。
以下數值與技術陳述保留為使用者指定的製作目標，未另行驗證為兩款遊戲的實際內部實作。

## 核心視覺

Y2K Low-Poly Cel-Shading / Dreamcast Aesthetic，以《Jet Set Radio》及《Bomb Rush Cyberfunk》為方向。
「用清晰的幾何切面取代圓滑過渡，用高對比色塊取代寫實光影」。
優先誇張剪影、硬朗切面、鮮明飽和色、銳利像素與漫畫黑邊；避免圓滑塑膠感。

## 1. 幾何與拓撲

- JSR 角色目標：500–1,200 tris；BRC 現代角色目標：1,500–3,500 tris。
- 單棟建築目標：200–1,000 tris。窗戶、冷氣、招牌用方塊擠出或單面片。
- Silhouette-first：輪廓轉折由真實幾何構成，不用 Normal Map 偽造細節。
- 五官以貼圖繪製；厚底鞋、寬鬆褲管、耳機、背包保留誇張幾何。
- 不做平滑倒角；衣褶、關節、鞋子以低面數硬邊或穿插網格表達。

## 2. 法線與著色

- 場景、機械道具：100% Flat Shading。
- 角色：Auto Smooth 約 30°–45° + Mark Sharp；褲管摺痕、衣領、鞋底 Split Normals。
- 避免全身 Shade Smooth 的圓滑陰影。
- 臉部可統一朝前法線，或用球體投射 / Data Transfer / Normal Thief 保持受光整潔。
- 開啟 Backface Culling，模型單面渲染；反向殼描邊另按其剔除需求處理。

## 3. 貼圖與 UV

- 解析度：128×128–512×512，最大 1024。
- 過濾：Point / Nearest Neighbor 或銳利 Bilinear；關閉 Trilinear 與 Anisotropic。
- Mipmap：關閉，或負數 bias（目標 -1.5），保留遠處銳利邊緣。
- 僅 Albedo / Base Color；不用 Normal、Roughness、Metallic 等 PBR 貼圖。
- 可用 Indexed Color 16 / 256 色減色，強化色塊分離。
- Texel density：32–64 px/m。
- 共用 256×256 / 512×512 atlas；重疊對稱 UV，使用 Trim Sheets 拼接鐵軌、欄杆、外牆。
- 衣褶暗部、高光線、鞋子結構黑線以硬邊手繪烘焙入色彩貼圖，作不受光細節。

## 4. 頂點色與光影

- 以 Vertex Color RGBA 儲存環境明暗、AO、霓虹或夕陽染色；保留低面數線性插值的 Gouraud 感。
- 不依賴現代寫實 GI 或複雜 Lightmap。
- Hard Cascaded Shadow Maps（關閉 Soft Shadows）、Stencil Shadow 或 Blob Shadow。
- 陰影輪廓俐落；陰影色用藍紫或深青，避免純黑死灰。

## 5. Cel Shader 與描邊

- N·L 經 step() 或 Constant 1D ramp；通常 2 階（亮 / 暗），最多 3 階（高光 / 亮 / 暗）。
- Shadow Tint 使用高飽和冷色，例如深藍、紫紅、青綠；不直接乘黑。
- 角色與近景道具：Inverted Hull，沿法線外擠，翻面 / Cull Front，純黑材質。
- 為避免硬邊斷法線造成描邊裂縫，預先將平滑法線存入 Vertex Color 或 UV2，描邊 Shader 用此方向外擠。
- 遠景建築、地板結構：Screen-space depth / normal edge detection，Sobel 或 Roberts Cross。
- 天空、白雲、塗鴉、加速特效及 UI 字體：Unlit / Emissive，保留原色。
- 實作時需規劃頂點通道配置，避免頂點色光影與描邊法線資料互相覆蓋。

## 6. 透明、動畫與 VFX

- Camera Fade、LOD Fade、部分陰影邊緣：4×4 或 8×8 Bayer ordered dithering + Alpha Clip / Cutout。
- 遊戲可 60 FPS；特定街舞、特技、過場用 Constant 插值或 12–15 FPS 感，關鍵姿勢停留數幀。
- 衝擊波、噴霧、火花：低面數錐體 / 平面 Mesh Particles、2D Billboards、硬邊 Flipbook + Alpha Clip。
- 避免碎小的現代粒子煙霧；保持高對比、圖形化、銳利邊緣。
