# 四角動作review／RIVET首切片證據

[實作、限制及來源](../../RIVET_MOTION_SLICE.zh-TW.md)。Godot4.6.3 Linux Compatibility／Mesa llvmpipe／Dummy，非Mac或真人品質驗收。

- `before/`／`after/`：四角22動作、每類90tick，0／24／55tick截圖；資料為顯式狀態fixture，根節點固定，不是正常輸入步行。`samples.json.gz`保留每tick Foot／Hand骨socket與clip；`summary.json`記錄每角每招位移及未改三角一致性。指標不是鞋底幾何／地形IK測量。
- [前後圖](rivet-comparison.png)：RIVET idle／cross／special抽格，左至右固定tick見圖標，短招24tick已可能回收。
- [12秒原生有聲片](rivet-motion.mp4)／`movie.json`：三段重置練習，各一次正常L按／持／放，3次真命中；沿session command，不注入傷害。30fps／360幀，實錄約67秒，非硬件60fps證明。
- `checks.json`／`native.log`：19新檢查；`service-rules.json`／`service.log`：46機制；`grounded-death.json`／`death.log`：104死亡與群戰，均通過。骨骼站穩不等同完成全身轉髖與自然步態。
- `trajectory-before.json`／`trajectory-after.json`：1800步SHA及事件完全相同。`before.log`／`after.log`為抽樣accepted引擎log。
- `motion-strict.log`：四個變更runtime腳本七類warning設為error，全部通過。`strict/`與`strict-baseline/`：全19腳本均有相同4處既有失敗，非全套通過。
- `movie.log`記錄原生錄製與混音。沒測目標Mac／人手操作／實聽／GPU效能。影片與抽格已目視，未聲稱逐幀完整藝術驗收。

重現（先以editor import建立本機資產快取；正常GPU／X11環境）：

```sh
godot --path godot --rendering-method gl_compatibility --audio-driver Dummy --script res://tools/capture_fighter_motion.gd -- /absolute/output/folder
godot --path godot --rendering-method gl_compatibility --audio-driver Dummy --script res://tools/verify_rivet_motion.gd -- /absolute/checks.json
godot --path godot --rendering-method gl_compatibility --audio-driver Dummy --script res://tools/probe_ink_equivalence.gd -- /absolute/trajectory.json
godot --path godot --rendering-method gl_compatibility --audio-driver Dummy --fixed-fps 30 --write-movie /tmp/rivet-motion.avi --script res://tools/capture_rivet_motion.gd -- /absolute/movie.json
python tools/summarize_fighter_motion.py docs/evidence/fighter-motion
```

before由45bb063原runtime加相同capture工具取得；不是在新版重新生成的假基線。現有規則／死亡測試會寫其原證據路徑，本輪結果另複製至此，原歷史檔已還原。
