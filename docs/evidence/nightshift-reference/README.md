# 按原圖重做：實際引擎證據

frame-*.png／capture-*.png是Godot Compatibility實際SubViewport渲染，含真骨架人物、3D光束／機械臂／煙／電光；空場貼圖用於固定攝影機的投影美術，不是可自由轉視角的完整建築。

preview-15s.mp4：450幀／30fps，15.000秒，音樂為既有遊戲menu.ogg混入；不是原附件音軌。video-metadata.json為ffprobe輸出。Movie Writer原始458幀包含啟動／退出，已裁掉。原片15.083秒只作參考，未拿原影片當runtime背景播放。

目前骨架人物仍與原圖生成插畫有外形與姿態差異，不能把近似動畫或靜態貼圖對齊說成逐像素／逐來源幀完美。詳見NIGHTSHIFT_REFERENCE_REBUILD.zh-TW.md中的方法、限制與Tripo選配清單。初版粗模225項證據仍在nightshift-hub，不能冒充此版新測試。

最終回歸：新據點30、完整戰役原生23、城市原生22、戰役規則50、城市成長規則86，共211；另15腳本fatal-warning編譯通過。accepted log無ERROR／SCRIPT ERROR。timeline-verification.log另覆核六站可達、五骨架人物及F2停強特效。Linux4.6.3 Compatibility／llvmpipe／Dummy，不是Mac／真人／即時FPS驗收。
