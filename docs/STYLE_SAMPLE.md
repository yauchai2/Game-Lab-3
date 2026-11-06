# S3 街道風格樣片

入口附近約 14–16 m 的左右主立面、直立招牌、消防栓和廂型車是本次樣片。其餘街段及飛機仍維持白盒；沒有覆寫原始 GLB、S1 白盒場景或六件道具包裝場景。

## 查看與比較

以 Godot 4.6.3 開啟 `godot/project.godot` 並執行主場景。原有遊走與固定視角操作不變；按 **B** 循環切換：

1. 原始材質：保留樣片新增幾何與相同的測試光照。
2. 兩段明暗：預設模式。
3. 三段明暗。

B 只改變樣片指定的材質，不切換幾何、鏡頭或光照。遊走與固定視角均可切換。為了不混淆比較，三種模式都使用新招牌文字及相同裝飾；單獨執行 S1 `street_whitebox.tscn` 則保留原白盒。

- [原始材質](evidence/style/01_original.png)
- [兩段明暗](evidence/style/02_two_bands.png)
- [三段明暗](evidence/style/03_three_bands.png)
- 消防栓近景：[兩段](evidence/style/05_two_detail.png)／[三段](evidence/style/06_three_detail.png)

以上均為 **Godot 4.6.3 Compatibility renderer 實際擷取**，以 Xorg dummy 顯示及 Mesa llvmpipe 軟體 OpenGL 4.5 執行，800×800；不代表硬體 GPU 效能。比較圖暫時隱藏測試角色和操作文字，遊戲場景本身仍正常顯示角色與介面。兩段與三段在目前大平面立面上差異較小，曲面和局部陰影較容易看出；尚未視為最終風格決策。

## 實作內容

- 右側主立面加入欄杆、球燈、遮雨棚及店面色塊；左側加入遮雨棚、冷氣、管線和小招牌。細節集中於入口近處，不增加角色路徑的實體碰撞。
- 主招牌使用原創「高空航道」字面。透過系統字型後備顯示，未隨專案打包字型；不同電腦若缺字型可能有顯示差異。
- 受光測試涵蓋左右前景立面、主招牌、消防栓與廂型車，共 56 個 mesh 材質覆寫。`sample_toon.gdshader` 支援原貼圖、兩／三段光照與引擎投影衰減；來源道具原有雙面設定以 shader 變體保留。
- 其他街段、飛機及小型裝飾使用既有／簡單材質；不是全場完成的 toon 方案。來源 GLB 保持不變。
- 測試場景獨立複製環境資源並降低測試光照，讓路面及道具高光更容易辨識；S1 白盒場景的環境設定保持原狀。

## 驗證與重現

- 12 項 headless 結構與切換檢查通過，涵蓋材質還原、B 鍵循環、兩件來源貼圖、雙面設定、固定幾何與角色控制。
- S2 的 28 項遊走物理／邏輯檢查及六件來源資產檢查再次通過；原始 GLB SHA-256 不變。
- 以實際 Godot 軟體渲染同一入口視角，關閉投影作控制組：橘色立面區域有 90,708 個像素出現超過 8 階的差異。兩／三段的入口視角有 41,484 個像素差異超過 5 階。這是本次截圖條件下的影像檢查，不是 FPS 或硬體 GPU 測量。
- 紀錄：[結構檢查](evidence/style/verification.json)、[擷取環境](evidence/style/captures.json)、[像素比較](evidence/style/pixel_comparison.json)；原始文字紀錄見 evidence/style/*.log。

```sh
godot --headless --editor --path godot --import --quit
godot --headless --path godot --script res://tools/verify_style.gd
godot --headless --path godot --fixed-fps 60 --script res://tools/verify_walk.gd
# 需有可用桌面顯示；此命令不使用 --headless
godot --path godot --rendering-method gl_compatibility --resolution 800x800 --script res://tools/capture_style.gd
# 可選的截圖比較，需 Python Pillow
python tools/verify_style_pixels.py
```

目前未驗證：目標電腦的 GPU／幀率、真實桌面游標與人工遊玩手感、不同平台的中文字型，以及最終 toon 藝術方向。飛機仍靜止，下一階段才處理掠過事件。
