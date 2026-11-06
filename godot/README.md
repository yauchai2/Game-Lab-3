# Godot 道具展示專案

驗證版本：Godot 4.6.3。以編輯器開啟 project.godot，匯入後執行 scenes/review.tscn。

六件模型保留來源 GLB；尺寸與簡化碰撞位於 scenes/ 的同名包裝場景。這是資產展示場景，沒有玩家控制器、街道或飛機事件，材質仍是來源 PBR。

從 repo 根目錄可執行：

```sh
godot --headless --editor --path godot --import --quit
godot --headless --path godot --script res://verify.gd
```

最終 toon 畫面、操作手感及 GPU 效能需另行驗收。詳細紀錄見 ../docs/VALIDATION.md。
