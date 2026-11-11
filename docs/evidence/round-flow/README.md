# 完整回合演出與循環 AI Demo — 2026-11-11

正式 FIGHT／Street Run：2.8 秒街景開場、當局 P1／P2 3D 近鏡與 ROUND → 原倒數 → 對戰 → 真 KO → 5 秒場景／飛機破壞 → 3.2 秒勝者魚眼及專屬離場 → 玩家確認結果。練習保持即玩。

AI Demo／F12：相同完整入場和 KO 演出，自動下一 round；兩勝完場後也重新開場繼續循環。採正常有限生命與正常命中，沒有舊版回血、注入傷害或強行結算，沿用選角並不給 XP。R 重開 Demo；F12 返回標題；Esc 暫停；Enter／Space 可跳過入場／KO；F2 減少特效。

加入原創開場音軌，沿原 SFX bus、音量／靜音／暫停／清理及 BGM duck。街邊／屋頂蒸煙 18 團、命中揚塵池 12 團、KO 殘煙 64 團固定上限；世界座標 billboard 配量化噪聲，不是影片貼片。戰鬥重擊後可用 0.28 秒魚眼重音，至少 1.6 秒冷卻，讓位給 Neon 大招與 KO；以雙人 bounds 和 HUD 留白限制構圖。

## 可觀看證據

- [完整連續有聲引擎錄像](full-round-demo.mp4)：標題 → 兩個真實 AI 回合／兩次完整 KO 和離場 → 第三次入場。沒有強制生命或注入命中；[事件與擷取時間](capture.json)。原 BGM 在這次錄像刻意靜音，以便聽清 SFX；遊戲正常保留 BGM。
- [P1 入場](p1-entry.png)／[P2 入場](p2-entry.png)／[ROUND](round-entry.png)。
- [街邊煙霧](street-smoke.png)／[戰鬥魚眼](combat-fisheye.png)／[空爆](smoke-explosion.png)／[爆後殘煙](smoke-aftermath.png)／[勝者](winner.png)。魚眼截圖位於效果剛觸發，影片可見完整脈衝。

## 驗證

[完整回合檢查26/26](verification.json)包含三次正常生命 AI 真 KO、每次勝者後段及下一入場、兩勝後繼續 loop、四角色入場、Street Run 兩站、無 XP、煙霧上限、雙人構圖、pause／skip／F2／F12／退出清理。

[原生相關回歸](regression-native/summary.json)：勝者86/86、KO FX20/20、KO165/165、Demo輸入11/11。舊 UI 斷言仍要求 endless health，因此初跑36/37；依新需求更新契約後[最終UI37/37](regression-ui-final/summary.json)。[無視窗規則](regression-headless/summary.json)：30,000步 Demo 確定性及正常生命7/7、結果17/17。四角色初次測試直接修改選角陣列而未調用正式選角入口，造成25/26；改用標題的set_character後[最終26/26](regression-round-final/summary.json)。勝者最終批次曾於86項通過後報4個資源退出仍佔用，verbose重跑未重現；測試增加停止音訊後的drain等待，另存[退出重驗](regression-exit-final/summary.json)，不宣稱已診斷或修正Godot底層。最終相關369項皆通過；初跑log保留。原歷史 evidence 保留，當次結果另存這裡。此輪不是全套測試零失敗的宣稱；此前已記錄的舊 Rhythm 六項失敗未作本輪變更。

Godot 4.6.3 Linux Compatibility／Mesa llvmpipe，Dummy audio 混音由 Movie Writer 輸出；640×360／30fps 是固定時間步錄製規格，不是硬件即時 FPS。不是使用者 Mac、真人混音／手感或目標 GPU 效能驗收。原始模型不變，只有程序演出／煙霧及新原創聲效；未發佈公開 Web。
