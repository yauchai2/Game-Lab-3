# CITY BREAKER：聲音、鏡頭與漫畫 FX

[有聲 10 秒引擎預覽](city-breaker-with-sound.mp4) · [八鏡總覽](contact-sheet.jpg)

這段影片由 Godot Movie Writer 同步輸出畫面與真正的引擎混音，沒有事後混入獨立聲軌。640×360、30fps、立體聲48kHz；開場準備幀裁去1/30秒，保留10秒過場。預覽關閉BGM以便聽清新聲效；遊戲正常BGM沿既有transport繼續，重擊時暫時duck。不是目標Mac／GPU效能或真人實聽驗收。

- [15項FX／真PCM／靜音／清理檢查](verification.json)／[原生log](verification.log)。
- [164項四角雙方KO回歸](ko-regression.json)／[log](ko-regression.log)。
- [17項結果回歸](result-regression.json)／[log](result-regression.log)。
- [37項原生UI／音樂transport](ui-regression.json)／[log](ui-regression.log)。
- [6項既有實際混音回歸](mix-regression.json)／[log](mix-regression.log)。
- [影片解碼音軌量測](movie-audio.json)：峰值約0.467，RMS約0.040，零削波樣本，左右聲道不同。
- [Movie Writer log](movie.log)保留軟件渲染耗時，不把固定30fps匯出當成即時效能。

以上最終log無ERROR／SCRIPT ERROR或資源洩漏警告；V-Sync不支援提示保留。舊Rhythm測試的既有六項基線失敗見前輪city-breaker，不把本輪相關檢查通過說成整個歷史suite零失敗。新音軌為原創程序合成，沒有外部樣本；來源及重建見 `godot/audio/city_breaker/README.md`。

重現：

```sh
python tools/build_city_breaker_audio.py
godot --headless --editor --path godot --import --quit
godot --path godot --audio-driver Dummy --script res://tools/verify_city_breaker_fx.gd
godot --path godot --audio-driver Dummy --fixed-fps 30 --write-movie /tmp/city-breaker-fx.avi --script res://tools/capture_city_breaker_fx.gd
ffmpeg -ss 0.033333333 -i /tmp/city-breaker-fx.avi -t 10 -c:v libx264 -crf 18 -c:a aac -b:a 192k -pix_fmt yuv420p -movflags +faststart city-breaker-with-sound.mp4
```
