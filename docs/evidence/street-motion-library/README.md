# ZIP踢技／RIVET新庫證據

[實作、來源與限制](../../STREET_MOTION_LIBRARY.zh-TW.md)。Godot4.6.3 Linux Compatibility／llvmpipe／Dummy；非Mac或真人品質驗收。

- `after/`：四角22類，每類90tick，0／24／55tick抽格，部分攻擊另取5／14／38tick；根固定。`sources/`：8種來源clip四角preview。`samples.json.gz`是每tick Foot／Hand骨socket資料，非鞋幾何接地或真輸入走路。
- 前輪基線抽樣在`../fighter-motion/after/`，commit25c83ec。`summary.json`證明HUSH／LOOP骨socket資料相同。
- [12秒原生有聲片](street-motions.mp4)／`movie.json`：三個明示重設練習，正常付費ZIP L、ZIP W+L、RIVET W+L，真命中2／3／1，合計6。沒有假傷害或全場自動追蹤。30fps／360幀、固定步進錄製；不是硬件FPS。
- `checks.json`90／`rivet-checks.json`19／`rules.json`46／`death.json`104／`fx.json`26與對應log：共285項通過。動作與socket、機制、死亡、群戰、FX池／清理均有覆蓋。
- `trajectory.json`／`trajectory-baseline.json`：verify_motion_gameplay的相同指令1800固定tick，狀態SHA／指令SHA相同、21次真命中、0sim差異與0呈現改寫。重設每180tick以有界測付費技能，不當自然對戰。
- `demo-trajectory*.json`：舊Demo／畫面迴圈probe受並行Godot視窗焦點自動暫停影響而不一致，保留但不當相同輸入證明；舊跨輪hash亦不可混比。
- `strict.log`：六個motion／recipe腳本七類fatal-warning通過；`full-strict/`：全19腳本15/19，四個既有失敗與前輪相同。完整suite並未全綠。
- `rebuild.log`：固定來源hash驗證與重建結果；runtime只帶衍生曲線，不帶第三方網格。授權／來源／SHA詳references/animation-sources/street-library.json及LICENSE-KayKit.txt。

重現需先建立Godot import cache，並有正常GPU／X11；以下headless warning檢查不是畫面證據：

```sh
godot --path godot --rendering-method gl_compatibility --audio-driver Dummy --script res://tools/verify_street_motion.gd -- /absolute/checks.json
godot --path godot --rendering-method gl_compatibility --audio-driver Dummy --script res://tools/verify_motion_gameplay.gd -- /absolute/trajectory.json
godot --path godot --rendering-method gl_compatibility --audio-driver Dummy --script res://tools/capture_fighter_motion.gd -- /absolute/captures
godot --path godot --rendering-method gl_compatibility --audio-driver Dummy --script res://tools/capture_fighter_motion.gd -- /absolute/sources sources
godot --path godot --rendering-method gl_compatibility --audio-driver Dummy --fixed-fps 30 --write-movie /tmp/street-motions.avi --script res://tools/capture_street_motions.gd -- /absolute/movie.json
python tools/verify_motion_warnings.py /absolute/strict.log
python tools/build_street_motion_library.py /absolute/UAL2.glb /absolute/KayKit_CombatMelee.glb /absolute/KayKit_MovementBasic.glb /absolute/KayKit_MovementAdvanced.glb
```

建置用numpy／scipy；四個GLB依固定manifest raw URL取得，需byte hash吻合。重播基線是在25c83ec的隔離scripts目錄配同一固定指令工具；原19clip及英雄資產不變。既有測試產出的歷史檔已另存本輪結果並還原。

錄影工具每幀檢查screen=play，若焦點中斷便失敗；initial-movie-focus.json保留初次被暫停的2／0／1命中記錄，不作accepted影片。正式焦點自動暫停功能保持。
