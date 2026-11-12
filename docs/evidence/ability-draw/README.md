# 回合間3D抽能力 — 引擎證據

[完整有聲預覽](ability-draw.mp4)：同一遊戲街景，明示第二回合1:1結果fixture；真3D程序NPC／機器／輪盤／獎品、真正native流程與原創聲音。未注入戰鬥命中來偽造自然完整match；BGM只於預覽靜音。

- [進場](01-entry.png)／[落地](02-landing.png)／[拍機](03-slap.png)／[代幣邀請](04-offer.png)
- [轉輪](05-reels.png)／[鎖停](06-lock.png)／[爆獎](07-jackpot.png)／[獎品卡](08-core.png)
- [擷取時序](capture.json)／[Movie Writer紀錄](movie-writer.log)／[實際PCM量測](audio.json)
- [45項新原生檢查](verification.json)／[嚴格log](verify-native.log)／[既有結果15項](regression-result.log)／[既有戰鬥34項](regression-combat.log)

包含1:1及2:0分流、免費一次抽取、skip不重抽、只領一次、真實移動／回盾／起始能量、重置清除、Street Run、Demo無永久XP、另一落點／32度入口、碰撞掃掠備援、雙方及背景人物隱藏、暫停／設定／F2／重開／退出及鏡頭與音樂duck還原。45項native最終log無ERROR／SCRIPT ERROR，VSync不支援warning保留。

初次headless33項中Demo測試在同一引擎幀手動推360步，觸發去重保護而未自動領取；改為真frame邊界。該次及下一次headless即使33/33仍有既有模型重建的Dummy material null錯誤，不當成嚴格通過；最終native沒有重現。另一輪原生42/44的兩個失敗是配置測試誤用街景碰撞mask及F2測試繼承上一case的true值，修正隔離測試設定後45/45。`initial-attempts/`保留上述log，不宣稱這些早期執行無錯。

source.mp4與manifest在`references/ability-draw/`。原片約4.35秒，本次預覽因代幣與結果停留約5.73秒。動作／模型／材質仍有與原片的差異，詳見[實作範圍](../../ABILITY_DRAW.zh-TW.md)。Godot4.6.3／Linux／Compatibility／llvmpipe；640×360、30fps固定步長錄製再nearest放大，不是即時硬件FPS或使用者Mac實測。
