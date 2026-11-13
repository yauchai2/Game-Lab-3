# HUSH／LOOP地面動作證據

[實作與限制](../../HUSH_LOOP_MOTION.zh-TW.md)。Godot4.6.3 Linux Compatibility／llvmpipe／Dummy；非Mac／真人／硬體FPS驗收。

- `after/`：四角22類、每類90tick呈現fixture，根固定，非真輸入步行；`sources/`：七種單手／拳擊／防守來源preview。`samples.json.gz`為Foot／Hand骨socket，不能當鞋幾何接地證明。
- `summary.json`：ZIP／RIVET每tick骨socket與前輪相同；基線抽樣在`../street-motion-library/after/`。
- `checks.json`／`native.log`122項；`zip-rivet.json`90、`rivet.json`19、`rules.json`46、`death.json`104、`fx.json`26及各log，共407項通過。
- 正常指令測例驗HUSH真parry→sample→L反擊、LOOP近／遠放點不假傷→S＋L真脈衝；0／1／2節點encore測例為明示初始資源fixture。不要把有種子節點的測例當自然取得證據。
- `trajectory*.json`及log：471b21e隔離scripts基線與新版、相同指令1800 simulation ticks、相同狀態／輸入hash、21真命中及0呈現改寫；不是受視窗焦點影響的Demo wall-loop。
- `strict.log`：七個motion／recipe腳本七類fatal warning通過；`full-strict/`：15/19，四個既有失敗與前輪相同。未宣稱全套全綠。
- `rebuild.log`：固定GLB來源hash檢查及可重建結果；來源／作者／CC0與衍生hash在references/animation-sources/street-library.json。

重現（原生截圖／錄影先建Godot匯入快取、有GPU／X11；錄影單獨跑以免失焦自動暫停）：

```sh
godot --path godot --rendering-method gl_compatibility --audio-driver Dummy --script res://tools/verify_counter_motion.gd -- /absolute/checks.json
godot --path godot --rendering-method gl_compatibility --audio-driver Dummy --script res://tools/capture_fighter_motion.gd -- /absolute/after
godot --path godot --rendering-method gl_compatibility --audio-driver Dummy --script res://tools/capture_fighter_motion.gd -- /absolute/sources KK_Punch,KK_Punch_Mirror,KK_StickStab,KK_StickSweep,KK_StickChop,KK_StickGuard,KK_StickBlockHit
godot --path godot --rendering-method gl_compatibility --audio-driver Dummy --script res://tools/verify_motion_gameplay.gd -- /absolute/trajectory.json
godot --path godot --rendering-method gl_compatibility --audio-driver Dummy --fixed-fps 30 --write-movie /tmp/counter-motions.avi --script res://tools/capture_counter_motions.gd -- /absolute/movie.json
python tools/verify_motion_warnings.py /absolute/strict.log
```

來源建置沿tools/build_street_motion_library.py四個固定GLB參數，需numpy／scipy，與前輪同一份原始來源。原生fixture的輸出另存這裡，既有歷史證據已還原。

[15秒有聲原生片](counter-motions.mp4)：HUSH真招架取得／消耗SAMPLE，LOOP兩點手動脈衝、一點接大招。450幀連續PLAY；三段各1次真命中，後兩段各1個真節點脈衝事件。沒有預塞樣本／節點或注入傷害；對手首記jab為明示合法起招fixture。固定步進錄製非硬體FPS；[對照圖](comparison.png)使用相同tick的代表姿態，不是逐招完整動態驗收。
