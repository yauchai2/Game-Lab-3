# 下一個 Tripo 候選：港式箱式貨車

建議下一件先生成一輛**靜態、窄車身、白色廂式貨車**，用於重現原照片中的街道車流和貨運氣氛。它是可選候選，不阻塞現有遊走原型，也尚未收到模型。圖片是左前斜角的單車設計，不包含後方視角；單圖重建的背面和車輪需要回傳後檢查。

[下載單輛貨車參考圖](../references/assets/VEH_TRUCK_A01_ref_v001.png)

1. Tripo 網頁使用**單張圖片生成模型**，沿用 **P1.0**，先生成 **1 個**候選；實際扣點與設定以網頁顯示為準。
2. 若可選，設定三角面約 **1,500–2,500** 作為第一次參考；先用 1,500，輪廓不夠再決定調高，不需因小幅面數差而重做。
3. 本階段是停放車輛，**不需拆件、車輪動畫或綁定**。有去光處理可先使用。
4. 匯出 **GLB、1K 貼圖**；若網頁沒有對應選項，可使用可用預設並告訴 AI。將 GLB 傳回聊天，AI 會檢查前後車身與輪組、尺度、貼圖、碰撞及 Godot 使用情況。貨車目標長約 5–6 m，最後依街道尺度和模型比例調整。

參考圖片由 image generation 根據既有 [轎車風格參考](../references/assets/VEH_CAR_A01_ref_v002_3quarter.png) 製作，未使用或輸出第三方廠牌。

原始影像提示詞：

> Create one clean isolated image-to-3D reference for a stylized late-1990s Hong Kong urban delivery box truck: compact cab-over, single rear axle, plain rectangular enclosed cargo box behind the cabin, four wheels total, proportions suitable for narrow old city streets. ONE complete truck in front-left three-quarter view, show the whole vehicle with a modest view of front, driver side and box, front bumper and every wheel positioned logically; pale ivory cab, warm gray/off-white box, dark teal windows, charcoal bumper and black tires, small amber lights, restrained weathering as flat color blocks. Match the attached sedan's stylized low-poly game-asset appearance and color treatment, not its passenger car shape. Neutral diffuse lighting, simple flat very light gray background, no cast shadow touching vehicle, no cargo, no people, no buildings, no scenery, no lettering, no logos, no text, no license plate characters, no collage. The truck is a static background prop, crisp and simple, no extra parts floating.
