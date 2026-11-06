# Game-Lab-3

以 Godot 4 製作風格化低空航道街區。AI 主導製作，使用者透過 Tripo 網頁生成與回傳模型，並提供美術及遊玩回饋。

目前包含六件資產的原型展示庫，以及 S1 街道白盒、四個固定視角與俯視布局。可操作角色、最終 toon 材質及飛機事件仍待製作。

## 接續前先讀

- [協作規範](AGENTS.md)
- [交接與目前狀態](docs/HANDOFF.md)
- [待辦](docs/TODO.md)
- [白盒操作、預覽與重建](docs/WHITEBOX.md)
- [設計基準](docs/DESIGN.md) 與 [下一階段規格](docs/design/next-phase.zh-TW.md)
- [重要決策](docs/DECISIONS.md)
- [驗證結果與限制](docs/VALIDATION.md)
- [資產索引與來源雜湊](assets-manifest.json)

開始修改前確認目前分支、遠端最新提交及工作區變動；不要假設知道其他對話進度。保留現有內容，將重要決策與驗證同步到任務分支。

## 開啟專案

驗證版本為 Godot 4.6.3，以編輯器開啟 `godot/project.godot`，匯入後執行主場景 `scenes/street_whitebox.tscn`，按 `1–5` 或 `Tab` 切換視角。原資產展示仍保留於 `scenes/review.tscn`。

```sh
godot --headless --editor --path godot --import --quit
godot --headless --path godot --script res://verify.gd
```

上述命令驗證匯入和場景載入，不能代替 GPU 畫面、實際遊玩或效能測試。細節見 [Godot 專案說明](godot/README.md)。
