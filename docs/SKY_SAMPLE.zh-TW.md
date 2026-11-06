# 天空樣片

依使用者在聊天中提供的深藍天空與白／淺藍分層積雲圖片，製作了程序天空樣片。圖檔本身未加入 repo；這是對可見參考的原創程序詮釋，並非把原圖匯入遊戲。

主場景預設顯示深藍天空與靜態圖形化雲朵。按 **C** 可在新天空和 S4 原本的青藍色純色背景之間切換；**B** 仍只切換原有材質樣片，**P** 重播飛機。可按 **1**／**2** 查看固定視角、**0** 返回遊走。兩種天空切換時，環境 ambient 參數、玩家鏡頭及 B 的材質模式不變；反射對物體表面可能仍有影響。

天空以 Godot sky shader 沿視線方向計算，雲層不是環形平面，也沒有碰撞。角度差使用週期化計算以處理經度接縫，雲不延伸至極點；已在軟體渲染下測試一次水平環視與指定接縫，目標硬體和其他俯仰角仍需檢查。此版是靜態、簡化的輪廓，雲形、密度、顏色和玩家實際仰視感受待人工回饋，並非最終天空。S1 獨立白盒環境不變。

## 最新雲層與環視檢查

入口上方增加兩朵大小及比例不同的雲，後方安排一朵橫跨角度接縫；現有飛機航路、純色天空切換與場景碰撞未更改。查看[更新後入口](evidence/sky-rotation/01_clouds_entry.png)、[同鏡頭純色對照](evidence/sky-rotation/02_flat_entry.png)及[八個方向的天空拼圖](evidence/sky-rotation/rotation-contact.png)。截圖以高空攝影機隔離天空，拼圖不代表玩家在街上的實際視野。

Godot Compatibility／Mesa llvmpipe 在 640×640、60° FOV、固定仰角條件下擷取 0° 到 360° 每 45°、+180°／−180° 及接縫兩側 ±179.75°。0°／360° 與 ±180° 畫面在此次測試逐像素相同；接縫兩側先按角度差平移 5 像素，比較中央指定區域，約 **0.21% 像素不同**，未對齊時約 1.66%；測試區域含白雲。詳見 [像素結果](evidence/sky-rotation/pixel-verification.json)、[擷取設定](evidence/sky-rotation/captures.json)。這是特定軟體渲染路徑、角度及區域的數值檢查，不保證所有解析度、俯仰角或顯示卡皆無接縫。天空 7 項切換／隔離檢查重跑通過，無額外玩法或硬體效能測量。

重現（需 Pillow、NumPy 與可用圖形顯示）：

```sh
godot --path godot --rendering-method gl_compatibility --audio-driver Dummy --resolution 640x640 --script res://tools/capture_sky_rotation.gd
python3 tools/verify_sky_rotation.py
```

## 初版預覽與驗證（歷史紀錄）

以下畫面由 Godot Compatibility、Xorg dummy 和 Mesa llvmpipe 軟體 OpenGL 擷取，飛機固定在參考位置，並非連續動態影片：

- [入口：分層雲](evidence/sky/01_clouds_entry.png)與[入口：原純色天空](evidence/sky/02_flat_entry.png)，使用相同鏡頭。
- [街道中段](evidence/sky/03_clouds_midstreet.png)、[回望](evidence/sky/04_clouds_reverse.png)。

Godot 4.6.3 headless 的 7 項天空／切換／場景隔離檢查通過；12 項材質、28 項遊走、11 項飛機事件回歸也通過。飛機回歸的退出清理警告仍存在；音效仍未人工試聽。檢查與截圖資訊在 [evidence/sky](evidence/sky/)。這些不代表實體 GPU 效能、真實桌面輸入或使用者美術驗收。

重現邏輯檢查：

```sh
godot --headless --editor --path godot --import --quit
godot --headless --path godot --fixed-fps 60 --audio-driver Dummy --script res://tools/verify_sky.gd
```

`res://tools/capture_sky.gd` 需可用的圖形顯示環境；截圖比較時第一和第二張使用同一相機與飛機固定位置。
