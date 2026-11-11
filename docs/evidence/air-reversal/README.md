# 空中反制證據

功能與規則：[AIR_REVERSAL.md](../../AIR_REVERSAL.md)。驗證範圍與失敗修正：[VALIDATION.md](../../VALIDATION.md)。

- `final-headless/summary.json`：427/427；`final-native/summary.json`：143/143。
- `rules-first.json`：52/53 的首次重播分支覆蓋失敗，保留原結果；`rules.json` 最終 57/57。
- `native-soak/complete.json`：120.134 秒真實 native physics + viewport 自動輸入，90 次啟動，77 次反制，24 次反踢命中，53 次抽身。
- `captures/`：14 張原生工具控制畫面；`air-reversal.gif`／`.mp4`：80 幀固定 60Hz 步進、30fps 輸出，非真人錄影。
- `source-manifest.json`：候選內容雜湊及 42 件來源資產不變；`regression-headless/` 是加入新測試前的 370 項回歸。

軟體 GL／Dummy 音訊，不代表真人平衡、實聽、目標 GPU 或使用者電腦同步。未更新公開網頁。
