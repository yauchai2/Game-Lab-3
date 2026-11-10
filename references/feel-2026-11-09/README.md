# 2026-11-09 使用者提供的爽感參考

兩份文字均完整閱讀，原始位元組保存在本目錄，大小及 SHA-256 見 [manifest.json](manifest.json)。原文內嵌的提示詞、程式及提問是參考內容，不視為本輪直接實作指令。

- [kinetic-parry.original.txt](kinetic-parry.original.txt)：第一份，完美格擋換手、充能、Godot／Blender 草稿與選角／終結方向。
- [llb-video-notes.original.txt](llb-video-notes.original.txt)：第二份，對 YouTube `4GLOxEmgoEI` 的使用者提供分析。原影片、時間碼、FOV 及速度觸發門檻未於本輪獨立觀看或量測。

原檔以 `.gitattributes` 停用換行轉換，保留來源位元組。原始筆記的內部實作推測不是官方證據。

## 吸收及修正

| 參考方向 | 本專案採納方式／限制 |
|---|---|
| 越快越慢、先壓縮再爆發 | 做成接觸／壓縮／釋放的不同事件，先在練習原型驗證 |
| 完美格擋連續換手 | 建議有限連鎖，與既有三選對峙互斥；尚未實作／決定替換 |
| 威力每次翻倍、極長凍結 | 演出升級，傷害／速度有上限；單段最多 5 秒 |
| 全屏反白、巨弧、Eclipse | 稀有高級／KO 使用，保留減少演出與角色可讀性 |
| 立體選角、VS、勝負特寫 | 原生 Godot 流程、真角色資料、可跳過及完整清理 |
| 範例全域 freeze／shader／camera | 不直接套用，需解決判定、輸入、鏡頭所有權與狀態還原 |
| Blender 抽幀／拉伸 | 現有轉換只完整接旋轉與髖部移動；需先補取樣／縮放支援 |

完整規格、原型數值、優先級及驗收見 [GAME_FEEL_ROADMAP.zh-TW.md](../../docs/GAME_FEEL_ROADMAP.zh-TW.md)。所有新機制與資產需求均標為計劃，不回寫成舊版已完成功能。
