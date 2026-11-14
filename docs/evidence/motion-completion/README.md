# 動作隨Git及第一批收尾驗收

[實作／使用方法](../../MOTION_COMPLETION.zh-TW.md) · [逐招覆核表](coverage.zh-TW.md) · [所有suite結果](summary.json)

兩個game-ready JSON已按使用者2026-11-14明確授權隨遊戲提交，預設從assets/animations讀取；不是快取／外部私人資料。23個衍生clip全部啟用。bundle-manifest.json記錄實際bytes／SHA，clips.json記錄最新裁切及contact。Blender以同批來源重建結果與提交檔逐byte相同。原FBX／GLB未改；Mixamo來源說明在assets/animations/MIXAMO_SOURCES.md。

## 檢查結果

|範圍|結果|資料|
|---|---:|---|
|四角全部現有合法戰鬥move組合與狀態、兩朝向、起手／接觸／收尾、F2／hitstop、無simulation寫入|554/554|coverage.json|
|首批15地面slot、接觸骨、每幀skin floor、正向慢行／護架步法|119/119|batch.json|
|壞schema／SHA／缺clip／非法curve及有效reload|13/13|library.json|
|肩摔雙人matrix、miss／tech／牆邊／KO／training／reset／群戰、回位depth與真骨架|147/147|paired.json|
|獨立renderer bake的四角／雙向、入投／翻轉／落地／完整起身及正式KO|65/65|regression/verify_paired_throw_render.json|
|RIVET新動作／舊缺檔fallback|各19/19|rivet.json、rivet-fallback.json|
|其餘legacy street／counter／air|90／122／216全過|regression/相應JSON|
|真蒙皮地面與屍體|104/104|regression/grounded-death.json|
|四角風格／InkFX／角色規則|51／26／46全過|regression/相應JSON|
|黑衣人完整場景／角色隔離／生命周期|35/35|regression/black-suit.json|
|黑衣人槍械規則|21/21|regression/verify_gun_shot.log|
|18個相關runtime、七類warning為fatal|全過|strict.log|

上述suite包含重疊場景，不加成一個「唯一測試總數」。RIVET舊6項失敗本輪已修正，缺檔fallback仍驗原有雙腳固定條件，並非把原失敗改標通過；新Mixamo源片容許實際重心／步伐，驗每幀蒙皮貼地與不寫simulation。Transit舊全零model.position斷言已改為X/Z零lunge加skin floor，以容許真正鞋底Y校正。黑衣人舊fixture的roster `street_run`按鈕已不存在，改驗主線現用`skills`的focus鄰接，產品UI未因此修改。初次額外黑衣人fixture在舊鍵名中止，修正後35項重跑通過；錯誤執行沒有當作accepted結果。

## 乾淨載入／打包

cold-start.json：建立沒有`.godot`的完整遊戲副本，沒有GAME_LAB動作override、私人安裝檔或原始FBX；editor重新匯入成功，直接13項loader及147項肩摔通過。最後depth回位修改亦已複製最新程式到該副本重跑147通過。這是乾淨專案副本，沒有宣稱已操作使用者Mac。

pack-check.json 7/7：本機以export-pack輸出PCK；在起初沒有任何assets的空專案掛載，確認兩個JSON、23clip、雙人角色與來源說明皆在包內。這是資產包含檢查，不是Web瀏覽器遊玩／部署。PCK沒有提交到Git，公開Web未更新。

## 畫面及真事件

- [12秒肩摔／完整起身](throw.mp4)：四個正常grab訓練fixture，P1依次四角、P2為ZIP；每段start／land／hit／end各一次。來源落地傷害保持一次，恢復64tick，收尾depth平滑回共同平面。[全片4fps](throw-review.jpg)。
- [14秒四角空連](air.mp4)：正常launcher＋按住J＋Space，四段均有真付費追擊及air_jab／air_kick／meteor命中。[全片4fps](air-review.jpg)。
- [20格四角起身](getup-rigs.jpg)：每角施投另一角，每個角色皆實際當一次被摔者；80／96／120／140／143tick，與renderer bake同一fixture。
- [空中接觸](air-rigs.jpg)、[四角倒地](ko-rigs.jpg)：真hero rig、直接pose fixture，不能當真人輸入或連擊影片。

上述完整時間軸抽格與接觸表均已檢視，實際事件在throw.json／air.json，媒體時長／音軌峰值在media.json。MovieWriter肩摔360幀／12.000秒、錄製約98秒；空連420幀／14.000秒、約123秒。均1280×720／30fps／非零AAC，峰值低於0dBFS，不是人耳聆聽或即時FPS。早期肩摔回位修正前的146秒錄製未當最終影片；公開throw.mp4是修正後重錄版。

Linux Godot4.6.3 Compatibility／llvmpipe／Xvfb／Dummy。Mac／實體輸入／人手手感及硬體效能仍待使用者裝置驗收。公開log只去行尾空白，原log在工作區保留。

可重跑：

```sh
DISPLAY=:99 godot --path godot --audio-driver Dummy --script res://tools/verify_motion_completion.gd -- --out=/tmp/motion-review
godot --headless --path godot --script res://tools/verify_paired_throw.gd -- /tmp/paired.json
DISPLAY=:99 godot --path godot --audio-driver Dummy --script res://tools/verify_paired_throw_render.gd -- /tmp/render.json /tmp/getup-pictures
python3 tools/verify_motion_warnings.py /tmp/motion-strict.log
```
