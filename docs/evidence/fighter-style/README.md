# 四角風格證據

[實作與限制](../../FOUR_FIGHTER_EFFECT_STYLE.zh-TW.md)。Linux Godot4.6.3 llvmpipe／Dummy；不是Mac／人耳／真人／GPU效能驗收。

- `checks.json`／`checks.log`：51新增原生檢查，包含四角有限圖形、四種可重建PCM／非靜音峰值、雙owner鏡頭、72組間距／空中邊界、F2／暫停、靜音／音量0／音效預算及呈現不改sim。
- `counter`122、`street`90、`rivet`19、`rules`46、`death`104、`fx`26及各log：407既有回歸通過；合計458。歷史工具輸出複製後還原舊證據，沒有覆寫歷史結果。
- `motion-strict.log`：11腳本七類fatal warnings全通過。`full-strict`：16/19，仍有story_opening、world_ink_fx及fight_session依賴的reference_workshop三處既有失敗；sprite_fx警告本輪修正，非全專案全綠。
- `trajectory*.json`及log：701f0c7隔離scripts基線與新版同輸入1800 simulation ticks，狀態SHA022cef61…一致、21命中、0simulation差異／呈現改寫。這支重播比較骨架呈現，不是完整聲光圖形等價；新增51項另檢查全scene呈現前後sim快照。
- `silhouettes.png`：同色命中fixture，上排完整、下排F2；刻意排除palette影響，不是實戰或來源動捕畫面。四個WAV為runtime固定種子原創材質層輸出，實戰另有既有CC0打擊主體。
- `four-styles.mp4`／`movie.json`／`movie.log`：12秒360幀連續PLAY，四段練習fixture各由100能量及固定站位開始；ZIP L、RIVET W+L、HUSH真parry取樣再L、LOOP放一點再W+L；真命中2/1/1/1，沒有預塞樣本／節點／傷害。`contact-sheet.png`為2fps覆核抽樣。全長影片已完整抽樣覆核，但不是來源動畫逐幀藝術驗收。
- `summary.json`：計數、編碼資訊、影片hash與解碼音軌RMS／peak；混合BGM+SFX的非靜音量測不是人耳品質確認。

重跑：`python tools/verify_motion_warnings.py OUTPUT.log`；原生`godot --path godot --rendering-method gl_compatibility --audio-driver Dummy --script res://tools/verify_fighter_style.gd -- OUTPUT/checks.json`。輸出目錄先建立。錄影使用`capture_fighter_styles.gd`及`--fixed-fps 30 --write-movie OUTPUT.avi`，再轉H264/AAC。UI測試／錄影應各自單獨執行，避免焦點失去而被正常防護暫停。
