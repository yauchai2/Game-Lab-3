# 黑衣人整合證據

2026-11-11。Godot 4.6.3 Linux Compatibility／Mesa llvmpipe，Dummy audio；來源基於 main 738c740，變更在 codex/black-suit-enemy。

- [敵人選擇](enemy-selection.png)：真實 BLACK SUIT / P2 指標按鈕與 3D 預覽。
- [正式 FIGHT](enemy-fight.png)：玩家對黑衣人，同一街區與原規則；畫面中的近身位置為構圖 fixture。
- [自由 AI](enemy-demo.png)：正常合法 AI 對打樣本，無站樁低血或強制命中。
- [重用姿態](actor-poses.png)：同一場景三個實例，由左至右待機／走路／防守；非多人戰鬥。
- [32 項敵人原生整合](native-checks.json)、`native.log`。
- [46 項四角技能規則](hero-rules.json)、`hero-rules.log`。
- [二段跳／防禦回歸](headless-regressions/summary.json)：62＋25。
- [UI／材質回歸](native-regressions/summary.json)：37＋6。

執行 `godot --path godot --rendering-method gl_compatibility --audio-driver Dummy --script res://tools/verify_black_suit.gd`；需可用原生顯示服務。該腳本會注入正常指標事件，並以普通 simulation 攻擊驗證命中／招架。30 秒自由 AI 為固定時間步進，並非硬件 FPS、真人平衡或真人學習證明。

保留 `initial-headless.log` 記錄早期失敗：誤用不存在的測試函式 step（已改 tick），以及 Dummy renderer 的 material 診斷。整個 visual integration 測試現要求原生顯示，不把 headless 當作渲染成功。較早的原生退出曾出現 ObjectDB 警告；測試器已在釋放場景後等待清理再退出，最終 log 另行檢查。原始主角測試報告及舊畫面不覆寫。

原始上傳檔案、權重與貼圖檢查：[inspection.json](../../../references/characters/black-suit/inspection.json)。後續故事、武器與場景仍待實作，沒有 Web 發佈。
