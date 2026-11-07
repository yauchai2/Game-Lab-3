# 《Jet Set Radio》與《Bomb Rush Cyberfunk》3D 建模與渲染技術規範

《Jet Set Radio》(JSR) 與《Bomb Rush Cyberfunk》(BRC) 代表的千禧年低多邊形賽璐璐風格（**Y2K Low-Poly Cel-Shading / "Dreamcast Aesthetic"**），其核心在於**「用清晰的幾何切面取代圓滑過渡，用高對比色塊取代寫實光影」**。以下為完整還原此視覺風格的 3D 建模、貼圖與渲染配置清單：

---

## 1. 幾何與面數規格 (Geometry & Polycount Budgets)

此風格不依賴法線貼圖（Normal Map）來偽造細節，所有輪廓轉折都必須由真實的幾何頂點構成。

*   **角色模型面數 (Character Polycount)**：
    *   **原版 JSR (Dreamcast)**：約 **500 – 1,200 Tris**（三角面）。
    *   **現代標準 BRC**：約 **1,500 – 3,500 Tris**。五官通常直接畫在貼圖上，僅保留誇張的大輪廓（如厚底鞋、寬鬆褲管、耳機、背包）的幾何結構。
*   **場景與道具面數 (Environment & Props)**：建築物與街景極度簡化，窗戶、冷氣機、招牌多為簡單的方塊擠出（Extrude）或單面片（Plane），單棟建築約 **200 – 1,000 Tris**。
*   **無細節拓撲 (Silhouette-First Topology)**：不製作平滑倒角（Bevel/Chamfer），所有衣褶、關節、鞋子塊面都用銳利的硬邊幾何體（Boxy Geometry）直接拼插（Intersecting Meshes）或低面數轉折呈現。

---

## 2. 法線與著色組配置 (Normals & Shading Groups)

這是決定模型看起來像「千禧年復古風」還是「廉價現代塑膠感」的最關鍵設定：

*   **硬邊／平面著色 (Flat Shading / Hard Edges)**：
    *   **場景與機械道具**：$100\%$ 使用 **Flat Shading**（Blender 中為 `Shade Flat`），不進行任何法線平滑，讓每個多邊形切面直接反映明確的受光階梯。
    *   **角色模型**：採用 **Auto Smooth + 銳邊標記 (Mark Sharp)**（角度閾值約 $30^\circ\text{–}45^\circ$）。在褲管摺痕、衣領、鞋底邊緣強制斷開法線（Split Normals），產生像折紙或美式塗鴉的硬朗塊面感，避免全身 `Shade Smooth` 導致陰影出現水母般的圓滑漸層。
*   **自訂法線編輯 (Custom Split Normals / Normal Editing)**：角色臉部若不想出現破碎陰影，會將臉部頂點法線統一指向前方或從球體投射（Data Transfer / Normal Thief），確保臉部受光乾淨平整。
*   **無雙面渲染 (Backface Culling)**：全程開啟背面剔除，所有模型維持單面渲染以確保剪影與描邊乾淨。

---

## 3. 貼圖與 UV 技術 (Texturing & UV Mapping)

建築物的窗戶、磚牆、角色的衣服標誌都帶有明顯的銳利像素邊緣與手繪塗鴉質感：

| 配置項目 | 技術術語 | 推薦數值／設定 | 視覺效果說明 |
| :--- | :--- | :--- | :--- |
| **貼圖解析度** | Low-Res Textures | **128x128** 至 **512x512** (最大 1024) | 刻意限制解析度以保留復古像素顆粒感 |
| **紋理過濾** | Texture Filtering | **Point (Nearest Neighbor)** 或 **銳利 Bilinear** | **關閉三線性過濾 (Trilinear) 與各向異性過濾 (Anisotropic)**，防止貼圖被模糊化 |
| **Mipmap 設定** | Mipmapping | **Disabled (關閉)** 或負數 **Mipmap Bias (-1.5)** | 確保遠處建築的窗戶與塗鴉依然保持銳利邊緣，不會糊成一團 |
| **貼圖通道** | Albedo / Base Color Only | **僅使用單張 Color 貼圖** | **嚴禁使用** Normal Map、Roughness、Metallic 等 PBR 貼圖 |
| **色彩空間** | Color Palette Quantization | **Indexed Color (索引色 16/256 色)** | 貼圖輸出前可減色處理，強化色塊分離感 |

*   **像素密度一致化 (Texel Density)**：場景通常維持在 **32 – 64 px/m**，讓近看牆面時能清楚看到像素塊，但整體比例協調。
*   **色盤貼圖與 UV 折疊 (Texture Atlasing & UV Overlapping)**：將多個道具共用一張 256x256 或 512x512 的合併貼圖（Atlas），並大量重疊對稱的 UV、利用 **Trim Sheets（裝飾條紋貼圖）** 拼接鐵軌、欄杆與大樓外牆。
*   **烘焙光影至貼圖 (Baked-in Lighting / Hand-Painted Highlights)**：衣服的皺褶暗部、高光線條、鞋子的結構黑線，有一半是直接用畫筆硬邊畫在貼圖上的（Unlit 細節）。

