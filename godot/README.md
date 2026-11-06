# Godot 道具展示專案

驗證版本：Godot 4.6.3。以編輯器開啟 project.godot，匯入後執行主場景 scenes/street_walk.tscn。WASD 移動、Space 跳躍、V 切換第一／第三人稱，1–5／Tab 查看固定視角，0 回到角色，R 重設，Esc 釋放游標。原資產展示為 scenes/review.tscn。

六件模型保留來源 GLB；尺寸與簡化碰撞位於 scenes/ 的同名包裝場景。主場景已有街道與四引擎客機白盒；已加入測試玩家控制器，尚無掠過事件，現有道具材質仍是來源 PBR。白盒說明及五張 CPU 預覽見 ../docs/WHITEBOX.md。

從 repo 根目錄可執行：

```sh
godot --headless --editor --path godot --import --quit
godot --headless --path godot --script res://verify.gd
```

最終 toon 畫面、操作手感及 GPU 效能需另行驗收。詳細紀錄見 ../docs/VALIDATION.md。

S2 操作、28 項物理／邏輯檢查及人工試玩範圍見 ../docs/WALK.md。
