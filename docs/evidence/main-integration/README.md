# main 整合驗證

合併987d4d2黑衣人與3389fa9正式戰鬥更新後，477項最終通過，無引擎ERROR／SCRIPT ERROR。

- `headless/`：146項規則／Demo／二段跳／防禦／戰鬥。
- `native/`：結果24、勝者86、材質6、UI37通過；初次回合測試19/23保留。
- `round-flow-final/`：修正測試器引擎影格讓出後回合24/24，含自然AI真KO／跨場循環。
- `extra/`：群戰35＋原生10、黑衣人35、Tripo模型22＋流程52，全數通過。黑衣人新增進場與敵人勝者演出檢查。

Linux Godot4.6.3 Compatibility／llvmpipe、Dummy audio。原始來源與雙方歷史證據保留；雲端測試不等同Mac、喇叭實聽或真人平衡。初次round-flow在同一Engine process frame裡執行多次確認，被正確的防重複機制阻擋；測試現在定期await process_frame，不改正式確認規則。

## 最後遠端更新3ea0691

`latest-final/`：再合併最新手動抽獎／節奏／UI後，24回合＋22原模型＋63抽獎共109項原生通過，無ERROR／SCRIPT ERROR。Demo現在按最新要求等待DRAW／CONTINUE；回合測試送明示Enter後驗跨場，不修改runtime要求。前述477項屬528393e第一次整合結果，保留其版本與完整紀錄。
