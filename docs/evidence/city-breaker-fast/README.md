# 五秒 KO：整體加快一倍，保留重拍

[五秒有聲引擎預覽](ko-five-seconds.mp4) · [八鏡](contact-sheet.jpg)

原10秒過場縮為5秒。不是整段2×播放：穿街／拉遠／追天段壓縮，撞樓保留短重拍，主要空爆在約3.61秒保留局部慢拍，最後4.08–5秒約0.92秒給KO字卡收尾。八鏡、當局人物及場景、F2／暫停／跳過規則保持。

聲效按同一 `godot/audio/city_breaker/timing.json` 重排並重新合成5秒版本；音高與低頻不變，AudioStreamPlayer維持pitch_scale=1，不以整條音軌倍速變調。程序生成器與Godot的正反時間映射共享同一profile。`export_presets.cfg`只加入此JSON的打包filter，沒有匯出或部署公開Web。

- [20項FX／PCM與新節奏檢查](fx.json)／[log](fx.log)：5秒影片／聲軌、原音高、單調映射、空爆重拍、0.9秒以上收尾、靜音／暫停／清理。
- [165項原生KO回歸](ko.json)／[log](ko.log)：最後一幀前仍在演出、約5秒自然結束、四角×雙方、真傷害KO與所有出口。
- [17項結果回歸](result.json)／[log](result.log)。
- [Movie Writer log](movie.log)及[解碼音軌量測](movie-audio.json)。最終上述log無ERROR／SCRIPT ERROR或洩漏警告。

影片由Godot真正同步聲畫輸出，裁去1個準備幀，長5秒／640×360／30fps／48kHz立體聲，沒有後配音或在剪輯器倍速。固定匯出不是Mac／目標GPU即時效能或真人實聽驗收。前輪全UI／音樂與既有混音檢查見city-breaker-fx；本輪未重跑整個歷史suite，舊Rhythm基線失敗不冒稱已修復。

重現：

```sh
python tools/build_city_breaker_audio.py
godot --headless --editor --path godot --import --quit
godot --path godot --audio-driver Dummy --script res://tools/verify_city_breaker_fx.gd
godot --path godot --audio-driver Dummy --script res://tools/verify_city_breaker.gd
godot --path godot --audio-driver Dummy --fixed-fps 30 --write-movie /tmp/city-breaker-fast.avi --script res://tools/capture_city_breaker_fx.gd -- --out=res://../docs/evidence/city-breaker-fast/
ffmpeg -ss 0.033333333 -i /tmp/city-breaker-fast.avi -t 5 -c:v libx264 -crf 18 -c:a aac -b:a 192k -pix_fmt yuv420p -movflags +faststart ko-five-seconds.mp4
```
