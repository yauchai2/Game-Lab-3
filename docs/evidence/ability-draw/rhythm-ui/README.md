# 手動抽獎／節奏與共用字體

[有聲原生預覽](ability-draw-rhythm-ui.mp4) · [等待抽獎](04-offer.png) · [穩定結果](08-core.png)

刻意設定第二回合 1:1 邊界，正式街景／NPC／機身／骨架／聲效與 GUI 渲染；入場後等待兩秒，再送滑鼠按下／放開事件至真正 viewport GUI，沒有直接 emit 按鈕 signal，也不是自然完整對局。結果等待供閱讀。

- `verification.json`／`verification.log`：63/63，含真 GUI 點擊、按住防穿透、Demo 無自動抽／領、Enter 不跳抽獎、Space 不重抽、逐輪鎖定／靜拍／揭曉、原正式邊界、能力生效、跨場景／備援、暫停／F2／重開／退出還原。
- `model-verification.json`／log：22/22，原 65 骨／skin、CC0 gait、手腕接觸／代幣、機殼貼圖／開窗／獨立活動件原生回歸。
- `capture.json`：鏡頭擷取時間；Movie Writer 同錄影像及 PCM，再轉 MP4 AAC，沒有事後配音。`audio-check.json` 記錄 AAC 解碼非靜音與削波檢查。
- `initial-coordinate-fixture-failure.json` 保留初次失敗：測試把內部 viewport 座標當實際視窗座標，未處理桌面整數縮放的 letterbox。改用 viewport.push_input(event,true) 驗證真 GUI；另曾在結果出現不足 160ms 時測試 claim，已改為等待輸入啟用後按下。最終日誌無 ERROR／SCRIPT ERROR／資源洩漏。

Godot 4.6.3／Linux／llvmpipe／Dummy。固定幀匯出不是即時 GPU 效能或 Mac 驗收，未宣稱真人聆聽。原始資產與歷史證據保留，公開 Web 沒有更新。