---

## 4. 頂點色與光影系統 (Vertex Colors & Lighting)

Dreamcast 與 BRC 的場景之所以色彩極度鮮豔且不髒，是因為它們**不使用現代寫實的全域光照（GI）或複雜的 Lightmap**：

*   **頂點色烘焙 (Vertex Color Baking / Vertex Lighting)**：
    *   環境的明暗過渡、角落陰影（Ambient Occlusion）與彩色環境光（如霓虹燈反射、夕陽染紅），直接寫入模型的 **Vertex Color (RGBA)** 頂點屬性中。
    *   由於模型面數低，頂點色會在多邊形之間形成非常有標誌性的**線性插值漸層（Gouraud Shading 感）**。
*   **硬邊投影 (Hard Shadows / Blob Shadows)**：
    *   角色腳下與建築物的落地陰影使用極高銳利度的 **Hard Cascaded Shadow Maps**（關閉 Soft Shadow 模糊），或是傳統的 Stencil Shadow（模板陰影），陰影邊緣如同刀切般俐落，且陰影顏色通常帶有**藍紫色或深青色調**，絕不使用純黑死灰。

---

## 5. 渲染器與 Shader 架構 (Cel-Shading & Outline Shaders)

要實現鮮明的「兩階色塊光影」與「粗細黑邊」，Shader 需配置以下模組：

1.  **階梯光影漫反射 (Stepped Ramp Diffuse / Cel-Shading)**：
    *   計算公式為將 $\mathbf{N} \cdot \mathbf{L}$（法線與光源內積）通過 `Step()` 函數或一張 **1D Color Ramp Texture（設定為 Constant / 恆定階梯，無漸層）**。
    *   通常只分 **2 階（亮面 + 暗面）** 或最多 **3 階（高光 + 亮面 + 暗面）**。
    *   暗面不直接乘以黑色，而是透過 **Shadow Tint（暗部染色）** 混合高飽和度的冷色（如深藍、紫紅、青綠）。
2.  **反向殼描邊 (Inverted Hull Outline)**：
    *   將角色與近景道具模型複製一層，沿著頂點法線向外擠出（Extrude along Vertex Normals），並將面翻轉（Flip Normals / Cull Front），塗上純黑色。
    *   *技巧*：若模型使用了 Hard Edges（斷開法線），直接擠出會導致描邊裂開。因此必須將**平滑後的法線（Smoothed Normals）預先烘焙進 Vertex Color 或 UV2 通道**，讓描邊 Shader 讀取平滑法線來擠出連續不斷裂的黑邊。
3.  **深度與法線後處理描邊 (Screen-Space Depth/Normal Edge Detection)**：
    *   用於遠景建築與地板結構線（使用 Sobel 或 Roberts Cross 算子偵測深度差與法線夾角），確保城市天際線也有漫畫框線感。
4.  **自發光與無光材質 (Unlit / Emissive Elements)**：
    *   天空盒（Skybox）、白雲、塗鴉噴漆（Graffiti）、加速特效、UI 字體全部使用 **Unlit Shader**（不受光照影響，$100\%$ 顯示貼圖原色）。

---

## 6. 網點抖動與動畫特效 (Dithering, Animation & VFX)

*   **網點抖動透明 (Ordered Bayer Dithering / Screen-Space Dither)**：
    *   早期的硬體處理半透明（Alpha Blending）容易出現排序錯誤且效能昂貴，因此 JSR/BRC 在處理「攝影機穿牆透明化（Camera Fade）」、「距離淡出（LOD Fade）」或部分陰影邊緣時，會使用 **4x4 或 8x8 Bayer Matrix Dithering（棋盤格像素鏤空）** 配合 `Alpha Clip / Cutout` 來模擬半透明。
*   **抽幀／定格動畫 (Stepped Animation / Constant Interpolation)**：
    *   雖然遊戲以 60 FPS 流暢運行，但角色的特定街舞、花式特技（Trick Pose）與過場動作會刻意將動畫曲線設為 **Constant（階梯曲線）** 或抽幀（12–15 FPS 感），並在關鍵姿勢（Key Pose）停留數幀以強化張力。
*   **2D 廣告牌與網格特效 (2D Billboards & Mesh VFX)**：
    *   黃色衝擊波、塗鴉噴霧、摩擦火花，皆不使用碎小的現代粒子煙霧，而是使用**低面數錐體／平面網格（Mesh Particles）**搭配高對比、邊緣銳利的 2D 序列幀貼圖（Flipbook）與硬邊 Alpha Clip 裁切。