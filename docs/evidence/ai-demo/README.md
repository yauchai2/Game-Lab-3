# 雙 AI Demo 證據

[操作與範圍](../../AI_DEMO.md) · [驗證與限制](../../VALIDATION.md)

- `headless/summary.json`：384/384，新 Demo 37 項、兩輪 9,858 tick 真實事件覆蓋與決定性。
- `native/summary.json`：138/138，新 Demo 31 項，原生按鍵／按鈕／完整循環／偏好恢復。
- `native-soak/complete.json`：120.005 秒，僅開始的 2 次按鍵轉換，自動跑完一次循環，43 次真實命中及 1 次 KO。
- `rules-first.*`：首跑 25/37，純決策器未識別 KO 終止狀態，無法進第二輪；修正後通過。
- `captures/`：25 張原生引擎圖；`demo.mp4`／`demo.gif`：180 幀，固定 60Hz，每四 tick 擷取、15fps 的 12 秒無聲片段剪接，非真人錄影。
- `source-manifest.json`：基線、執行檔雜湊及既有模型／圖片／音檔不變。

這是明示預設情境的技巧展示，不是競技 AI 勝率或真人／GPU／實聽驗收；未更新公開 Web。
