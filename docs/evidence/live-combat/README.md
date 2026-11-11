# 正式街鬥改善：前後對照

基線 `baa6950`，修改後為本輪來源。六個production owner的前後SHA256見 [source-manifest.json](source-manifest.json)。Linux Godot4.6.3 Compatibility／Mesa llvmpipe／Dummy audio；原始GLB及歷史證據不改。

## 真正FIGHT與錄像

- [正式FIGHT真投技畫面](real-fight-throw.png)／[真鍵盤結果](real-fight-keys.json)：R重開、長按Shift，CPU以普通grab真正命中。`training=false`、`demo=false`、正常出生點／60能量／倒數，沒有站樁必中或改血fixture。CPU動作統計包含重開前未操作的開場，只有guarded throw確認要求真實Shift按住。
- [ZIP／RIVET：左舊右新30秒](zip-rivet-before-after.mp4)。
- [HUSH／LOOP：左舊右新30秒](hush-loop-before-after.mp4)。

兩組影片是原生F12自由AI（正常Rush規則、其既有showcase policy，非玩家對CPU的FIGHT），每段各300幀／10fps／30個虛擬wall秒、相同配搭及初始seed。不是硬件FPS、同一招式逐幀同步或真人手感證據。正式policy另外由下列FIGHT情境及真鍵盤驗證，沒有把Demo結果冒稱真人對局。前後都無強制命中、章節或中途定時重設。

[修改前統計](before-demo.json)／[修改後統計](after-demo.json)。兩組前後都能實際交手；新版包含真parry、counter_success、付費追擊、節點／角色資源和BREAK。命中數不是好玩程度評分。

## 可重現斷點

[before-probe.json](before-probe.json)／[after-probe.json](after-probe.json)：普通FIGHT policy／數值，以控制輸入比較；KO後才開新局，不修血製造結果。12個「P1持續guard，四角×三難度CPU」各1800 game tick情境，舊版全0投技起手，新版每組5–12；這是起手數，不是假稱全部投中。

LOOP持續J、距離1.2／1.5，基線180 tick內最高兩連段且第三擊失敗；新版本兩組都在第41 tick接第三擊，其他三角維持原結果。無吸附或改判定距離。

[接觸前](before-latency.json)／[接觸後](after-latency.json)：先用真攻擊／格擋建立接觸，再以1/60虛擬wall步進直到角色frame或stun再次推進。SURGE60挑空13→9步、parry16→12、overdrive30→23；原生9／8／26 hitstop tick保持。低壓三例也更快，不是硬件鍵盤延遲。

## 驗證及歷史

- [45項正式玩法檢查](checks.json)：攻防意圖承諾、guard投技、跳躍避投、揮空恢復、低guard後撤、低能量HUSH等四角接近交戰、空中決策變化、LOOP連段、共用時鐘及12,000步重播一致。
- [最終260項戰鬥](final-regressions/summary.json)／[37項原生UI音樂](native-regressions/summary.json)／[185項既有系統](supplemental/summary.json)。成長／裝備／SURGE原型／教學均保留隔離。
- 最終checks.log、before/after-demo.log、before/after-latency.log、real-fight-keys.log及final-regressions／native-regressions／supplemental log無ERROR／SCRIPT ERROR；原生VSync不支援警告保留。
- `regressions/`保留早期4項失敗：3項舊「新手單鍵能贏」測試原先用了預設Normal，現在明確Easy，Normal／Hard不再保證輸給單鍵spam；1項大招自由AI參與門檻曾未通過，調整空中決策相位後已通過，最終保留雙方各>50真命中原門檻，另記攻防參與數。`updated-regressions/`是中間回歸，最終以`final-regressions/`為準。

重現：`godot --headless --path godot --script res://tools/probe_live_combat.gd -- after`、`probe_contact_latency.gd -- after`、`verify_live_combat.gd`。`capture_live_after.gd`擷取目前自由AI；`capture_live_before.gd`只允許使用`baa6950`production runtime的分開checkout，避免把新版重錄後冒稱舊版。`verify_live_fight_keys.gd`用正常FIGHT等待實際Shift，可在RESULT用R重開。

完整無強制命中的影片及數值只能證明行為改變、規則合法與軟體渲染結果。Mac硬件、真人難度／爽感、實際喇叭與混音仍待測。公開Web未更新。
