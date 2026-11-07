# Godot 道具展示專案

驗證版本：Godot 4.6.3。以編輯器開啟 project.godot，匯入後執行主場景 scenes/street_walk.tscn。WASD 移動、Space 跳躍、V 切換第一／第三人稱，1–5／Tab 查看固定視角，0 回到角色，R 重設，P 重播飛機，C 比較純色與程序天空，N 比較預設圖片天空與程序天空，O 開關描邊，Esc 釋放游標。原資產展示為 scenes/review.tscn。

八件模型保留來源 GLB（資產展示場景仍為原六件，轎車和貨車已加入遊走主場景）；尺寸與簡化碰撞位於 scenes/ 的同名包裝場景。主場景已有街道與四引擎客機白盒；已加入測試玩家控制器，已加入掠過事件及合成測試音；入口樣片支援可逆卡通明暗。白盒說明及五張 CPU 預覽見 ../docs/WHITEBOX.md。

從 repo 根目錄可執行：

```sh
godot --headless --editor --path godot --import --quit
godot --headless --path godot --script res://verify.gd
```

最終 toon 畫面、操作手感及 GPU 效能需另行驗收。詳細紀錄見 ../docs/VALIDATION.md。

S2 操作、28 項物理／邏輯檢查及人工試玩範圍見 ../docs/WALK.md。

S4 飛機事件、截圖與驗證範圍見 ../docs/FLYBY.md。

S3 入口風格樣片按 B 比較原始材質、兩段與三段明暗；細節與 Godot 軟體渲染結果見 ../docs/STYLE_SAMPLE.md。

可切換的程序天空與驗證見 ../docs/SKY_SAMPLE.zh-TW.md。

港式街景細節、飛機動態及繪製批次測量見 ../docs/STREET_POLISH.zh-TW.md。

使用者角色以暫用程序步態顯示；角色 GLB 沒有動畫片段。細節與局限見 ../docs/CHARACTER_TEXTURES.zh-TW.md。
