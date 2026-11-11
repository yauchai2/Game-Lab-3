# 四角色配搭與新 GLB 接入

最新覆蓋：[COMBAT_RHYTHM.md](COMBAT_RHYTHM.md) 已加入真正的停慢快節奏、加長紅幕及甩鏡，角色 4 高度減少 1/3。以下初版時長／全部 2.1 倍的描述為前輪紀錄，以最新文件為準。


2026-11-09。使用者新增 `1.glb`、`3.glb`、`4.glb`，原始位元組保留於 `godot/assets/characters/`；既有角色不替換。這是可操作的基本角色配搭頁，不是整份角色專屬技能／選角演出已完成。

## 怎樣試

GitHub Desktop 拉取 **codex/street-combat**，Godot 4.6.3 匯入 `godot/project.godot`、F5。主選單點 **角色配搭**，分別選「你的角色」和「對手角色」，右邊會即時預覽；選擇會保存。可選同角色對戰。預設為原角色對角色 1。

點街頭對戰或返回主選單：Enter 對戰、T 練習、F12 無限 AI Demo 都使用所選配搭。戰鬥中不更換模型；返回主選單再選。J／K／L 和友善格擋等操作見 [Rush 主玩法](RUSH_REWORK.md)。探索場景仍用原角色。

[角色 4 對角色 3](evidence/character-roster/01_fighter_4_vs_3.png) · [角色 1 對角色 3](evidence/character-roster/02_fighter_1_vs_3.png) · [新角色紅幕 KO](evidence/character-roster/03_new_fighter_ko.png) · [新配搭 AI Demo](evidence/character-roster/04_demo_pair.png)

## 來源與適配

| 選項 | 原檔 | 保存模型 | 三角面 | 骨骼 | 內嵌動畫 |
|---|---|---|---:|---:|---:|
| 原角色 | 先前 character-1.glb | CHAR_PLAYER_A01.glb | 1,664 | 65 | 0 |
| 角色 1 | 本輪 1.glb | CHAR_FIGHTER_1.glb | 1,502 | 65 | 0 |
| 角色 3 | 本輪 3.glb | CHAR_FIGHTER_3.glb | 1,535 | 65 | 0 |
| 角色 4 | 本輪 4.glb | CHAR_FIGHTER_4.glb | 1,548 | 65 | 0 |

三個新檔皆一件網格、一個材質、1024×1024 內嵌 Base Color、Mixamo 骨架，模型局部高度約 1m。戰鬥包裝沿用 2.1 倍縮放、現有 toon／描邊材質、陣營顏色及程序姿態；不改來源 GLB。Godot 匯入自動抽出的 JPG 是原內嵌貼圖，與 GLB 一起保存。

動作沿用既有 CC0 Quaternius 重定向與程序疊加，已接起地空連段、巨拳腳、追擊和 KO。**目前四位共用招式、判定及能力**，新 GLB 並不包含新招式動畫。暫依原檔編號命名，不代替使用者決定正式名字／人設。

[來源、檔案識別與 SHA-256](../references/characters/uploads-2026-11-09.json)／[總資產索引](../assets-manifest.json)。使用 Game Asset Production 的檢查準則，但環境沒有 `game-dev` CLI，未執行其 canonical package 流程或宣稱有該工具 receipt；改以本專案既有 Python 靜態檢查與 Godot 匯入接入。未呼叫生成服務、安裝軟體或付費。

## 驗證與限制

[完整記錄](VALIDATION.md)：四角色骨架／重定向、非退化骨矩陣、雙手判定幀放大及 F2 復原；三個新角色各實際完成一輪空連 KO。選單回呼、雙語／三視窗尺寸、配搭沿用到 Demo、保存／非法編號限制及反覆換角清理皆通過。已檢視原生角色預覽、交戰與紅幕 KO 圖；不是只做無視窗載入。

原生測試使用固定步進／注入輸入、Compatibility／Mesa llvmpipe／Dummy 音訊；未冒稱真人手感、目標 GPU 或使用者電腦驗收。角色專用招式、正式名字、選角頭像與完整 VS 過場仍待後續；無需重新生成模型。只更新來源分支，公開 Web 未更新。
