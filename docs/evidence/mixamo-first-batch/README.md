# 第一批動作接入證據（2026-11-14）

[實作／安裝說明](../../MIXAMO_FIRST_BATCH_RUNTIME.zh-TW.md) · [總表](summary.json) · [12秒正式場景](native.mp4) · [完整時間軸2fps抽格](native-review.jpg)

22來源的原始FBX／GLB和逐幀曲線只存私有區；公開sources.json為來源SHA／時長／骨數／root量測，clips.json為裁切及contact metadata，沒有可還原的逐幀曲線。23衍生clip中20啟用，15個地面出招slot已換；3個只轉換未啟用的clip是AirKick／KnockedOut／GetUp。

新檢查132/132：native-rigs.json的119項為實際四角／雙向／15攻擊slot、有限正交骨架、單一owner、presentation不寫simulation、每幀蒙皮最低點不低於0.008m、實際打擊骨、正向慢行、護架行路／停動／過場與死亡隔離／缺檔fallback。診斷圖片直接設定attack state及frame，**不是正常輸入影片**。四張contact sheet已檢視：[ZIP](hero-0.jpg)、[RIVET](hero-1.jpg)、[HUSH](hero-2.jpg)、[LOOP](hero-3.jpg)。library-test.json另13項驗證缺檔／不相容／壞曲線／缺必要clip拒收，以及有效檔重新載入。

835項相關回歸通過，逐suite及「有私有庫／缺檔fallback」範圍見summary.json及regression/。**另有舊RIVET 13/19，6項失敗**：5個舊固定腳位斷言和1個charge 7/8幀斷言。將三個修改中的runtime檔恢復到基線08e3e51，其他資產／測試／環境相同，6個失敗與數值完全相同；見regression/rivet-baseline.json及對照log。不是本批新增回歸，也沒有放寬舊斷言；根因仍待後續。不能將這輪稱所有舊測試全過。

公開log僅去行尾空白，原始log保留在私有工作區。18個runtime腳本在原七類warning為fatal時通過；final editor import無ERROR／SCRIPT ERROR。builder重跑，以及把inspection與sample檔序全部反轉後，輸出SHA均為`5b1097e5d05042f4368083ff83b0c2fa714e6f96ee98ece28c34dd0380dd8b1e`。原始inspector的來源取樣有FBX Short user-property警告，來源骨架仍完整；不把這類匯入metadata警告當動作驗收。一次錯用headless跑需frame_post_draw的ink-FX fixture逾時，已改原生重跑通過，不計入accepted結果。

native.mp4是正常street_fight scene的四個近距離訓練fixture，P1每段先真D＋Shift護架行路，再down＋heavy及light命令，沒有注入damage／空中狀態／出招pose。每段實際2 swing／1 hit，四段都用到MX_Walking；不是15招全接觸連擊展示。combat.json記錄實際事件與觀察到的clip。全片12.000秒、360幀、30fps、1280×720、AAC48kHz，完整2fps抽格已檢視；錄製約88秒，不能當即時效能。AAC整體峰值-4.159724dBFS，量測有非零聲音，不是人耳聆聽驗收。

執行例：先安裝私有兩個JSON，再在repo根：

```sh
DISPLAY=:99 godot --path godot --audio-driver Dummy --script res://tools/verify_mixamo_batch.gd -- --capture --out=/private/native
godot --headless --path godot --script res://tools/verify_mixamo_library.gd -- /private/library-test.json
DISPLAY=:99 godot --path godot --audio-driver Dummy --resolution 1280x720 --fixed-fps 30 --write-movie /private/combat.avi --script res://tools/capture_mixamo_combat.gd -- /private/combat.json
python3 tools/verify_motion_warnings.py /private/strict.log
```

Linux Godot4.6.3 Compatibility／llvmpipe／Xvfb／Dummy，沒有Mac、硬體FPS、真人平衡或實體輸入驗收。舊rig試驗曾指出約0.20m鞋底穿地／旋風踢缺回收，已加skin floor及明示entry／exit後重跑；早期未修版本圖片不在accepted證據中。
