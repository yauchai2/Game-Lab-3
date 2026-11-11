# 大招慢鏡／近鏡／旋轉驗證

- [真實付費大招影片](overdrive-actual.mp4)：原角色，260個固定wall steps（約4.33虛擬秒）、30fps／130幀，無聲。實際simulation消耗能量及命中；測試關閉training資源回填，不增加命中／無敵。
- [全時間軸抽樣](contact.jpg)：2fps；[四人檢查／鏡頭時間軸](checks.json)／[最終verbose log](verification.log)。
- actor0–3的gather／open／aim／drive／settle PNG為真攻擊過程首次進入該演出段落的畫面。Body bounds是攝影機安全區，不表示所有大型VFX或伸出的指尖永遠在畫內。
- [原生UI／材質回歸](regression-native/summary.json)／[戰鬥規則回歸](regression-rules/summary.json)。

首次測試誤以為practice結束時meter仍小於100即可證明付費；實際訓練會回填，所以改成關閉training回填、執行真出招後驗證。未改遊戲規則遷就測試。最終日誌保留V-Sync不支援提示；ERROR／SCRIPT ERROR／ObjectDB洩漏須檢查，狀態JSON不能掩蓋renderer問題。

Linux Godot4.7.2 Compatibility／Mesa llvmpipe；不代表Mac硬件FPS、聲音裝置或人類遊玩評分。功能與後續範圍見 [更新說明](../../NEON_SIGNATURE.zh-TW.md)。
