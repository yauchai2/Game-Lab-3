# S1 街道白盒

本版完成參數化街道量體、四個固定視角與俯視布局，供構圖與尺度審查。此為白盒，尚未完成 S2 步行控制器、S3 toon 材質或 S4 飛機掠過事件。

## 開啟與操作

用 Godot 4.6.3 開啟 `godot/project.godot`，主場景為 `scenes/street_whitebox.tscn`。

- `1`：入口仰角。
- `2`：街道中段。
- `3`：側巷回望。
- `4`：右側人行道看招牌與飛機。
- `5`：俯視布局，隱藏飛機，方便看路寬與道具位置。
- `Tab`：依序切換。

此版本沒有 WASD 行走。既有 `scenes/review.tscn` 保留作六件資產的對照展示。

## 場景內容

- 長 64 m、寬 8 m 的道路；兩側各 2 m 人行道；短側巷、入口橫街及街區地面基底，避免側巷轉角露出天空。
- 4–6 層的冷暖建築量體、大窗面、店面開口及粗略樓層／陽台帶。
- 黃框直立招牌，四個色塊代表字面節奏，並非最終文字。
- 四引擎客機程序白盒，含機身、機翼、尾翼、引擎開口及簡化輪組。靜止姿態用於構圖，沒有航路／事件／聲音。
- 六件已回傳的原始 Tripo 資產，以現有包裝場景放入街區。

來源照片在原聊天可見，但尚未存入 repo；本版是依聊天參考與設計規格轉譯，沒有像素配準或測量還原的驗證。

## 參數與重建

主要參數位於 `godot/config/street_whitebox.json`：道路尺寸、樓高、飛機位置與朝向、招牌，以及五個相機的位置／目標／FOV。地面相機的 FOV 為 Camera3D KEEP_HEIGHT 模式的垂直視角 75°；CPU 預覽採方形畫幅，Godot 視窗為 16:9。

在 repo 根目錄執行：

```sh
godot --headless --editor --path godot --import --quit
godot --headless --path godot --script res://tools/build_street_whitebox.gd
godot --headless --path godot --script res://tools/verify_whitebox.gd
godot --headless --path godot --quit-after 5
```

生成器重建 `street_whitebox.tscn`；不要靠逐件手動搬移來維持白盒。重建時固定視角、道具和地標位置按配置／生成器定義重新生成。大幅調整尺寸後，需重新評估相機與物理取樣位置。驗證腳本目前鎖定本版 64 m／8 m 基準，不代表任意參數組合均已測試。

## 預覽

以下為同一份 Godot 幾何快照在 **Blender Cycles CPU** 的預覽。燈光為 Blender 中的中性預覽配置，不是 Godot GPU 螢幕擷取，也不是最終 toon 外觀。

| 視角 | 預覽 |
|---|---|
| 入口仰角 | [01_entry.png](evidence/whitebox/01_entry.png) |
| 街道中段 | [02_midstreet.png](evidence/whitebox/02_midstreet.png) |
| 側巷回望 | [03_alley.png](evidence/whitebox/03_alley.png) |
| 右側人行道 | [04_sidewalk.png](evidence/whitebox/04_sidewalk.png) |
| 俯視布局 | [05_layout.png](evidence/whitebox/05_layout.png) |

重現預覽：先執行 `verify_whitebox.gd` 匯出幾何至系統暫存目錄，再執行：

```sh
blender --background --python tools/render_whitebox_previews.py
```

預覽工具採 Godot 的相機位置、目標和垂直 FOV；俯視圖隱藏飛機。輸出記錄見 [previews.json](evidence/whitebox/previews.json)。

## 檢查範圍

[verification.json](evidence/whitebox/verification.json) 記錄：六件道具存在、1–5 快捷鍵、Tab 循環切換與相機方向、道路尺寸、四個引擎／開口、251 個 mesh 節點，以及道路／兩側人行道／側巷八個垂直射線取樣命中。主場景無視窗啟動通過，來源 GLB 雜湊維持一致。

這些檢查不等於玩家行走、碰撞手感、GPU 圖像、幀率或任意場景位置均無問題。下一步為使用者構圖回饋及 S2 基本遊走。
