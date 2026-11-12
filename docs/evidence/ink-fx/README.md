# 正式戰鬥VFX證據

[實作與限制](../../COMBAT_VFX_RUNTIME.zh-TW.md)。Linux Godot4.6.3 Compatibility llvmpipe／Dummy，420項最終檢查；新FX26、strict14，其餘回歸380。

- comparison.mp4：前後並排，音訊只播新版；after.mp4／before.mp4為各自版本。12秒、30fps、兩組固定種子原AI（每組6秒），略過入場；360個真正渲染及混音影格，但錄製約37秒，不是目標硬件FPS或真人實玩。
- running.png、light-contact.png、launch-contact.png、landing-cels.png、squad.png：明示狀態／輸入fixture截圖。landing-cels含手動發射slam以覆核輪廓；不能把它當全自動自然落地證據。真正air_land另有規則／事件檢查。
- checks.json／native.log：26新檢查；strict/extended.json與log：14腳本以四類warning作error。
- trajectory-before.json／trajectory-after.json：1800步相同玩法SHA及37次真命中／2次KO事件，相關log在baseline/trajectory.log與trajectory.log。首次Dummy renderer探查不作accepted。
- before-movie.json／after-movie.json、baseline/movie.log／movie.log：錄製及draw calls資料。CPU數值包括兩次simulation/presentation，不等同單一FX耗時；未證實Mac 1–2ms預算。
- movie-audio.json：AAC解碼非零／無滿幅樣本；regressions/audio.json及log為真引擎混音6項。未作真人聆聽。
- regressions/：最終11組相關log與JSON。舊fixture已對齊有限生命／裝備過場及Easy整局時間；不是削弱遊戲規則。
- initial/及baseline/：首次jump測試時序錯誤、舊Neon永不結束假設、基線Rush600tick不足及舊回合入場假設；保留歷史失敗，不當作最終通過。

重現：原生環境執行 `godot --path godot --rendering-method gl_compatibility --audio-driver Dummy --script res://tools/verify_ink_fx.gd`。錄影用capture_ink_fx.gd配合`--write-movie`／`--fixed-fps 30`，不是把headless載入當畫面證據。probe_ink_equivalence.gd也需原生renderer，避免Dummy材質生命週期限制。

14腳本嚴格編譯可直接重現：`python tools/verify_godot_warnings.py --output docs/evidence/ink-fx/strict`。
