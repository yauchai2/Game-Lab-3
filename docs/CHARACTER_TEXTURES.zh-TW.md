# 圖片天空、角色及低清街景

日期：2026-11-06。遊走主場景 `godot/scenes/street_walk.tscn`；Godot 4.6.3。

## 使用方式

在 GitHub Desktop 選取並 Pull `codex/flight-street-handoff`，用 Godot 開啟 `godot/project.godot` 並執行主場景。預設為專案原創圖片天空，N 在圖片與程序天空切換，C 比較程序雲與純色，O 切換實驗描邊，B 比較材質。WASD 移動、滑鼠轉向、Space 跳躍、V 切換第一／第三人稱，1–5 固定鏡頭、0 回角色、P 重播飛機。

## 參考與資產

- 使用者提供的影片僅抽看約 5.6、31.9、43.2 秒影格，用作高飽和角色、色塊、簡化地面紋理與圖形塗鴉方向；沒有聲稱已完整審看影片或音訊。原始影片未置入 repo；檔名、SHA-256 與取樣記錄在 [integrity.json](evidence/character/integrity.json)。
- 使用者提供 `character-1.glb`，原始檔無修改存為 `assets/CHAR_PLAYER_A01.glb`，SHA-256 與來源一致；1,664 三角面、65 個骨骼、1024×1024 材質、沒有動畫片段。包裝內將高度縮放至約 1.75 m；第一人稱隱藏、第三人稱顯示。`character_pose_driver.gd` 依實際水平速度及空中狀態擺動骨骼，只是暫用步態，沒有正式動畫、腳部 IK、滑板或跑酷。
- 全景 `SKY_BLUE_A01.png` 為前次依使用者參考生成的原創圖片，非使用者早前貼出的單張天空圖；以圖片天空作預設。各角度與接縫仍需在目標硬體檢查。
- `tools/build_environment_textures.py` 以固定亂數產生 128×128 無文字路面、鋪磚及牆面材質，於 14 個主場景網格按世界座標投射；色彩仍由原有材質控制，獨立 S1 不變。
- 側巷原創透明 PNG `godot/assets/art/graffiti_swift_A01.png` 由圖像生成製作：抽象紙飛機／雨燕、青綠珊瑚黃米白深藍、粗黑輪廓、無文字或標誌；Godot 匯入限制為 256×131，沒有碰撞。
- 原照片構圖中的金邊棕色直招牌及交叉支架在遊走場景加強，文字為暫用虛構文字；飛機卡通材質關閉接收陰影以避免自陰影斑點，飛機仍能投影，但機身上的自陰影也會減少。

## 實際輸出與驗證

- [入口構圖](evidence/textured/01_entry.png)、[街道](evidence/textured/02_street_level.png)、[人行道](evidence/textured/04_sidewalk.png)、[側巷塗鴉](evidence/textured/05_alley_mural.png)。
- [角色背面](evidence/character/01_idle_behind.png)、[側面](evidence/character/03_character_side.png)、[臨時步態無聲影片](evidence/character/character_walk_silent.mp4)。影片以實際控制器輸入、固定 60 Hz 模擬及每秒擷取 20 影格生成，非真人操作。
- [角色／貼圖驗證](evidence/character/verification.json)，[其餘回歸報告與日誌](evidence/textured/regression/)。畫面透過 Godot Compatibility／Mesa llvmpipe 軟體渲染，非目標 GPU；實際手感、聲音、效能與最終視覺均待人工驗收。部分舊測試退出時有 ObjectDB 音訊清理警告。
