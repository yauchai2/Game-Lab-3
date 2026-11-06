# S4 飛機掠過原型

在 Godot 4.6.3 打開 `godot/project.godot` 並執行主場景。角色在入口時會自動觸發；抬頭或按 `1` 看入口固定視角，按 `P` 可隨時重播，按 `0` 返回角色。事件不會強制改變相機或角色位置。視角／游走其餘控制見 [WALK.md](WALK.md)。

入口觸發區在玩家出生點周圍；事件持續約 9 秒，沿飛機自身朝向直線飛行 540 m，4.5 秒經過原 S1 參考位置。結束後隱藏；30 秒冷卻後再次進入觸發區可再啟動，`P` 不受冷卻影響。這些數值是可調的構圖原型，不是寫實航拍或飛行模擬。輪組和襟翼以程序幾何補充，並非最終客機模型；S1 獨立白盒保持靜態。

採用程式合成的四秒循環低頻測試音，放在飛機上，事件前後兩秒漸變；生成程式在 `tools/make_flyby_audio.py`，音檔是 `godot/audio/engine_placeholder.wav`，之後可換成有適當使用權的音效。headless 使用 Dummy 音訊驅動，只檢查播放狀態和包絡，**尚未人工聽過聲音、確認音量／距離衰減或同步感**。

依新參考調整了天空、暖色日照、入口窗框與遠方虛構招牌；原白盒及原始 GLB 不變。B 切換也涵蓋原有飛機網格；新增輪組／襟翼是固定材質。兩張風格參考目前僅在原聊天中，未作為 repo 附件保存；比例與最終風格仍需使用者評估。

## 畫面

以下為 Godot Compatibility 在 Mesa llvmpipe 軟體 OpenGL 的固定入口鏡頭擷取；以指定時間比例凍結飛機位置，非連續遊玩錄影：

- [接近，43%](evidence/flyby/01_arrival.png)
- [經過參考位置，50%](evidence/flyby/02_overhead.png)
- [離開，57%](evidence/flyby/03_departure.png)

## 驗證與重現

Godot 4.6.3 headless、固定 60 fps 驗證 11 項：入口自動啟動、測試音與八個新增輪子、飛經中點、保持相機、音量包絡、結束及冷卻、P 重播、擷取凍結和重啟。28 項遊走回歸、12 項風格回歸和六件來源模型載入／雜湊通過。詳細結果見 [事件檢查](evidence/flyby/verification.json)、[遊走回歸](evidence/flyby/walk-regression.json)、[風格回歸](evidence/flyby/style-regression.json)、[資產完整性](evidence/flyby/integrity.json) 和 [截圖資訊](evidence/flyby/captures.json)。測試結束時 Godot 報告 ObjectDB 退出清理警告；檢查結果通過但警告尚待追查。

```sh
godot --headless --editor --path godot --import --quit
godot --headless --path godot --fixed-fps 60 --audio-driver Dummy --script res://tools/verify_flyby.gd
godot --headless --path godot --fixed-fps 60 --script res://tools/verify_walk.gd
godot --headless --path godot --fixed-fps 60 --script res://tools/verify_style.gd
godot --headless --path godot --script res://verify.gd
```

擷取腳本 `res://tools/capture_flyby.gd` 需要可用的顯示／圖形環境。尚未進行人工遊玩、實際收聽、實體 GPU 畫質／效能或最終美術驗收；現階段畫面仍是幾何和事件樣片。
