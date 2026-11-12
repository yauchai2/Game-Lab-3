# CITY BREAKER 原生 3D 證據

- [10 秒實時 3D 場景取樣錄像（15fps、無聲）](city-breaker.mp4)
- 八鏡：[拋飛](shot-00.png)、[撞牆](shot-01.png)、[穿街](shot-02.png)、[俯視連爆](shot-03.png)、[仰拍](shot-04.png)、[飛機受擊](shot-05.png)、[空爆](shot-06.png)、[KO 收尾](shot-07.png)。
- [164 項檢查](verification.json)／[最終原生 log](verification.log)／[擷取 log](capture.log)。
- [既有 UI／持續音樂回歸](ui-regression.log)、[結果演出回歸](result-regression.log)、[二段跳](double-jump.log)、[正式玩法](live-combat.log)、[SURGE](combat-escalation.log)。
- 舊節奏 suite 六個失敗：[本輪](current-rhythm.log)與[未修改 4177ef9 基線](baseline-rhythm.log)相同；不聲稱全套零失敗。

來源影片由使用者提供，原樣與雜湊見 [製作說明](../../CITY_BREAKER.zh-TW.md)。八鏡使用現在的遊戲背景、四角 roster 及原客機網格。零生命的受擊者透過正常 session 結算入口進演出；另有真正付費 special 造成 KO 的驗證。受控 fixture 不代表真人完成對局。

Godot 4.6.3 Linux Compatibility／Mesa llvmpipe／Dummy audio。影片是引擎確定性場景取樣，並非影片貼圖、不是目標硬體效能或實聽驗收。最終原生過場及 UI log 無 ERROR／SCRIPT ERROR；V-Sync 不支援提示保留。首次 headless 換模的 null material 與早期失敗記錄沒有冒充通過。

重現（專案根目錄；原生擷取需要顯示伺服器）：

```sh
godot --headless --editor --path godot --import --quit
godot --path godot --audio-driver Dummy --script res://tools/verify_city_breaker.gd
godot --headless --path godot --script res://tools/verify_result_presentation.gd
godot --path godot --audio-driver Dummy --script res://tools/capture_city_breaker.gd
ffmpeg -framerate 15 -i /tmp/city-breaker-frames/%04d.png -c:v libx264 -crf 19 -pix_fmt yuv420p -movflags +faststart city-breaker.mp4
```
