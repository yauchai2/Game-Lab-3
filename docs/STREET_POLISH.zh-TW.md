# 港式街景優化樣片

此階段保留 S1 白盒及八件來源 GLB，在遊走場景新增店面、原創招牌、門窗、窗框、冷氣、街燈、架空電線、植物、街道標線、斑馬線與遠景立面。新裝飾大部分只影響視覺；四支路燈有簡化碰撞。原有側巷、車輛碰撞、場景控制及資產保持。

- [入口：優化前](evidence/dressing/before/01_entry.png)／[優化後](evidence/dressing/after/01_entry.png)。
- [街道高度](evidence/dressing/after/03_street_level.png)、[中段](evidence/dressing/after/04_midstreet.png)、[側巷回望](evidence/dressing/after/05_alley_return.png)。
- [飛機連續飛越影片（無聲）](evidence/motion/flight_street_silent.mp4)。這是固定 30 fps 模擬、每 3 幀擷取一次並以 10 fps 輸出的 640×360 Godot 軟體渲染影片，不是目標硬體性能或人工試玩錄影；未錄製聲音。
- [貨車車尾原型](evidence/dressing/truck/02_rear.png)：後門框、鎖桿及車牌色塊由包裝場景額外產生，未修改使用者 GLB。

## 操作與效果

Godot 主場景按 **1** 看入口，**0** 返回遊走，**P** 重播飛機，**B** 比較材質，**C／N** 比較天空。**O** 可切換實驗性的深度輪廓線，預設關閉；[關閉](evidence/outline/01_off.png)／[開啟](evidence/outline/02_on.png)使用同一攝影機。輪廓效果針對目前 Compatibility 渲染器測試，並在文字之前繪製以免蓋掉透明招牌；不同顯示卡及其他渲染器仍待驗證。

遊走場景的飛機航路參考位置改為 `(-6,41,-52)`、yaw −150°，由 9 秒延長為 12 秒，讓入口視角有較長時間看到機身；綠色機頭和機身色帶為程序追加。獨立 S1 白盒位置及方向保持不變。飛機仍是簡化原型，天空、文字可讀性、後門和飛行時機需人工評估。

## 檢查範圍

- 13 項新場景／操作／路燈碰撞檢查，及原有 28 項遊走、12 項材質、7 項天空、11 項飛機、6 項轎車、11 項貨車／天空回歸均通過；原 S1 與八件資產載入及來源雜湊通過。[檢查結果](evidence/dressing/verification.json)與同目錄回歸紀錄可重現。部分 headless 測試退出時仍有既存 ObjectDB 音訊清理警告。
- 新裝飾 542 個盒形／線段實例合併為 13 個材質批次；既有風格樣片的 165 個細節實例也以共享批次繪製。相同 800×450 鏡頭與軟體渲染條件下，包含陰影等渲染工作的 Godot 計數由 **1,871 降至 1,131 次繪製呼叫**；兩次包含少量後續細節差異，見 [前](evidence/dressing/render_metrics_before_batching.json)／[後](evidence/dressing/render_metrics.json)。這不是 FPS、GPU 記憶體或硬體效能承諾。
- 同一入口鏡頭、1280×720 的 [輪廓比較](evidence/outline/pixel_comparison.json)顯示效果有可見差異，主招牌的金色字樣保留。這只檢查指定軟體渲染和單一視角，不能保證所有透明物件或所有硬體都正確。
- 人工遊玩、真實桌面輸入、GPU 效能、音效實聽，以及中文字型跨平台仍待使用者驗收。方向以使用者參考為基礎，但最終美術未視為已完成。

重現範例：

```sh
godot --headless --editor --path godot --import --quit
godot --headless --path godot --fixed-fps 60 --audio-driver Dummy --script res://tools/verify_dressing.gd
godot --headless --path godot --fixed-fps 60 --audio-driver Dummy --script res://tools/verify_walk.gd
# 下列命令需圖形顯示環境
godot --path godot --rendering-method gl_compatibility --audio-driver Dummy --resolution 1280x720 --script res://tools/capture_dressing.gd
godot --path godot --rendering-method gl_compatibility --audio-driver Dummy --resolution 1280x720 --script res://tools/capture_outline.gd
python3 tools/verify_outline_pixels.py
```
