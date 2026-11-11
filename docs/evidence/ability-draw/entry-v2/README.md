# NPC／機器入場修正 — 2026-11-11

[新版有聲進場](entry-animation.mp4)／[首鏡空場](00-empty.png)／[從左邊進入](01-entry.png)／[煞停](02-landing.png)。原版證據保留在上一層，本輪不是覆寫歷史截圖。

原版左右起點(-5,0,-.25)/(5,0,-.25)在真街景與StaticCollision相交，兩路失敗後退到entry_offset=0，造成原地出現。已用實際PhysicsDirectSpaceState證實，見before-probe.log。改用已驗清楚的±6m、z0起點，保留碰撞檢查，見after-probe.log；不是關掉碰撞。

開場先看空場，0.16–1.06秒以smoothstep拖入，攝影機從空街搖回落位點；輪子隨實際距離轉、雙腳隨路程交替、前傾用力、1.05秒煞停重拍與揚塵，之後接既有拍機。聲音重拍已對齊。兩條通道都堵塞的其他stage則有明確圖形遮幕揭幕，先遮住新生成的演員再揭開；仍要求地圖提供安全停機空間，不保證任意封閉地形能拖行。

[原生檢查](verification.json)／[log](verify-native.log)新增真街景非零進場、NPC／機器初始mesh corners均出框、實際位移與輪轉，以及雙路堵塞遮幕可見性，保留既有抽獎／下一局能力／暫停／F2／退出檢查。[錄像時序](capture.json)、[PCM](audio.json)及Movie Writer log一併保存。

同一遊戲World3D的1:1邊界fixture，非自然完整match。Godot4.6.3 Compatibility／Mesa llvmpipe，640×360／30fps固定時間步，nearest放大1280×720；不當Mac或目標硬件FPS證據。

最終52/52原生檢查通過，最終log無ERROR／SCRIPT ERROR或退出洩漏。初次52/52旗標後仍有四個音訊資源退出未釋放，verbose定位到arrival.ogg與intro.ogg播放實例；已在兩個入場owner的clear／exit顯式停止playback並解除stream，再跑完整52項及退出乾淨。初次log及verbose節錄保留，沒有把最初旗標視為嚴格通過。
