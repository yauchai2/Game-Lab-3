# 格擋容錯／正回饋證據

[新規則](../../FRIENDLY_DEFENSE.md) · [驗證範圍及首跑修正](../../VALIDATION.md)

- `final-headless/summary.json`：489/489，新增 25 項；包括短按保留不吞跳躍。
- `native/summary.json`：187/187，新增 13 項；`final-input/summary.json` 在最後跳躍取消修正後再跑 13/13，不重複加總。
- `first/`／`rules-recheck/`：舊時機契約的首次失敗與更新後檢查。
- `rules-first.*`：21/22，投技 fixture 站距超界，修正測試距離後通過。
- `input-first.*`：7/13，第一個鍵早於視窗初始化、空中檢查早一 tick；最終正確時序 13/13。
- `01_parry_ready.png`／`02_counter_success.png`／`03_nice_block.png`／`04_reduced_air_success.png`：實際原生引擎擷取，固定準備狀態和步進，非真人錄影。
- `source-manifest.json`：候選內容及原始 43 件二進位資產保留。

Dummy 音訊／軟體 GL，不代表真人平衡、實聽或目標硬體驗收。公開 Web 未更新。
